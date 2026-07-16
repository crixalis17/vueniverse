#include <jni.h>

#include <atomic>
#include <chrono>
#include <cstdint>
#include <mutex>
#include <string>
#include <vector>

#if WHYPULSE_LLAMA_AVAILABLE
#include "llama.h"
#endif

namespace {

constexpr int ERROR_OK = 0;
constexpr int ERROR_NATIVE_UNAVAILABLE = 1;
constexpr int ERROR_MODEL_NOT_LOADED = 2;
constexpr int ERROR_MODEL_LOAD_FAILED = 3;
constexpr int ERROR_INVALID_PROMPT = 4;
constexpr int ERROR_CONTEXT_CREATION_FAILED = 5;
constexpr int ERROR_TOKENIZATION_FAILED = 6;
constexpr int ERROR_DECODE_FAILED = 7;
constexpr int ERROR_CANCELLED = 8;
constexpr int ERROR_TIMEOUT = 9;
constexpr int ERROR_INTERNAL = 10;
constexpr int MAX_CONTEXT_TOKENS = 4096;

std::mutex g_runtime_mutex;
std::mutex g_error_mutex;
std::atomic<bool> g_cancelled{false};
std::atomic<bool> g_inference_active{false};
std::atomic<int> g_last_error{ERROR_OK};
std::string g_last_error_message;

#if WHYPULSE_LLAMA_AVAILABLE
llama_model *g_model = nullptr;
bool g_backend_initialized = false;
#endif

void set_error(int code, const std::string &message) {
    g_last_error.store(code);
    std::lock_guard<std::mutex> lock(g_error_mutex);
    g_last_error_message = message;
}

void clear_error() {
    set_error(ERROR_OK, "");
}

std::string from_jstring(JNIEnv *env, jstring value) {
    if (value == nullptr) return {};
    const char *characters = env->GetStringUTFChars(value, nullptr);
    if (characters == nullptr) return {};
    std::string result(characters);
    env->ReleaseStringUTFChars(value, characters);
    return result;
}

struct InferenceAbortState {
    std::chrono::steady_clock::time_point deadline;
};

bool should_abort_inference(void *data) {
    const auto *state = static_cast<InferenceAbortState *>(data);
    return g_cancelled.load() || std::chrono::steady_clock::now() > state->deadline;
}

#if WHYPULSE_LLAMA_AVAILABLE
std::string token_piece(const llama_vocab *vocab, llama_token token) {
    std::vector<char> buffer(256);
    int count = llama_token_to_piece(vocab, token, buffer.data(), buffer.size(), 0, true);
    if (count < 0) {
        buffer.resize(static_cast<size_t>(-count));
        count = llama_token_to_piece(vocab, token, buffer.data(), buffer.size(), 0, true);
    }
    if (count < 0) return {};
    return {buffer.data(), static_cast<size_t>(count)};
}
#endif

}  // namespace

extern "C" JNIEXPORT jboolean JNICALL
Java_com_whypulse_why_1pulse_medgemma_NativeMedGemma_nativeIsAvailable(
        JNIEnv *, jobject) {
#if WHYPULSE_LLAMA_AVAILABLE
    return JNI_TRUE;
#else
    return JNI_FALSE;
#endif
}

extern "C" JNIEXPORT jint JNICALL
Java_com_whypulse_why_1pulse_medgemma_NativeMedGemma_nativeLoad(
        JNIEnv *env, jobject, jstring model_path_value) {
#if !WHYPULSE_LLAMA_AVAILABLE
    set_error(ERROR_NATIVE_UNAVAILABLE, "llama.cpp was unavailable when the JNI library was built");
    return ERROR_NATIVE_UNAVAILABLE;
#else
    const std::string model_path = from_jstring(env, model_path_value);
    if (model_path.empty()) {
        set_error(ERROR_MODEL_LOAD_FAILED, "model path is empty");
        return ERROR_MODEL_LOAD_FAILED;
    }
    std::lock_guard<std::mutex> lock(g_runtime_mutex);
    if (g_model != nullptr) {
        llama_model_free(g_model);
        g_model = nullptr;
    }
    if (!g_backend_initialized) {
        llama_backend_init();
        g_backend_initialized = true;
    }
    llama_model_params parameters = llama_model_default_params();
    parameters.n_gpu_layers = 0;
    g_model = llama_model_load_from_file(model_path.c_str(), parameters);
    if (g_model == nullptr) {
        set_error(ERROR_MODEL_LOAD_FAILED, "llama.cpp could not load the validated model");
        return ERROR_MODEL_LOAD_FAILED;
    }
    clear_error();
    return ERROR_OK;
#endif
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_whypulse_why_1pulse_medgemma_NativeMedGemma_nativeInfer(
        JNIEnv *env,
        jobject,
        jstring prompt_value,
        jint max_output_tokens,
        jlong timeout_millis) {
#if !WHYPULSE_LLAMA_AVAILABLE
    set_error(ERROR_NATIVE_UNAVAILABLE, "llama.cpp was unavailable when the JNI library was built");
    return nullptr;
#else
    const std::string prompt = from_jstring(env, prompt_value);
    if (prompt.empty() || max_output_tokens < 1 || max_output_tokens > 512 || timeout_millis < 1) {
        set_error(ERROR_INVALID_PROMPT, "prompt or inference bounds are invalid");
        return nullptr;
    }

    std::lock_guard<std::mutex> runtime_lock(g_runtime_mutex);
    if (g_model == nullptr) {
        set_error(ERROR_MODEL_NOT_LOADED, "model is not loaded");
        return nullptr;
    }

    clear_error();
    g_cancelled.store(false);
    g_inference_active.store(true);
    const auto mark_inactive = [] { g_inference_active.store(false); };
    const auto started = std::chrono::steady_clock::now();
    const llama_vocab *vocab = llama_model_get_vocab(g_model);
    const int prompt_token_count = -llama_tokenize(
        vocab, prompt.c_str(), prompt.size(), nullptr, 0, true, true);
    if (prompt_token_count <= 0 || prompt_token_count + max_output_tokens > MAX_CONTEXT_TOKENS) {
        set_error(ERROR_TOKENIZATION_FAILED, "prompt does not fit the bounded context");
        mark_inactive();
        return nullptr;
    }
    std::vector<llama_token> prompt_tokens(static_cast<size_t>(prompt_token_count));
    if (llama_tokenize(
            vocab,
            prompt.c_str(),
            prompt.size(),
            prompt_tokens.data(),
            prompt_tokens.size(),
            true,
            true) < 0) {
        set_error(ERROR_TOKENIZATION_FAILED, "prompt tokenization failed");
        mark_inactive();
        return nullptr;
    }

    llama_context_params context_parameters = llama_context_default_params();
    context_parameters.n_ctx = static_cast<uint32_t>(prompt_token_count + max_output_tokens);
    context_parameters.n_batch = static_cast<uint32_t>(prompt_token_count);
    context_parameters.n_threads = 4;
    context_parameters.n_threads_batch = 4;
    InferenceAbortState abort_state{
        started + std::chrono::milliseconds(timeout_millis),
    };
    context_parameters.abort_callback = should_abort_inference;
    context_parameters.abort_callback_data = &abort_state;
    llama_context *context = llama_init_from_model(g_model, context_parameters);
    if (context == nullptr) {
        set_error(ERROR_CONTEXT_CREATION_FAILED, "llama.cpp could not create a context");
        mark_inactive();
        return nullptr;
    }

    llama_sampler_chain_params sampler_parameters = llama_sampler_chain_default_params();
    llama_sampler *sampler = llama_sampler_chain_init(sampler_parameters);
    llama_sampler_chain_add(sampler, llama_sampler_init_greedy());
    llama_batch batch = llama_batch_get_one(prompt_tokens.data(), prompt_tokens.size());
    std::string output;
    int generated = 0;

    while (generated < max_output_tokens) {
        if (g_cancelled.load()) {
            set_error(ERROR_CANCELLED, "inference was cancelled");
            break;
        }
        const auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now() - started);
        if (elapsed.count() > timeout_millis) {
            set_error(ERROR_TIMEOUT, "inference timed out");
            break;
        }
        if (llama_decode(context, batch) != 0) {
            if (g_cancelled.load()) {
                set_error(ERROR_CANCELLED, "inference was cancelled");
            } else if (std::chrono::steady_clock::now() > abort_state.deadline) {
                set_error(ERROR_TIMEOUT, "inference timed out");
            } else {
                set_error(ERROR_DECODE_FAILED, "llama.cpp decode failed");
            }
            break;
        }
        llama_token token = llama_sampler_sample(sampler, context, -1);
        if (llama_vocab_is_eog(vocab, token)) {
            clear_error();
            break;
        }
        output += token_piece(vocab, token);
        batch = llama_batch_get_one(&token, 1);
        generated += 1;
    }

    llama_sampler_free(sampler);
    llama_free(context);
    mark_inactive();
    if (g_last_error.load() != ERROR_OK) return nullptr;
    clear_error();
    return env->NewStringUTF(output.c_str());
#endif
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_whypulse_why_1pulse_medgemma_NativeMedGemma_nativeCancel(JNIEnv *, jobject) {
    const bool active = g_inference_active.load();
    if (active) g_cancelled.store(true);
    return active ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT void JNICALL
Java_com_whypulse_why_1pulse_medgemma_NativeMedGemma_nativeClose(JNIEnv *, jobject) {
    g_cancelled.store(true);
    std::lock_guard<std::mutex> lock(g_runtime_mutex);
#if WHYPULSE_LLAMA_AVAILABLE
    if (g_model != nullptr) {
        llama_model_free(g_model);
        g_model = nullptr;
    }
    if (g_backend_initialized) {
        llama_backend_free();
        g_backend_initialized = false;
    }
#endif
    clear_error();
}

extern "C" JNIEXPORT jint JNICALL
Java_com_whypulse_why_1pulse_medgemma_NativeMedGemma_nativeLastErrorCode(JNIEnv *, jobject) {
    return g_last_error.load();
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_whypulse_why_1pulse_medgemma_NativeMedGemma_nativeLastErrorMessage(
        JNIEnv *env, jobject) {
    std::lock_guard<std::mutex> lock(g_error_mutex);
    return env->NewStringUTF(g_last_error_message.c_str());
}

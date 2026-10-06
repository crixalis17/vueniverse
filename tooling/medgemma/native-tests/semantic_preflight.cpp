// Vocabulary-only host diagnostic. Never creates a context or evaluates tensors.
#include "llama.h"

#include <cstdint>
#include <fstream>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <vector>

namespace {
std::string read_file(const char *path, size_t bound) {
    std::ifstream stream(path, std::ios::binary);
    if (!stream) throw std::runtime_error("input could not be opened");
    std::string bytes((std::istreambuf_iterator<char>(stream)), {});
    if (bytes.empty() || bytes.size() > bound) throw std::runtime_error("input outside bound");
    return bytes;
}

std::vector<llama_token> tokenize(const llama_vocab *vocab, const std::string &prompt) {
    const int32_t needed = -llama_tokenize(vocab, prompt.data(), prompt.size(), nullptr, 0, true, true);
    if (needed < 1 || needed > 32768) throw std::runtime_error("invalid tokenizer sizing");
    std::vector<llama_token> tokens(static_cast<size_t>(needed));
    const int32_t actual = llama_tokenize(
        vocab, prompt.data(), prompt.size(), tokens.data(), tokens.size(), true, true);
    if (actual != needed) throw std::runtime_error("tokenizer sizing changed");
    return tokens;
}
}  // namespace

int main(int argc, char **argv) {
    if (argc != 47) {
        std::cerr << "Expected model followed by exactly 15 case/prompt/grammar triples\n";
        return 2;
    }
    llama_model *model = nullptr;
    try {
        auto params = llama_model_default_params();
        params.n_gpu_layers = 0;
        params.vocab_only = true;
        // No llama_backend_init, llama_init_from_model, llama_decode or sampling.
        model = llama_model_load_from_file(argv[1], params);
        if (!model) throw std::runtime_error("vocabulary-only load failed");
        const llama_vocab *vocab = llama_model_get_vocab(model);
        std::cout << "{\"vocab_only\":true,\"weights_loaded\":false,\"context_created\":false,"
                     "\"inference_performed\":false,\"cases\":[";
        for (int i = 2; i < argc; i += 3) {
            const std::string case_id = argv[i];
            if (case_id.empty() || case_id.find_first_not_of("abcdefghijklmnopqrstuvwxyz_")
                    != std::string::npos) throw std::runtime_error("invalid case ID");
            const auto prompt = read_file(argv[i + 1], 32768);
            const auto grammar = read_file(argv[i + 2], 16384);
            const auto tokens = tokenize(vocab, prompt);
            llama_sampler *sampler = llama_sampler_init_grammar(vocab, grammar.c_str(), "root");
            const bool initialized = sampler != nullptr;
            if (sampler) llama_sampler_free(sampler);
            if (i != 2) std::cout << ',';
            std::cout << "{\"case_id\":\"" << case_id << "\",\"prompt_tokens\":"
                      << tokens.size() << ",\"grammar_initialized\":"
                      << (initialized ? "true" : "false") << ",\"token_ids\":[";
            for (size_t j = 0; j < tokens.size(); ++j) {
                if (j) std::cout << ',';
                std::cout << tokens[j];
            }
            std::cout << "]}";
        }
        std::cout << "]}\n";
        llama_model_free(model);
        return 0;
    } catch (const std::exception &error) {
        if (model) llama_model_free(model);
        std::cerr << error.what() << '\n';
        return 1;
    }
}

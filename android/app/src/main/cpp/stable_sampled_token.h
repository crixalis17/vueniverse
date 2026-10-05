#pragma once

// llama_batch_get_one borrows a token pointer. Storage must outlive the next
// decode call, not merely the sampling loop iteration that creates the batch.
template <typename Token>
class StableSampledToken {
public:
    StableSampledToken() = default;
    StableSampledToken(const StableSampledToken &) = delete;
    StableSampledToken &operator=(const StableSampledToken &) = delete;
    StableSampledToken(StableSampledToken &&) = delete;
    StableSampledToken &operator=(StableSampledToken &&) = delete;

    Token *store(Token token) {
        value_ = token;
        return &value_;
    }

private:
    Token value_{};
};

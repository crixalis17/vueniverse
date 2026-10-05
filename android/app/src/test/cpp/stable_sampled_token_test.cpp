#include "stable_sampled_token.h"
#include <cassert>
#include <cstdint>
#include <type_traits>

int main() {
    using Storage = StableSampledToken<std::int32_t>;
    static_assert(!std::is_copy_constructible<Storage>::value);
    static_assert(!std::is_move_constructible<Storage>::value);
    Storage storage;
    std::int32_t *borrowed_batch_token = nullptr;
    for (std::int32_t step = 0; step < 10000; ++step) {
        // Model the NEXT decode reading the prior iteration's borrowed pointer.
        if (borrowed_batch_token != nullptr) assert(*borrowed_batch_token == step - 1);
        std::int32_t *next_pointer = nullptr;
        {
            const std::int32_t loop_local_sample = step;
            next_pointer = storage.store(loop_local_sample);
        }
        // The sample above is dead here, but the batch storage is still alive.
        assert(*next_pointer == step);
        if (borrowed_batch_token != nullptr) assert(next_pointer == borrowed_batch_token);
        borrowed_batch_token = next_pointer;
    }
    assert(*borrowed_batch_token == 9999);
    assert(*storage.store(-1) == -1);
}

#include "cache_operations.h"
#include "security_keywords.h"
#include <cstring>
#include <random>
#include <algorithm>
#include <android/log.h>

#define TAG "CacheOps"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)

namespace molly {
namespace security {

void CacheOperations::flush_cache_line(void* addr) {
#ifdef __aarch64__
    asm volatile("dc civac, %0" : : "r" (addr) : "memory");
#endif
}

void CacheOperations::prefetch_cache_line(void* addr) {
#ifdef __aarch64__
    asm volatile("prfm pldl1keep, [%0]" : : "r" (addr));
#endif
}

void CacheOperations::poison_cache(int intensity_percent) {
    // Allocate and access random memory locations to pollute cache
    size_t poison_size = (1024 * 1024 * intensity_percent) / 100;  // Up to 1MB
    if (poison_size == 0) return;

    uint8_t* poison_buffer = new uint8_t[poison_size];

    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, poison_size - 64);

    // Randomly access cache lines
    int num_accesses = (intensity_percent * 100);
    for (int i = 0; i < num_accesses; i++) {
        size_t offset = dis(gen);
        volatile uint8_t dummy = poison_buffer[offset];
        (void)dummy;
    }

    delete[] poison_buffer;

    LOGD("Cache poisoned with intensity %d%%", intensity_percent);
}

void CacheOperations::flush_cache_range(void* addr, size_t size) {
    uint8_t* p = static_cast<uint8_t*>(addr);
    for (size_t i = 0; i < size; i += 64) {
        flush_cache_line(&p[i]);
    }
#ifdef __aarch64__
    asm volatile("dsb sy" ::: "memory");
#endif
}

void CacheOperations::prefetch_cache_range(void* addr, size_t size) {
    uint8_t* p = static_cast<uint8_t*>(addr);
    for (size_t i = 0; i < size; i += 64) {
        prefetch_cache_line(&p[i]);
    }
}

void CacheOperations::fill_cache_with_noise(size_t size_kb, int screen_x, int screen_y, bool enable_gallop_dash) {
    size_t size_bytes = size_kb * 1024;
    uint8_t* noise_buffer = new uint8_t[size_bytes];

    // Fill with pseudo-random data
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, 255);

    // "Bury them with bullshit" - generate multiple passes for more noise
    int passes = enable_gallop_dash ? 10 : 3;  // Gallop dash = rapid generation

    for (int pass = 0; pass < passes; pass++) {
        // Fill with random data
        for (size_t i = 0; i < size_bytes; i++) {
            noise_buffer[i] = dis(gen);
        }

        // Embed security keywords at random positions
        std::uniform_int_distribution<size_t> pos_dis(0, size_bytes - 100);  // Leave room for keywords
        size_t keyword_count = (size_bytes / 1024) + 1;  // ~1 keyword per KB

        for (size_t k = 0; k < keyword_count && k < SecurityKeywords::getTotalKeywordCount(); k++) {
            const char* keyword = SecurityKeywords::getRandomKeyword(k % SecurityKeywords::getTotalKeywordCount());
            if (keyword) {
                size_t keyword_len = SecurityKeywords::getKeywordLength(keyword);
                size_t pos = pos_dis(gen);

                // Ensure keyword fits
                if (pos + keyword_len < size_bytes) {
                    memcpy(noise_buffer + pos, keyword, keyword_len);
                }
            }
        }

        // Embed screen coordinates as bytes
        if (screen_x != 0 || screen_y != 0) {
            std::uniform_int_distribution<size_t> coord_pos_dis(0, size_bytes - 8);
            size_t coord_pos = coord_pos_dis(gen);

            // Embed X coordinate (4 bytes)
            if (coord_pos + 4 < size_bytes) {
                noise_buffer[coord_pos] = (screen_x >> 24) & 0xFF;
                noise_buffer[coord_pos + 1] = (screen_x >> 16) & 0xFF;
                noise_buffer[coord_pos + 2] = (screen_x >> 8) & 0xFF;
                noise_buffer[coord_pos + 3] = screen_x & 0xFF;
            }

            // Embed Y coordinate (4 bytes)
            if (coord_pos + 8 < size_bytes) {
                noise_buffer[coord_pos + 4] = (screen_y >> 24) & 0xFF;
                noise_buffer[coord_pos + 5] = (screen_y >> 16) & 0xFF;
                noise_buffer[coord_pos + 6] = (screen_y >> 8) & 0xFF;
                noise_buffer[coord_pos + 7] = screen_y & 0xFF;
            }
        }
    }

    // Access all data to load into cache
    // "Gallop dash" - rapid access pattern
    volatile uint8_t dummy = 0;
    int access_multiplier = enable_gallop_dash ? 10 : 1;
    for (int multiplier = 0; multiplier < access_multiplier; multiplier++) {
        for (size_t i = 0; i < size_bytes; i += 64) {
            dummy += noise_buffer[i];
        }
    }

    delete[] noise_buffer;

    LOGD("Filled cache with %zu KB of noise (x=%d, y=%d, gallop=%s)",
         size_kb, screen_x, screen_y, enable_gallop_dash ? "yes" : "no");
}

} // namespace security
} // namespace molly

#include "memory_scrambler.h"
#include "security_keywords.h"
#include <cstring>
#include <cstdio>
#include <random>
#include <vector>
#include <algorithm>
#include <android/log.h>

#define TAG "MemoryScrambler"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)

namespace molly {
namespace security {

void MemoryScrambler::secure_wipe(void* addr, size_t size) {
    if (!addr || size == 0) return;

    volatile uint8_t* p = static_cast<volatile uint8_t*>(addr);

    // Multiple pass wipe (DoD 5220.22-M standard)
    // Pass 1: Write zeros
    for (size_t i = 0; i < size; i++) {
        p[i] = 0x00;
    }

    // Pass 2: Write ones
    for (size_t i = 0; i < size; i++) {
        p[i] = 0xFF;
    }

    // Pass 3: Write random
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, 255);

    for (size_t i = 0; i < size; i++) {
        p[i] = dis(gen);
    }

    // Final pass: Write zeros
    for (size_t i = 0; i < size; i++) {
        p[i] = 0x00;
    }

    // Memory barrier to prevent optimization
    asm volatile("" ::: "memory");
}

void MemoryScrambler::scramble_memory(void* addr, size_t size) {
    if (!addr || size == 0) return;

    volatile uint8_t* p = static_cast<volatile uint8_t*>(addr);
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, 255);

    for (size_t i = 0; i < size; i++) {
        p[i] = dis(gen);
    }

    LOGD("Scrambled %zu bytes of memory", size);
}

void MemoryScrambler::fill_available_ram(int fill_percent) {
    if (fill_percent <= 0 || fill_percent > 100) {
        return;
    }

    LOGD("Attempting to fill %d%% of available RAM", fill_percent);

    const size_t CHUNK_SIZE = 10 * 1024 * 1024;  // 10MB chunks
    std::vector<uint8_t*> allocated_chunks;

    try {
        // Allocate until we fail
        size_t total_allocated = 0;
        while (true) {
            uint8_t* chunk = new uint8_t[CHUNK_SIZE];
            if (!chunk) break;

            // Fill with random data
            std::random_device rd;
            std::mt19937 gen(rd());
            std::uniform_int_distribution<> dis(0, 255);

            for (size_t i = 0; i < CHUNK_SIZE; i += 4096) {
                chunk[i] = dis(gen);
            }

            allocated_chunks.push_back(chunk);
            total_allocated += CHUNK_SIZE;

            // Check if we've allocated enough based on percentage
            if (allocated_chunks.size() >= static_cast<size_t>(fill_percent)) {
                break;
            }
        }

        LOGD("Allocated %zu MB, wiping and releasing", total_allocated / (1024 * 1024));

        // Wipe and free
        for (uint8_t* chunk : allocated_chunks) {
            secure_wipe(chunk, CHUNK_SIZE);
            delete[] chunk;
        }

    } catch (...) {
        LOGD("RAM fill completed, cleaning up");
        for (uint8_t* chunk : allocated_chunks) {
            delete[] chunk;
        }
    }
}

void MemoryScrambler::create_decoy_patterns(size_t size_mb, int screen_x, int screen_y, bool enable_gallop_dash) {
    size_t size_bytes = size_mb * 1024 * 1024;

    uint8_t* decoy_buffer = new uint8_t[size_bytes];

    // "Bury them with bullshit" - generate multiple layers
    int layers = enable_gallop_dash ? 5 : 2;

    for (int layer = 0; layer < layers; layer++) {
        // Create patterns that look like sensitive data
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_int_distribution<> dis(0, 255);

        // Pattern 1: Fake key material (high entropy) - embed keywords here too
        for (size_t i = 0; i < size_bytes / 4; i++) {
            decoy_buffer[i] = dis(gen);
        }

        // Embed security keywords in key material section
        std::uniform_int_distribution<size_t> keyword_pos_dis(0, size_bytes / 4 - 100);
        size_t keyword_count = (size_bytes / (1024 * 1024)) * 2;  // ~2 keywords per MB

        for (size_t k = 0; k < keyword_count && k < SecurityKeywords::getTotalKeywordCount(); k++) {
            const char* keyword = SecurityKeywords::getRandomKeyword(k % SecurityKeywords::getTotalKeywordCount());
            if (keyword) {
                size_t keyword_len = SecurityKeywords::getKeywordLength(keyword);
                size_t pos = keyword_pos_dis(gen);

                if (pos + keyword_len < size_bytes / 4) {
                    memcpy(decoy_buffer + pos, keyword, keyword_len);
                }
            }
        }

        // Pattern 2: Fake text data (printable ASCII) - embed keywords here
        std::uniform_int_distribution<> text_dis(32, 126);
        size_t text_start = size_bytes / 4;
        size_t text_end = size_bytes / 2;

        for (size_t i = text_start; i < text_end; i++) {
            decoy_buffer[i] = text_dis(gen);
        }

        // Embed security keywords in text section (most natural place)
        std::uniform_int_distribution<size_t> text_keyword_pos_dis(text_start, text_end - 100);
        size_t text_keyword_count = (size_bytes / (1024 * 1024)) * 5;  // ~5 keywords per MB in text section

        for (size_t k = 0; k < text_keyword_count && k < SecurityKeywords::getTotalKeywordCount(); k++) {
            const char* keyword = SecurityKeywords::getRandomKeyword(k % SecurityKeywords::getTotalKeywordCount());
            if (keyword) {
                size_t keyword_len = SecurityKeywords::getKeywordLength(keyword);
                size_t pos = text_keyword_pos_dis(gen);

                if (pos + keyword_len < text_end) {
                    // Create variations: uppercase, lowercase, mixed
                    std::uniform_int_distribution<> case_dis(0, 2);
                    int case_type = case_dis(gen);

                    if (case_type == 0) {
                        // Uppercase
                        for (size_t j = 0; j < keyword_len; j++) {
                            decoy_buffer[pos + j] = (keyword[j] >= 'a' && keyword[j] <= 'z')
                                ? (keyword[j] - 32) : keyword[j];
                        }
                    } else if (case_type == 1) {
                        // Lowercase
                        for (size_t j = 0; j < keyword_len; j++) {
                            decoy_buffer[pos + j] = (keyword[j] >= 'A' && keyword[j] <= 'Z')
                                ? (keyword[j] + 32) : keyword[j];
                        }
                    } else {
                        // Original case
                        memcpy(decoy_buffer + pos, keyword, keyword_len);
                    }
                }
            }
        }

        // Embed screen coordinates in text section
        if (screen_x != 0 || screen_y != 0) {
            std::uniform_int_distribution<size_t> coord_pos_dis(text_start, text_end - 16);
            size_t coord_pos = coord_pos_dis(gen);

            // Embed as ASCII representation of coordinates
            char coord_str[32];
            snprintf(coord_str, sizeof(coord_str), "X:%d Y:%d", screen_x, screen_y);
            size_t coord_len = strlen(coord_str);

            if (coord_pos + coord_len < text_end) {
                memcpy(decoy_buffer + coord_pos, coord_str, coord_len);
            }

            // Also embed as binary
            if (coord_pos + 16 < text_end) {
                decoy_buffer[coord_pos + coord_len] = (screen_x >> 24) & 0xFF;
                decoy_buffer[coord_pos + coord_len + 1] = (screen_x >> 16) & 0xFF;
                decoy_buffer[coord_pos + coord_len + 2] = (screen_x >> 8) & 0xFF;
                decoy_buffer[coord_pos + coord_len + 3] = screen_x & 0xFF;
                decoy_buffer[coord_pos + coord_len + 4] = (screen_y >> 24) & 0xFF;
                decoy_buffer[coord_pos + coord_len + 5] = (screen_y >> 16) & 0xFF;
                decoy_buffer[coord_pos + coord_len + 6] = (screen_y >> 8) & 0xFF;
                decoy_buffer[coord_pos + coord_len + 7] = screen_y & 0xFF;
            }
        }

        // Pattern 3: Structured data (alternating patterns)
        for (size_t i = size_bytes / 2; i < size_bytes; i++) {
            decoy_buffer[i] = (i % 2 == 0) ? 0xAA : 0x55;
        }
    }

    // Keep in memory briefly then scramble
    // "Gallop dash" - rapid access pattern
    volatile uint8_t dummy = 0;
    int access_multiplier = enable_gallop_dash ? 20 : 1;
    for (int multiplier = 0; multiplier < access_multiplier; multiplier++) {
        for (size_t i = 0; i < size_bytes; i += 4096) {
            dummy += decoy_buffer[i];
        }
    }

    scramble_memory(decoy_buffer, size_bytes);
    delete[] decoy_buffer;

    LOGD("Created and scrambled %zu MB of decoy patterns (x=%d, y=%d, gallop=%s)",
         size_mb, screen_x, screen_y, enable_gallop_dash ? "yes" : "no");
}

void MemoryScrambler::overwrite_with_pattern(void* addr, size_t size, uint8_t pattern) {
    volatile uint8_t* p = static_cast<volatile uint8_t*>(addr);
    for (size_t i = 0; i < size; i++) {
        p[i] = pattern;
    }
}

} // namespace security
} // namespace molly

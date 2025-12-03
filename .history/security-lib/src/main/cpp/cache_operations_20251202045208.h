#ifndef MOLLY_SECURITY_CACHE_OPERATIONS_H
#define MOLLY_SECURITY_CACHE_OPERATIONS_H

#include <cstdint>
#include <cstddef>

namespace molly {
namespace security {

class CacheOperations {
public:
    // Poison cache with dummy data to disrupt side-channel attacks
    static void poison_cache(int intensity_percent);

    // Flush cache lines
    static void flush_cache_range(void* addr, size_t size);

    // Prefetch data into cache (for obfuscation)
    static void prefetch_cache_range(void* addr, size_t size);

    // Fill cache with noise pattern
    // screen_x, screen_y: Screen click coordinates to embed in noise (0 if not available)
    // enable_gallop_dash: Enable rapid burst generation mode
    static void fill_cache_with_noise(size_t size_kb, int screen_x = 0, int screen_y = 0, bool enable_gallop_dash = false);

private:
    static void flush_cache_line(void* addr);
    static void prefetch_cache_line(void* addr);
};

} // namespace security
} // namespace molly

#endif // MOLLY_SECURITY_CACHE_OPERATIONS_H

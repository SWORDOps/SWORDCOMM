#ifndef MOLLY_SECURITY_HYPERVISOR_DISRUPTOR_H
#define MOLLY_SECURITY_HYPERVISOR_DISRUPTOR_H

#include <cstddef>
#include <cstdint>

namespace molly {
namespace security {

/**
 * Advanced EL2 hypervisor disruption techniques
 * Focused on TIMING CHAOS to maximize disruption of hypervisor monitoring
 *
 * Strategy: "Bury them with bullshit" + "Gallop dash" TTP
 * - Overwhelm virtualized timers with high-frequency operations
 * - Create unpredictable timing patterns that confuse monitoring
 * - Force frequent hypervisor traps through timer manipulation
 */
class HypervisorDisruptor {
public:
    // ============================================================================
    // CLOCK SOURCE MANIPULATION
    // Rapid switching and reading to overwhelm virtualized timers
    // ============================================================================

    // Flood timer reads - overwhelm virtualized CNTVCT_EL0
    static void clock_read_flood(int iterations);

    // Rapid clock source switching and comparison
    static void clock_source_chaos(int duration_ms);

    // Measure and inject clock skew noise
    static void clock_skew_injection(int intensity_percent);

    // High-frequency timestamp sampling
    static void timestamp_flood(int iterations, int batch_size);

    // ============================================================================
    // TIMER FLOODING
    // Force frequent hypervisor timer traps
    // ============================================================================

    // Rapid timer arm/disarm cycles
    static void timer_arm_disarm_flood(int cycles);

    // Short timeout timer flooding
    static void short_timeout_flood(int duration_ms, int timeout_us);

    // Timer interrupt generation chaos
    static void timer_interrupt_chaos(int intensity_percent);

    // Nanosleep flooding with variable durations
    static void nanosleep_flood(int iterations, int max_ns);

    // ============================================================================
    // SCHEDULING DISRUPTION
    // Confuse hypervisor scheduling monitoring
    // ============================================================================

    // CPU affinity manipulation chaos
    static void cpu_affinity_chaos(int iterations);

    // Priority manipulation flood
    static void priority_chaos(int iterations);

    // Yield/sleep chaos patterns
    static void yield_chaos(int iterations, int intensity_percent);

    // Thread spawn/destroy flooding
    static void thread_flood(int thread_count, int iterations);

    // Futex-based timing chaos
    static void futex_timing_chaos(int iterations);

    // ============================================================================
    // SPECULATIVE TIMING ATTACKS
    // Timing-based attacks that confuse hypervisor monitoring
    // ============================================================================

    // Branch misprediction timing flood
    static void branch_timing_flood(int iterations);

    // Pipeline stall patterns
    static void pipeline_stall_chaos(int iterations);

    // Speculative execution timing noise
    static void speculative_timing_noise(int intensity_percent);

    // ============================================================================
    // MEMORY TIMING ATTACKS
    // Memory access patterns that create timing chaos
    // ============================================================================

    // Cache timing side-channel noise
    static void cache_timing_noise(int iterations, size_t buffer_size_kb);

    // Row hammer timing patterns (for disruption, not exploitation)
    static void row_hammer_timing(int iterations);

    // DRAM refresh timing interference
    static void dram_refresh_interference(int duration_ms);

    // Memory access timing variance injection
    static void memory_timing_variance(int iterations, int variance_percent);

    // ============================================================================
    // INTERRUPT TIMING CHAOS
    // Software interrupt and signal timing manipulation
    // ============================================================================

    // Software interrupt flooding
    static void software_interrupt_flood(int count);

    // Signal handler timing chaos
    static void signal_timing_chaos(int iterations);

    // IPC timing manipulation
    static void ipc_timing_chaos(int iterations);

    // ============================================================================
    // SYSCALL TIMING ATTACKS
    // High-frequency syscall patterns
    // ============================================================================

    // High-frequency syscall flood
    static void syscall_flood(int iterations);

    // Syscall timing variance injection
    static void syscall_timing_variance(int iterations, int variance_us);

    // gettime syscall flood (forces hypervisor timer virtualization)
    static void gettime_flood(int iterations);

    // ============================================================================
    // COMBINED ATTACKS
    // Maximum chaos modes
    // ============================================================================

    // Combined maximum timing disruption attack
    // "Nuclear option" - all timing techniques simultaneously
    static void maximum_timing_chaos(int duration_ms, int intensity_percent);

    // Continuous timing disruption mode
    // "Gallop dash" - rapid burst patterns
    static void continuous_timing_chaos(int intensity_percent, bool enable_gallop_dash);

    // Adaptive timing chaos (adjusts based on detected hypervisor response)
    static void adaptive_timing_chaos(int duration_ms);

private:
    // Helper functions
    static uint64_t read_timestamp_counter();
    static void busy_wait_cycles(uint64_t cycles);
    static void memory_barrier();
    static void data_sync_barrier();
    static void instruction_sync_barrier();
};

} // namespace security
} // namespace molly

#endif // MOLLY_SECURITY_HYPERVISOR_DISRUPTOR_H


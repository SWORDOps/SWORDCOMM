#ifndef MOLLY_SECURITY_HYPERVISOR_DISRUPTOR_H
#define MOLLY_SECURITY_HYPERVISOR_DISRUPTOR_H

#include <cstddef>
#include <cstdint>

namespace molly {
namespace security {

/**
 * Advanced EL2 hypervisor disruption techniques
 * Designed to maximize disruption of hypervisor monitoring and control
 */
class HypervisorDisruptor {
public:
    // TLB (Translation Lookaside Buffer) manipulation
    // Force hypervisor to handle page table walks
    static void flush_tlb_aggressive(int intensity_percent);
    static void tlb_bombardment(int duration_ms);

    // Branch predictor attacks
    // Confuse branch prediction which hypervisors monitor
    static void branch_predictor_poison(int intensity_percent);
    static void mispredict_flood(int iterations);

    // Cache line eviction patterns
    // Aggressive cache eviction to disrupt hypervisor cache monitoring
    static void cache_line_eviction_attack(size_t target_cache_size_kb, int intensity);
    static void cache_set_conflict_attack(int sets, int ways);

    // Memory barrier manipulation
    // Force memory ordering operations that hypervisors must handle
    static void memory_barrier_spam(int count);
    static void memory_fence_attack(int intensity);

    // Hypervisor-specific instruction sequences
    // Sequences that force hypervisor intervention
    static void hypercall_flood(int count);
    static void exception_generation_attack(int intensity);

    // Interrupt and exception flooding
    // Overwhelm hypervisor exception handling
    static void interrupt_flood(int duration_ms);
    static void exception_flood(int count);

    // SMC (Secure Monitor Call) abuse
    // Force secure monitor transitions
    static void smc_abuse_attack(int intensity);

    // Performance counter manipulation
    // Overwhelm performance counter monitoring
    static void perf_counter_flood(int intensity);
    static void perf_counter_poison(int duration_ms);

    // Page table manipulation
    // Force page table walks and TLB refills
    static void page_table_walk_attack(int pages, int intensity);
    static void page_fault_flood(int count);

    // Combined maximum disruption attack
    // "Nuclear option" - all techniques simultaneously
    static void maximum_disruption_attack(int duration_ms, int intensity_percent);

    // Continuous disruption mode
    // Run disruption techniques continuously
    static void continuous_disruption(int intensity_percent, bool enable_gallop_dash);
};

} // namespace security
} // namespace molly

#endif // MOLLY_SECURITY_HYPERVISOR_DISRUPTOR_H


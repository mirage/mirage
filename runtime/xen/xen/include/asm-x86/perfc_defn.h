/* This file is legitimately included multiple times. */
/*#ifndef __XEN_PERFC_DEFN_H__*/
/*#define __XEN_PERFC_DEFN_H__*/

PERFCOUNTER_ARRAY(exceptions,           "exceptions", 32)

#define VMX_PERF_EXIT_REASON_SIZE 56
#define VMX_PERF_VECTOR_SIZE 0x20
PERFCOUNTER_ARRAY(vmexits,              "vmexits", VMX_PERF_EXIT_REASON_SIZE)
PERFCOUNTER_ARRAY(cause_vector,         "cause vector", VMX_PERF_VECTOR_SIZE)

#define VMEXIT_NPF_PERFC 141
#define SVM_PERF_EXIT_REASON_SIZE (1+141)
PERFCOUNTER_ARRAY(svmexits,             "SVMexits", SVM_PERF_EXIT_REASON_SIZE)

PERFCOUNTER(seg_fixups,             "segmentation fixups")

PERFCOUNTER(apic_timer,             "apic timer interrupts")

PERFCOUNTER(domain_page_tlb_flush,  "domain page tlb flushes")

PERFCOUNTER(calls_to_mmuext_op,         "calls to mmuext_op")
PERFCOUNTER(num_mmuext_ops,             "mmuext ops")
PERFCOUNTER(calls_to_mmu_update,        "calls to mmu_update")
PERFCOUNTER(num_page_updates,           "page updates")
PERFCOUNTER(writable_mmu_updates,       "mmu_updates of writable pages")
PERFCOUNTER(calls_to_update_va,         "calls to update_va_map")
PERFCOUNTER(page_faults,            "page faults")
PERFCOUNTER(copy_user_faults,       "copy_user faults")

PERFCOUNTER(map_domain_page_count,  "map_domain_page count")
PERFCOUNTER(ptwr_emulations,        "writable pt emulations")

PERFCOUNTER(exception_fixed,        "pre-exception fixed")

PERFCOUNTER(guest_walk,            "guest pagetable walks")

/* Shadow counters */
PERFCOUNTER(shadow_alloc,          "calls to shadow_alloc")
PERFCOUNTER(shadow_alloc_tlbflush, "shadow_alloc flushed TLBs")

/* STATUS counters do not reset when 'P' is hit */
PERFSTATUS(shadow_alloc_count,         "number of shadow pages in use")
PERFCOUNTER(shadow_free,           "calls to shadow_free")
PERFCOUNTER(shadow_prealloc_1,     "shadow recycles old shadows")
PERFCOUNTER(shadow_prealloc_2,     "shadow recycles in-use shadows")
PERFCOUNTER(shadow_linear_map_failed, "shadow hit read-only linear map")
PERFCOUNTER(shadow_a_update,       "shadow A bit update")
PERFCOUNTER(shadow_ad_update,      "shadow A&D bit update")
PERFCOUNTER(shadow_fault,          "calls to shadow_fault")
PERFCOUNTER(shadow_fault_fast_gnp, "shadow_fault fast path n/p")
PERFCOUNTER(shadow_fault_fast_mmio, "shadow_fault fast path mmio")
PERFCOUNTER(shadow_fault_fast_fail, "shadow_fault fast path error")
PERFCOUNTER(shadow_fault_bail_bad_gfn, "shadow_fault guest bad gfn")
PERFCOUNTER(shadow_fault_bail_real_fault, 
                                        "shadow_fault really guest fault")
PERFCOUNTER(shadow_fault_emulate_read, "shadow_fault emulates a read")
PERFCOUNTER(shadow_fault_emulate_write, "shadow_fault emulates a write")
PERFCOUNTER(shadow_fault_emulate_failed, "shadow_fault emulator fails")
PERFCOUNTER(shadow_fault_emulate_stack, "shadow_fault emulate stack write")
PERFCOUNTER(shadow_fault_emulate_wp, "shadow_fault emulate for CR0.WP=0")
PERFCOUNTER(shadow_fault_fast_emulate, "shadow_fault fast emulate")
PERFCOUNTER(shadow_fault_fast_emulate_fail,
                                   "shadow_fault fast emulate failed")
PERFCOUNTER(shadow_fault_mmio,     "shadow_fault handled as mmio")
PERFCOUNTER(shadow_fault_fixed,    "shadow_fault fixed fault")
PERFCOUNTER(shadow_ptwr_emulate,   "shadow causes ptwr to emulate")
PERFCOUNTER(shadow_validate_gl1e_calls, "calls to shadow_validate_gl1e")
PERFCOUNTER(shadow_validate_gl2e_calls, "calls to shadow_validate_gl2e")
PERFCOUNTER(shadow_validate_gl3e_calls, "calls to shadow_validate_gl3e")
PERFCOUNTER(shadow_validate_gl4e_calls, "calls to shadow_validate_gl4e")
PERFCOUNTER(shadow_hash_lookups,   "calls to shadow_hash_lookup")
PERFCOUNTER(shadow_hash_lookup_head, "shadow hash hit in bucket head")
PERFCOUNTER(shadow_hash_lookup_miss, "shadow hash misses")
PERFCOUNTER(shadow_get_shadow_status, "calls to get_shadow_status")
PERFCOUNTER(shadow_hash_inserts,   "calls to shadow_hash_insert")
PERFCOUNTER(shadow_hash_deletes,   "calls to shadow_hash_delete")
PERFCOUNTER(shadow_writeable,      "shadow removes write access")
PERFCOUNTER(shadow_writeable_h_1,  "shadow writeable: 32b w2k3")
PERFCOUNTER(shadow_writeable_h_2,  "shadow writeable: 32pae w2k3")
PERFCOUNTER(shadow_writeable_h_3,  "shadow writeable: 64b w2k3")
PERFCOUNTER(shadow_writeable_h_4,  "shadow writeable: linux low/solaris")
PERFCOUNTER(shadow_writeable_h_5,  "shadow writeable: linux high")
PERFCOUNTER(shadow_writeable_h_6,  "shadow writeable: FreeBSD")
PERFCOUNTER(shadow_writeable_h_7,  "shadow writeable: sl1p")
PERFCOUNTER(shadow_writeable_h_8,  "shadow writeable: sl1p failed")
PERFCOUNTER(shadow_writeable_bf,   "shadow writeable brute-force")
PERFCOUNTER(shadow_writeable_bf_1, "shadow writeable resync bf")
PERFCOUNTER(shadow_mappings,       "shadow removes all mappings")
PERFCOUNTER(shadow_mappings_bf,    "shadow rm-mappings brute-force")
PERFCOUNTER(shadow_early_unshadow, "shadow unshadows for fork/exit")
PERFCOUNTER(shadow_unshadow,       "shadow unshadows a page")
PERFCOUNTER(shadow_up_pointer,     "shadow unshadow by up-pointer")
PERFCOUNTER(shadow_unshadow_bf,    "shadow unshadow brute-force")
PERFCOUNTER(shadow_get_page_fail,  "shadow_get_page_from_l1e failed")
PERFCOUNTER(shadow_check_gwalk,    "shadow checks gwalk")
PERFCOUNTER(shadow_inconsistent_gwalk, "shadow check inconsistent gwalk")
PERFCOUNTER(shadow_rm_write_flush_tlb,
                                   "shadow flush tlb by removing write perm")

PERFCOUNTER(shadow_invlpg,         "shadow emulates invlpg")
PERFCOUNTER(shadow_invlpg_fault,   "shadow invlpg faults")

PERFCOUNTER(shadow_em_ex_pt,       "shadow extra pt write")
PERFCOUNTER(shadow_em_ex_non_pt,   "shadow extra non-pt-write op")
PERFCOUNTER(shadow_em_ex_fail,     "shadow extra emulation failed")

PERFCOUNTER(shadow_oos_fixup_add,  "shadow OOS fixup adds")
PERFCOUNTER(shadow_oos_fixup_evict,"shadow OOS fixup evictions")
PERFCOUNTER(shadow_unsync,         "shadow OOS unsyncs")
PERFCOUNTER(shadow_unsync_evict,   "shadow OOS evictions")
PERFCOUNTER(shadow_resync,         "shadow OOS resyncs")

PERFCOUNTER(mshv_call_sw_addr_space,    "MS Hv Switch Address Space")
PERFCOUNTER(mshv_call_flush_tlb_list,   "MS Hv Flush TLB list")
PERFCOUNTER(mshv_call_flush_tlb_all,    "MS Hv Flush TLB all")
PERFCOUNTER(mshv_call_long_wait,        "MS Hv Notify long wait")
PERFCOUNTER(mshv_rdmsr_osid,            "MS Hv rdmsr Guest OS ID")
PERFCOUNTER(mshv_rdmsr_hc_page,         "MS Hv rdmsr hypercall page")
PERFCOUNTER(mshv_rdmsr_vp_index,        "MS Hv rdmsr vp index")
PERFCOUNTER(mshv_rdmsr_icr,             "MS Hv rdmsr icr")
PERFCOUNTER(mshv_rdmsr_tpr,             "MS Hv rdmsr tpr")
PERFCOUNTER(mshv_wrmsr_osid,            "MS Hv wrmsr Guest OS ID")
PERFCOUNTER(mshv_wrmsr_hc_page,         "MS Hv wrmsr hypercall page")
PERFCOUNTER(mshv_wrmsr_vp_index,        "MS Hv wrmsr vp index")
PERFCOUNTER(mshv_wrmsr_icr,             "MS Hv wrmsr icr")
PERFCOUNTER(mshv_wrmsr_tpr,             "MS Hv wrmsr tpr")
PERFCOUNTER(mshv_wrmsr_eoi,             "MS Hv wrmsr eoi")

PERFCOUNTER(realmode_emulations, "realmode instructions emulated")
PERFCOUNTER(realmode_exits,      "vmexits from realmode")

PERFCOUNTER(pauseloop_exits, "vmexits from Pause-Loop Detection")

/*#endif*/ /* __XEN_PERFC_DEFN_H__ */

/* This file is legitimately included multiple times. */

PERFCOUNTER(dtlb_translate,       "dtlb hit")

PERFCOUNTER(tr_translate,         "TR hit")

PERFCOUNTER(vhpt_translate,       "virtual vhpt translation")
PERFCOUNTER(fast_vhpt_translate,  "virtual vhpt fast translation")

PERFCOUNTER(recover_to_page_fault,    "recoveries to page fault")
PERFCOUNTER(recover_to_break_fault,   "recoveries to break fault")

PERFCOUNTER(phys_translate,       "metaphysical translation")

PERFCOUNTER(idle_when_pending,    "vcpu idle at event")

PERFCOUNTER(pal_halt_light,       "calls to pal_halt_light")

PERFCOUNTER(lazy_cover,           "lazy cover")

PERFCOUNTER(mov_to_ar_imm,        "privop mov_to_ar_imm")
PERFCOUNTER(mov_to_ar_reg,        "privop mov_to_ar_reg")
PERFCOUNTER(mov_from_ar,          "privop privified-mov_from_ar")
PERFCOUNTER(ssm,                  "privop ssm")
PERFCOUNTER(rsm,                  "privop rsm")
PERFCOUNTER(rfi,                  "privop rfi")
PERFCOUNTER(bsw0,                 "privop bsw0")
PERFCOUNTER(bsw1,                 "privop bsw1")
PERFCOUNTER(cover,                "privop cover")
PERFCOUNTER(fc,                   "privop privified-fc")
PERFCOUNTER(cpuid,                "privop privified-cpuid")

PERFCOUNTER_ARRAY(mov_to_cr,          "privop mov to cr", 128)
PERFCOUNTER_ARRAY(mov_from_cr,        "privop mov from cr", 128)

PERFCOUNTER_ARRAY(misc_privop,        "privop misc", 64)

// privileged instructions to fall into vmx_entry
PERFCOUNTER(vmx_rsm,              "vmx privop rsm")
PERFCOUNTER(vmx_ssm,              "vmx privop ssm")
PERFCOUNTER(vmx_mov_to_psr,       "vmx privop mov_to_psr")
PERFCOUNTER(vmx_mov_from_psr,     "vmx privop mov_from_psr")
PERFCOUNTER(vmx_mov_from_cr,      "vmx privop mov_from_cr")
PERFCOUNTER(vmx_mov_to_cr,        "vmx privop mov_to_cr")
PERFCOUNTER(vmx_bsw0,             "vmx privop bsw0")
PERFCOUNTER(vmx_bsw1,             "vmx privop bsw1")
PERFCOUNTER(vmx_cover,            "vmx privop cover")
PERFCOUNTER(vmx_rfi,              "vmx privop rfi")
PERFCOUNTER(vmx_itr_d,            "vmx privop itr_d")
PERFCOUNTER(vmx_itr_i,            "vmx privop itr_i")
PERFCOUNTER(vmx_ptr_d,            "vmx privop ptr_d")
PERFCOUNTER(vmx_ptr_i,            "vmx privop ptr_i")
PERFCOUNTER(vmx_itc_d,            "vmx privop itc_d")
PERFCOUNTER(vmx_itc_i,            "vmx privop itc_i")
PERFCOUNTER(vmx_ptc_l,            "vmx privop ptc_l")
PERFCOUNTER(vmx_ptc_g,            "vmx privop ptc_g")
PERFCOUNTER(vmx_ptc_ga,           "vmx privop ptc_ga")
PERFCOUNTER(vmx_ptc_e,            "vmx privop ptc_e")
PERFCOUNTER(vmx_mov_to_rr,        "vmx privop mov_to_rr")
PERFCOUNTER(vmx_mov_from_rr,      "vmx privop mov_from_rr")
PERFCOUNTER(vmx_thash,            "vmx privop thash")
PERFCOUNTER(vmx_ttag,             "vmx privop ttag")
PERFCOUNTER(vmx_tpa,              "vmx privop tpa")
PERFCOUNTER(vmx_tak,              "vmx privop tak")
PERFCOUNTER(vmx_mov_to_ar_imm,    "vmx privop mov_to_ar_imm")
PERFCOUNTER(vmx_mov_to_ar_reg,    "vmx privop mov_to_ar_reg")
PERFCOUNTER(vmx_mov_from_ar_reg,  "vmx privop mov_from_ar_reg")
PERFCOUNTER(vmx_mov_to_dbr,       "vmx privop mov_to_dbr")
PERFCOUNTER(vmx_mov_to_ibr,       "vmx privop mov_to_ibr")
PERFCOUNTER(vmx_mov_to_pmc,       "vmx privop mov_to_pmc")
PERFCOUNTER(vmx_mov_to_pmd,       "vmx privop mov_to_pmd")
PERFCOUNTER(vmx_mov_to_pkr,       "vmx privop mov_to_pkr")
PERFCOUNTER(vmx_mov_from_dbr,     "vmx privop mov_from_dbr")
PERFCOUNTER(vmx_mov_from_ibr,     "vmx privop mov_from_ibr")
PERFCOUNTER(vmx_mov_from_pmc,     "vmx privop mov_from_pmc")
PERFCOUNTER(vmx_mov_from_pkr,     "vmx privop mov_from_pkr")
PERFCOUNTER(vmx_mov_from_cpuid,   "vmx privop mov_from_cpuid")


PERFCOUNTER_ARRAY(slow_hyperprivop,   "slow hyperprivops", HYPERPRIVOP_MAX + 1)
PERFCOUNTER_ARRAY(fast_hyperprivop,   "fast hyperprivops", HYPERPRIVOP_MAX + 1)

PERFCOUNTER_ARRAY(slow_reflect,       "slow reflection", 0x80)
PERFCOUNTER_ARRAY(fast_reflect,       "fast reflection", 0x80)

PERFSTATUS(vhpt_nbr_entries,          "nbr of entries per VHPT")
PERFSTATUS(vhpt_valid_entries,        "nbr of valid entries in VHPT")

PERFCOUNTER_ARRAY(vmx_mmio_access,    "vmx_mmio_access", 8)
PERFCOUNTER(vmx_pal_emul,         "vmx_pal_emul")
PERFCOUNTER_ARRAY(vmx_switch_mm_mode, "vmx_switch_mm_mode", 8)
PERFCOUNTER(vmx_ia64_handle_break,"vmx_ia64_handle_break")
PERFCOUNTER_ARRAY(vmx_inject_guest_interruption,
                                      "vmx_inject_guest_interruption", 0x80)
PERFCOUNTER_ARRAY(fw_hypercall,       "fw_hypercall", 0x20)

#ifdef CONFIG_PRIVOP_ADDRS
#ifndef PERFPRIVOPADDR
#define PERFPRIVOPADDR(name) \
PERFSTATUS_ARRAY(privop_addr_##name##_addr, "privop-addrs addr " #name, \
                 PRIVOP_COUNT_NADDRS) \
PERFSTATUS_ARRAY(privop_addr_##name##_count, "privop-addrs count " #name, \
                 PRIVOP_COUNT_NADDRS) \
PERFSTATUS(privop_addr_##name##_overflow, "privop-addrs overflow " #name)
#endif

PERFPRIVOPADDR(get_ifa)
PERFPRIVOPADDR(thash)

#undef PERFPRIVOPADDR
#endif

// vhpt.c
PERFCOUNTER(local_vhpt_flush,               "local_vhpt_flush")
PERFCOUNTER(vcpu_vhpt_flush,                "vcpu_vhpt_flush")
PERFCOUNTER(vcpu_flush_vtlb_all,            "vcpu_flush_vtlb_all")
PERFCOUNTER(domain_flush_vtlb_all,          "domain_flush_vtlb_all")
PERFCOUNTER(vcpu_flush_tlb_vhpt_range,      "vcpu_flush_tlb_vhpt_range")
PERFCOUNTER(domain_flush_vtlb_track_entry,  "domain_flush_vtlb_track_entry")
PERFCOUNTER(domain_flush_vtlb_local,        "domain_flush_vtlb_local")
PERFCOUNTER(domain_flush_vtlb_global,       "domain_flush_vtlb_global")
PERFCOUNTER(domain_flush_vtlb_range,        "domain_flush_vtlb_range")

// domain.c
PERFCOUNTER(flush_vtlb_for_context_switch,  "flush_vtlb_for_context_switch")

// mm.c
PERFCOUNTER(assign_domain_page_replace,     "assign_domain_page_replace")
PERFCOUNTER(assign_domain_pge_cmpxchg_rel,  "assign_domain_pge_cmpxchg_rel")
PERFCOUNTER(zap_domain_page_one,            "zap_domain_page_one")
PERFCOUNTER(dom0vp_zap_physmap,             "dom0vp_zap_physmap")
PERFCOUNTER(dom0vp_add_physmap,             "dom0vp_add_physmap")
PERFCOUNTER(create_grant_host_mapping,      "create_grant_host_mapping")
PERFCOUNTER(replace_grant_host_mapping,     "replace_grant_host_mapping")
PERFCOUNTER(steal_page_refcount,            "steal_page_refcount")
PERFCOUNTER(steal_page,                     "steal_page")
PERFCOUNTER(guest_physmap_add_page,         "guest_physmap_add_page")
PERFCOUNTER(guest_physmap_remove_page,      "guest_physmap_remove_page")
PERFCOUNTER(domain_page_flush_and_put,      "domain_page_flush_and_put")

// dom0vp
PERFCOUNTER(dom0vp_phystomach,              "dom0vp_phystomach")
PERFCOUNTER(dom0vp_machtophys,              "dom0vp_machtophys")

#ifdef CONFIG_XEN_IA64_TLB_TRACK
// insert or dirty
PERFCOUNTER(tlb_track_iod,                  "tlb_track_iod")
PERFCOUNTER(tlb_track_iod_again,            "tlb_track_iod_again")
PERFCOUNTER(tlb_track_iod_not_tracked,      "tlb_track_iod_not_tracked")
PERFCOUNTER(tlb_track_iod_force_many,       "tlb_track_iod_force_many")
PERFCOUNTER(tlb_track_iod_tracked_many,     "tlb_track_iod_tracked_many")
PERFCOUNTER(tlb_track_iod_tracked_many_del, "tlb_track_iod_tracked_many_del")
PERFCOUNTER(tlb_track_iod_found,            "tlb_track_iod_found")
PERFCOUNTER(tlb_track_iod_new_entry,        "tlb_track_iod_new_entry")
PERFCOUNTER(tlb_track_iod_new_failed,       "tlb_track_iod_new_failed")
PERFCOUNTER(tlb_track_iod_new_many,         "tlb_track_iod_new_many")
PERFCOUNTER(tlb_track_iod_insert,           "tlb_track_iod_insert")
PERFCOUNTER(tlb_track_iod_dirtied,          "tlb_track_iod_dirtied")

// search and remove
PERFCOUNTER(tlb_track_sar,                  "tlb_track_sar")
PERFCOUNTER(tlb_track_sar_not_tracked,      "tlb_track_sar_not_tracked")
PERFCOUNTER(tlb_track_sar_not_found,        "tlb_track_sar_not_found")
PERFCOUNTER(tlb_track_sar_found,            "tlb_track_sar_found")
PERFCOUNTER(tlb_track_sar_many,             "tlb_track_sar_many")

// flush
PERFCOUNTER(tlb_track_use_rr7,              "tlb_track_use_rr7")
PERFCOUNTER(tlb_track_swap_rr0,             "tlb_track_swap_rr0")
#endif

// tlb flush clock
#ifdef CONFIG_XEN_IA64_TLBFLUSH_CLOCK
PERFCOUNTER(tlbflush_clock_cswitch_purge,  "tlbflush_clock_cswitch_purge")
PERFCOUNTER(tlbflush_clock_cswitch_skip,   "tlbflush_clock_cswitch_skip")
#endif

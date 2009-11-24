#ifndef __ASM_DOMAIN_H__
#define __ASM_DOMAIN_H__

#include <xen/config.h>
#include <xen/mm.h>
#include <asm/hvm/vcpu.h>
#include <asm/hvm/domain.h>
#include <asm/e820.h>
#include <public/vcpu.h>

#define has_32bit_shinfo(d)    ((d)->arch.has_32bit_shinfo)
#define is_pv_32bit_domain(d)  ((d)->arch.is_32bit_pv)
#define is_pv_32bit_vcpu(v)    (is_pv_32bit_domain((v)->domain))
#ifdef __x86_64__
#define is_pv_32on64_domain(d) (is_pv_32bit_domain(d))
#else
#define is_pv_32on64_domain(d) (0)
#endif
#define is_pv_32on64_vcpu(v)   (is_pv_32on64_domain((v)->domain))

struct trap_bounce {
    uint32_t      error_code;
    uint8_t       flags; /* TBF_ */
    uint16_t      cs;
    unsigned long eip;
};

#define MAPHASH_ENTRIES 8
#define MAPHASH_HASHFN(pfn) ((pfn) & (MAPHASH_ENTRIES-1))
#define MAPHASHENT_NOTINUSE ((u16)~0U)
struct mapcache_vcpu {
    /* Shadow of mapcache_domain.epoch. */
    unsigned int shadow_epoch;

    /* Lock-free per-VCPU hash of recently-used mappings. */
    struct vcpu_maphash_entry {
        unsigned long mfn;
        uint16_t      idx;
        uint16_t      refcnt;
    } hash[MAPHASH_ENTRIES];
};

#define MAPCACHE_ORDER   10
#define MAPCACHE_ENTRIES (1 << MAPCACHE_ORDER)
struct mapcache_domain {
    /* The PTEs that provide the mappings, and a cursor into the array. */
    l1_pgentry_t *l1tab;
    unsigned int cursor;

    /* Protects map_domain_page(). */
    spinlock_t lock;

    /* Garbage mappings are flushed from TLBs in batches called 'epochs'. */
    unsigned int epoch;
    u32 tlbflush_timestamp;

    /* Which mappings are in use, and which are garbage to reap next epoch? */
    unsigned long inuse[BITS_TO_LONGS(MAPCACHE_ENTRIES)];
    unsigned long garbage[BITS_TO_LONGS(MAPCACHE_ENTRIES)];
};

void mapcache_domain_init(struct domain *);
void mapcache_vcpu_init(struct vcpu *);

/* x86/64: toggle guest between kernel and user modes. */
void toggle_guest_mode(struct vcpu *);

/*
 * Initialise a hypercall-transfer page. The given pointer must be mapped
 * in Xen virtual address space (accesses are not validated or checked).
 */
void hypercall_page_initialise(struct domain *d, void *);

/************************************************/
/*          shadow paging extension             */
/************************************************/
struct shadow_domain {
    spinlock_t        lock;  /* shadow domain lock */
    int               locker; /* processor which holds the lock */
    const char       *locker_function; /* Func that took it */
    unsigned int      opt_flags;    /* runtime tunable optimizations on/off */
    struct page_list_head pinned_shadows;

    /* Memory allocation */
    struct page_list_head freelists[SHADOW_MAX_ORDER + 1];
    struct page_list_head p2m_freelist;
    unsigned int      total_pages;  /* number of pages allocated */
    unsigned int      free_pages;   /* number of pages on freelists */
    unsigned int      p2m_pages;    /* number of pages allocates to p2m */

    /* 1-to-1 map for use when HVM vcpus have paging disabled */
    pagetable_t unpaged_pagetable;

    /* Shadow hashtable */
    struct page_info **hash_table;
    int hash_walking;  /* Some function is walking the hash table */

    /* Fast MMIO path heuristic */
    int has_fast_mmio_entries;

    /* reflect guest table dirty status, incremented by write
     * emulation and remove write permission
     */
    atomic_t          gtable_dirty_version;

    /* OOS */
    int oos_active;
    int oos_off;
};

struct shadow_vcpu {
#if CONFIG_PAGING_LEVELS >= 3
    /* PAE guests: per-vcpu shadow top-level table */
    l3_pgentry_t l3table[4] __attribute__((__aligned__(32)));
    /* PAE guests: per-vcpu cache of the top-level *guest* entries */
    l3_pgentry_t gl3e[4] __attribute__((__aligned__(32)));
#endif
    /* Non-PAE guests: pointer to guest top-level pagetable */
    void *guest_vtable;
    /* Last MFN that we emulated a write to as unshadow heuristics. */
    unsigned long last_emulated_mfn_for_unshadow;
    /* MFN of the last shadow that we shot a writeable mapping in */
    unsigned long last_writeable_pte_smfn;
    /* Last frame number that we emulated a write to. */
    unsigned long last_emulated_frame;
    /* Last MFN that we emulated a write successfully */
    unsigned long last_emulated_mfn;

    /* Shadow out-of-sync: pages that this vcpu has let go out of sync */
    mfn_t oos[SHADOW_OOS_PAGES];
    mfn_t oos_snapshot[SHADOW_OOS_PAGES];
    struct oos_fixup {
        int next;
        mfn_t smfn[SHADOW_OOS_FIXUPS];
        unsigned long off[SHADOW_OOS_FIXUPS];
    } oos_fixup[SHADOW_OOS_PAGES];
};

/************************************************/
/*            hardware assisted paging          */
/************************************************/
struct hap_domain {
    spinlock_t        lock;
    int               locker;
    const char       *locker_function;

    struct page_list_head freelist;
    unsigned int      total_pages;  /* number of pages allocated */
    unsigned int      free_pages;   /* number of pages on freelists */
    unsigned int      p2m_pages;    /* number of pages allocates to p2m */
};

/************************************************/
/*       common paging data structure           */
/************************************************/
struct log_dirty_domain {
    /* log-dirty lock */
    spinlock_t     lock;
    int            locker; /* processor that holds the lock */
    const char    *locker_function; /* func that took it */

    /* log-dirty radix tree to record dirty pages */
    mfn_t          top;
    unsigned int   allocs;
    unsigned int   failed_allocs;

    /* log-dirty mode stats */
    unsigned int   fault_count;
    unsigned int   dirty_count;

    /* functions which are paging mode specific */
    int            (*enable_log_dirty   )(struct domain *d);
    int            (*disable_log_dirty  )(struct domain *d);
    void           (*clean_dirty_bitmap )(struct domain *d);
};

struct paging_domain {
    /* flags to control paging operation */
    u32                     mode;
    /* extension for shadow paging support */
    struct shadow_domain    shadow;
    /* extension for hardware-assited paging */
    struct hap_domain       hap;
    /* log dirty support */
    struct log_dirty_domain log_dirty;
};

struct paging_vcpu {
    /* Pointers to mode-specific entry points. */
    const struct paging_mode *mode;
    /* HVM guest: last emulate was to a pagetable */
    unsigned int last_write_was_pt:1;
    /* HVM guest: last write emulation succeeds */
    unsigned int last_write_emul_ok:1;
    /* Translated guest: virtual TLB */
    struct shadow_vtlb *vtlb;
    spinlock_t          vtlb_lock;

    /* paging support extension */
    struct shadow_vcpu shadow;
};

#define MAX_CPUID_INPUT 40
typedef xen_domctl_cpuid_t cpuid_input_t;

struct p2m_domain;

/* Define for GUEST MCA handling */
#define MAX_NR_BANKS 30

/* This entry is for recording bank nodes for the impacted domain,
 * put into impact_header list. */
struct bank_entry {
    struct list_head list;
    uint16_t bank;
    uint64_t mci_status;
    uint64_t mci_addr;
    uint64_t mci_misc;
};

struct domain_mca_msrs
{
    /* Guest should not change below values after DOM boot up */
    uint64_t mcg_cap;
    uint64_t mcg_ctl;
    uint64_t mcg_status;
    uint64_t mci_ctl[MAX_NR_BANKS];
    uint16_t nr_injection;
    struct list_head impact_header;
    spinlock_t lock;
};

struct arch_domain
{
#ifdef CONFIG_X86_64
    struct page_info **mm_perdomain_pt_pages;
    l2_pgentry_t *mm_perdomain_l2;
    l3_pgentry_t *mm_perdomain_l3;

    unsigned int hv_compat_vstart;
#else
    l1_pgentry_t *mm_perdomain_pt;

    /* map_domain_page() mapping cache. */
    struct mapcache_domain mapcache;
#endif

    bool_t s3_integrity;

    /* I/O-port admin-specified access capabilities. */
    struct rangeset *ioport_caps;
    uint32_t pci_cf8;

    struct list_head pdev_list;
    struct hvm_domain hvm_domain;

    struct paging_domain paging;
    struct p2m_domain *p2m;

    /* Shadow translated domain: P2M mapping */
    pagetable_t phys_table;

    /* NB. protected by d->event_lock and by irq_desc[irq].lock */
    int *irq_pirq;
    int *pirq_irq;

    /* Shared page for notifying that explicit PIRQ EOI is required. */
    unsigned long *pirq_eoi_map;
    unsigned long pirq_eoi_map_mfn;

    /* Pseudophysical e820 map (XENMEM_memory_map).  */
    struct e820entry e820[3];
    unsigned int nr_e820;

    /* Maximum physical-address bitwidth supported by this guest. */
    unsigned int physaddr_bitsize;

    /* Is a 32-bit PV (non-HVM) guest? */
    bool_t is_32bit_pv;
    /* Is shared-info page in 32-bit format? */
    bool_t has_32bit_shinfo;
    /* Domain cannot handle spurious page faults? */
    bool_t suppress_spurious_page_faults;

    /* Continuable domain_relinquish_resources(). */
    enum {
        RELMEM_not_started,
        RELMEM_xen,
        RELMEM_l4,
        RELMEM_l3,
        RELMEM_l2,
        RELMEM_done,
    } relmem;
    struct page_list_head relmem_list;

    cpuid_input_t cpuids[MAX_CPUID_INPUT];

    /* For Guest vMCA handling */
    struct domain_mca_msrs vmca_msrs;

    /* SoftTSC emulation */
    bool_t vtsc;
    s_time_t vtsc_last;
    spinlock_t vtsc_lock;
    uint64_t vtsc_kerncount; /* for hvm, counts all vtsc */
    uint64_t vtsc_usercount; /* not used for hvm */
} __cacheline_aligned;

#define has_arch_pdevs(d)    (!list_empty(&(d)->arch.pdev_list))

#ifdef CONFIG_X86_64
#define perdomain_pt_pgidx(v) \
      ((v)->vcpu_id >> (PAGETABLE_ORDER - GDT_LDT_VCPU_SHIFT))
#define perdomain_ptes(d, v) \
    ((l1_pgentry_t *)page_to_virt((d)->arch.mm_perdomain_pt_pages \
      [perdomain_pt_pgidx(v)]) + (((v)->vcpu_id << GDT_LDT_VCPU_SHIFT) & \
                                  (L1_PAGETABLE_ENTRIES - 1)))
#define perdomain_pt_page(d, n) ((d)->arch.mm_perdomain_pt_pages[n])
#else
#define perdomain_ptes(d, v) \
    ((d)->arch.mm_perdomain_pt + ((v)->vcpu_id << GDT_LDT_VCPU_SHIFT))
#define perdomain_pt_page(d, n) \
    (virt_to_page((d)->arch.mm_perdomain_pt) + (n))
#endif


#ifdef __i386__
struct pae_l3_cache {
    /*
     * Two low-memory (<4GB) PAE L3 tables, used as fallback when the guest
     * supplies a >=4GB PAE L3 table. We need two because we cannot set up
     * an L3 table while we are currently running on it (without using
     * expensive atomic 64-bit operations).
     */
    l3_pgentry_t  table[2][4] __attribute__((__aligned__(32)));
    unsigned long high_mfn;  /* The >=4GB MFN being shadowed. */
    unsigned int  inuse_idx; /* Which of the two cache slots is in use? */
    spinlock_t    lock;
};
#define pae_l3_cache_init(c) spin_lock_init(&(c)->lock)
#else /* !defined(__i386__) */
struct pae_l3_cache { };
#define pae_l3_cache_init(c) ((void)0)
#endif

struct arch_vcpu
{
    /* Needs 16-byte aligment for FXSAVE/FXRSTOR. */
    struct vcpu_guest_context guest_context
    __attribute__((__aligned__(16)));

    struct pae_l3_cache pae_l3_cache;

    unsigned long      flags; /* TF_ */

    void (*schedule_tail) (struct vcpu *);

    void (*ctxt_switch_from) (struct vcpu *);
    void (*ctxt_switch_to) (struct vcpu *);

    /* Record information required to continue execution after migration */
    void *continue_info;

    /* Bounce information for propagating an exception to guest OS. */
    struct trap_bounce trap_bounce;

    /* I/O-port access bitmap. */
    XEN_GUEST_HANDLE(uint8) iobmp; /* Guest kernel vaddr of the bitmap. */
    int iobmp_limit;  /* Number of ports represented in the bitmap.  */
    int iopl;         /* Current IOPL for this VCPU. */

#ifdef CONFIG_X86_32
    struct desc_struct int80_desc;
#endif
#ifdef CONFIG_X86_64
    struct trap_bounce int80_bounce;
    unsigned long      syscall32_callback_eip;
    unsigned long      sysenter_callback_eip;
    unsigned short     syscall32_callback_cs;
    unsigned short     sysenter_callback_cs;
    bool_t             syscall32_disables_events;
    bool_t             sysenter_disables_events;
#endif

    /* Virtual Machine Extensions */
    struct hvm_vcpu hvm_vcpu;

    /*
     * Every domain has a L1 pagetable of its own. Per-domain mappings
     * are put in this table (eg. the current GDT is mapped here).
     */
    l1_pgentry_t *perdomain_ptes;

#ifdef CONFIG_X86_64
    pagetable_t guest_table_user;       /* (MFN) x86/64 user-space pagetable */
#endif
    pagetable_t guest_table;            /* (MFN) guest notion of cr3 */
    /* guest_table holds a ref to the page, and also a type-count unless
     * shadow refcounts are in use */
    pagetable_t shadow_table[4];        /* (MFN) shadow(s) of guest */
    pagetable_t monitor_table;          /* (MFN) hypervisor PT (for HVM) */
    unsigned long cr3;                  /* (MA) value to install in HW CR3 */

    /* Current LDT details. */
    unsigned long shadow_ldt_mapcnt;
    spinlock_t shadow_ldt_lock;

    struct paging_vcpu paging;

    /* Guest-specified relocation of vcpu_info. */
    unsigned long vcpu_info_mfn;

#ifdef CONFIG_X86_32
    /* map_domain_page() mapping cache. */
    struct mapcache_vcpu mapcache;
#endif

#if XEN_GDBSX_CONFIG
    uint32_t gdbsx_vcpu_event;
#endif 

    /* A secondary copy of the vcpu time info. */
    XEN_GUEST_HANDLE(vcpu_time_info_t) time_info_guest;

} __cacheline_aligned;

/* Shorthands to improve code legibility. */
#define hvm_vmx         hvm_vcpu.u.vmx
#define hvm_svm         hvm_vcpu.u.svm

/* Continue the current hypercall via func(data) on specified cpu. */
int continue_hypercall_on_cpu(int cpu, long (*func)(void *data), void *data);

void vcpu_show_execution_state(struct vcpu *);
void vcpu_show_registers(const struct vcpu *);

/* Clean up CR4 bits that are not under guest control. */
unsigned long pv_guest_cr4_fixup(unsigned long guest_cr4);

/* Convert between guest-visible and real CR4 values. */
#define pv_guest_cr4_to_real_cr4(v)                         \
    (((v)->arch.guest_context.ctrlreg[4]                    \
      | (mmu_cr4_features & (X86_CR4_PGE | X86_CR4_PSE))    \
      | ((v)->domain->arch.vtsc ? X86_CR4_TSD : 0))         \
      & ~X86_CR4_DE)
#define real_cr4_to_pv_guest_cr4(c) \
    ((c) & ~(X86_CR4_PGE | X86_CR4_PSE | X86_CR4_TSD | X86_CR4_OSXSAVE))

void domain_cpuid(struct domain *d,
                  unsigned int  input,
                  unsigned int  sub_input,
                  unsigned int  *eax,
                  unsigned int  *ebx,
                  unsigned int  *ecx,
                  unsigned int  *edx);

int construct_dom0(
    struct domain *d,
    unsigned long image_base,
    unsigned long image_start, unsigned long image_len,
    unsigned long initrd_start, unsigned long initrd_len,
    char *cmdline);

extern unsigned long initial_images_nrpages(void);
extern void discard_initial_images(void);

#endif /* __ASM_DOMAIN_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

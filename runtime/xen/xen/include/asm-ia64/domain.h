#ifndef __ASM_DOMAIN_H__
#define __ASM_DOMAIN_H__

#include <linux/thread_info.h>
#include <asm/tlb.h>
#include <asm/vmx_vpd.h>
#include <asm/vmmu.h>
#include <asm/regionreg.h>
#include <public/xen.h>
#include <asm/vmx_platform.h>
#include <xen/list.h>
#include <xen/cpumask.h>
#include <xen/mm.h>
#include <asm/fpswa.h>
#include <xen/rangeset.h>

struct p2m_entry;
#ifdef CONFIG_XEN_IA64_TLB_TRACK
struct tlb_track;
#endif

extern unsigned long volatile jiffies;

struct vcpu;
extern void relinquish_vcpu_resources(struct vcpu *v);
extern int vcpu_late_initialise(struct vcpu *v);

/* given a current domain metaphysical address, return the physical address */
extern unsigned long translate_domain_mpaddr(unsigned long mpaddr,
                                             struct p2m_entry* entry);

/* Set shared_info virtual address.  */
extern unsigned long domain_set_shared_info_va (unsigned long va);

/* Flush cache of domain d.
   If sync_only is true, only synchronize I&D caches,
   if false, flush and invalidate caches.  */
extern void domain_cache_flush (struct domain *d, int sync_only);

/* Control the shadow mode.  */
extern int shadow_mode_control(struct domain *d, xen_domctl_shadow_op_t *sc);

/* Cleanly crash the current domain with a message.  */
extern void panic_domain(struct pt_regs *, const char *, ...)
     __attribute__ ((noreturn, format (printf, 2, 3)));

#define has_arch_pdevs(d)    (!list_empty(&(d)->arch.pdev_list))

struct mm_struct {
	volatile pgd_t * pgd;
    //	atomic_t mm_users;			/* How many users with user space? */
};

struct foreign_p2m {
    spinlock_t          lock;
    /*
     * sorted list with entry->gpfn.
     * It is expected that only small number of foreign domain p2m
     * mapping happens at the same time.
     */
    struct list_head    head;
};

struct last_vcpu {
#define INVALID_VCPU_ID INT_MAX
    int vcpu_id;
#ifdef CONFIG_XEN_IA64_TLBFLUSH_CLOCK
    u32 tlbflush_timestamp;
#endif
} ____cacheline_aligned_in_smp;

/* These are data in domain memory for SAL emulator.  */
struct xen_sal_data {
    /* OS boot rendez vous.  */
    unsigned long boot_rdv_ip;
    unsigned long boot_rdv_r1;

    /* There are these for EFI_SET_VIRTUAL_ADDRESS_MAP emulation. */
    int efi_virt_mode;		/* phys : 0 , virt : 1 */
};

/*
 * Optimization features are used by the hypervisor to do some optimizations
 * for guests.  By default the optimizations are switched off and the guest
 * may activate the feature. The guest may do this via the hypercall
 * __HYPERVISOR_opt_feature.  Domain builder code can also enable these
 * via XEN_DOMCTL_set_opt_feature.
 */

/*
 * Helper struct for the different identity mapping optimizations.
 * The hypervisor does the insertion of address translations in the tlb
 * for identity mapped areas without reflecting the page fault
 * to the guest.
 */
struct identity_mapping {
        unsigned long pgprot;	/* The page protection bit mask of the pte.*/
        unsigned long key;	/* A protection key. */
};

/* opt_feature mask */
/*
 * If this feature is switched on, the hypervisor inserts the
 * tlb entries without calling the guests traphandler.
 * This is useful in guests using region 7 for identity mapping
 * like the linux kernel does.
 */
#define XEN_IA64_OPTF_IDENT_MAP_REG7_FLG_BIT    0
#define XEN_IA64_OPTF_IDENT_MAP_REG7_FLG        \
	(1UL << XEN_IA64_OPTF_IDENT_MAP_REG7_FLG_BIT)

/* Identity mapping of region 4 addresses in HVM. */
#define XEN_IA64_OPTF_IDENT_MAP_REG4_FLG_BIT    \
        (XEN_IA64_OPTF_IDENT_MAP_REG7_FLG_BIT + 1)
#define XEN_IA64_OPTF_IDENT_MAP_REG4_FLG        \
        (1UL << XEN_IA64_OPTF_IDENT_MAP_REG4_FLG_BIT)

/* Identity mapping of region 5 addresses in HVM. */
#define XEN_IA64_OPTF_IDENT_MAP_REG5_FLG_BIT    \
        (XEN_IA64_OPTF_IDENT_MAP_REG7_FLG_BIT + 2)
#define XEN_IA64_OPTF_IDENT_MAP_REG5_FLG        \
        (1UL << XEN_IA64_OPTF_IDENT_MAP_REG5_FLG_BIT)

/* Central structure for optimzation features used by the hypervisor.  */
struct opt_feature {
    unsigned long mask;			/* For every feature one bit. */
    struct identity_mapping im_reg4;	/* Region 4 identity mapping */
    struct identity_mapping im_reg5;	/* Region 5 identity mapping */
    struct identity_mapping im_reg7;	/* Region 7 identity mapping */
};

/* Set an optimization feature in the struct arch_domain. */
extern int domain_opt_feature(struct domain *, struct xen_ia64_opt_feature*);

struct arch_domain {
    struct mm_struct mm;

    /* Flags.  */
    union {
        unsigned long flags;
        struct {
            unsigned int is_sioemu : 1;
#ifdef CONFIG_XEN_IA64_PERVCPU_VHPT
            unsigned int has_pervcpu_vhpt : 1;
            unsigned int vhpt_size_log2 : 6;
#endif
        };
    };

    /* maximum metaphysical address of conventional memory */
    u64 convmem_end;

    /* Allowed accesses to io ports.  */
    struct rangeset *ioport_caps;

    /* There are two ranges of RID for a domain:
       one big range, used to virtualize domain RID,
       one small range for internal Xen use (metaphysical).  */
    /* Big range.  */
    unsigned int starting_rid;	/* first RID assigned to domain */
    unsigned int ending_rid;	/* one beyond highest RID assigned to domain */
    /* Metaphysical range.  */
    unsigned int starting_mp_rid;
    unsigned int ending_mp_rid;
    /* RID for metaphysical mode.  */
    unsigned int metaphysical_rid_dt;	/* dt=it=0  */
    unsigned int metaphysical_rid_d;    /* dt=0, it=1  */
    
    unsigned char rid_bits;		/* number of virtual rid bits (default: 18) */
    int breakimm;               /* The imm value for hypercalls.  */

    struct list_head pdev_list;
    struct virtual_platform_def     vmx_platform;
#define	hvm_domain vmx_platform /* platform defs are not vmx specific */

    u64 shared_info_va;
 
    /* Address of SAL emulator data  */
    struct xen_sal_data *sal_data;

    /* Shared page for notifying that explicit PIRQ EOI is required. */
    unsigned long *pirq_eoi_map;
    unsigned long pirq_eoi_map_mfn;

    /* Address of efi_runtime_services_t (placed in domain memory)  */
    void *efi_runtime;
    /* Address of fpswa_interface_t (placed in domain memory)  */
    void *fpswa_inf;

    /* Bitmap of shadow dirty bits.
       Set iff shadow mode is enabled.  */
    u64 *shadow_bitmap;
    /* Length (in bits!) of shadow bitmap.  */
    unsigned long shadow_bitmap_size;
    /* Number of bits set in bitmap.  */
    atomic64_t shadow_dirty_count;
    /* Number of faults.  */
    atomic64_t shadow_fault_count;

    /* for foreign domain p2m table mapping */
    struct foreign_p2m foreign_p2m;

    struct last_vcpu last_vcpu[NR_CPUS];

    struct opt_feature opt_feature;

    /* Debugging flags.  See arch-ia64.h for bits definition.  */
    unsigned int debug_flags;

    /* Reason of debugging break.  */
    unsigned int debug_event;

#ifdef CONFIG_XEN_IA64_TLB_TRACK
    struct tlb_track*   tlb_track;
#endif

    /* for domctl_destroy_domain continuation */
    enum {
        RELRES_not_started,
        RELRES_mm_teardown,
        RELRES_xen,
        RELRES_dom,
        RELRES_done,
    } relres;
    /* Continuable mm_teardown() */
    unsigned long mm_teardown_offset;
    /* Continuable domain_relinquish_resources() */
    struct page_list_head relmem_list;
};
#define INT_ENABLE_OFFSET(v) 		  \
    (sizeof(vcpu_info_t) * (v)->vcpu_id + \
    offsetof(vcpu_info_t, evtchn_upcall_mask))

#ifdef CONFIG_XEN_IA64_PERVCPU_VHPT
#define HAS_PERVCPU_VHPT(d)     ((d)->arch.has_pervcpu_vhpt)
#else
#define HAS_PERVCPU_VHPT(d)     (0)
#endif


struct arch_vcpu {
    /* Save the state of vcpu.
       This is the first entry to speed up accesses.  */
    mapped_regs_t *privregs;

    /* TR and TC.  */
    TR_ENTRY itrs[NITRS];
    TR_ENTRY dtrs[NDTRS];
    TR_ENTRY itlb;
    TR_ENTRY dtlb;

    /* Bit is set if there is a tr/tc for the region.  */
    unsigned char itr_regions;
    unsigned char dtr_regions;
    unsigned char tc_regions;

    unsigned long irr[4];	    /* Interrupt request register.  */
    unsigned long insvc[4];		/* Interrupt in service.  */
    unsigned long iva;
    unsigned long domain_itm;
    unsigned long domain_itm_last;

    unsigned long event_callback_ip;		// event callback handler
    unsigned long failsafe_callback_ip; 	// Do we need it?

    /* These fields are copied from arch_domain to make access easier/faster
       in assembly code.  */
    unsigned long metaphysical_rid_dt;	// from arch_domain (so is pinned)
    unsigned long metaphysical_rid_d;	// from arch_domain (so is pinned)
    unsigned long metaphysical_saved_rr0;	// from arch_domain (so is pinned)
    unsigned long metaphysical_saved_rr4;	// from arch_domain (so is pinned)
    unsigned long fp_psr;       // used for lazy float register
    u64 *shadow_bitmap;         // from arch_domain (so is pinned)
    int breakimm;			// from arch_domain (so is pinned)
    int starting_rid;		/* first RID assigned to domain */
    int ending_rid;		/* one beyond highest RID assigned to domain */
    unsigned char rid_bits;     // from arch_domain (so is pinned)

    /* Bitset for debug register use.  */
    unsigned int dbg_used;
    u64 dbr[IA64_NUM_DBG_REGS];
    u64 ibr[IA64_NUM_DBG_REGS];

    struct thread_struct _thread;	// this must be last

    thash_cb_t vtlb;
    thash_cb_t vhpt;
    char irq_new_pending;
    char irq_new_condition;    // vpsr.i/vtpr change, check for pending VHPI
    char hypercall_continuation;

    fpswa_ret_t fpswa_ret;     /* save return values of FPSWA emulation */
    struct timer hlt_timer;
    struct arch_vmx_struct arch_vmx; /* Virtual Machine Extensions */

    /* This vector hosts the protection keys for pkr emulation of PV domains.
     * Currently only 15 registers are usable by domU's. pkr[15] is
     * reserved for the hypervisor. */
    unsigned long pkrs[XEN_IA64_NPKRS+1];	/* protection key registers */
#define XEN_IA64_PKR_IN_USE	0x1		/* If psr.pk = 1 was set. */
    unsigned char pkr_flags;

    unsigned char       vhpt_pg_shift;		/* PAGE_SHIFT or less */
#ifdef CONFIG_XEN_IA64_PERVCPU_VHPT
    PTA                 pta;
    unsigned long       vhpt_maddr;
    struct page_info*   vhpt_page;
    unsigned long       vhpt_entries;
#endif
#define INVALID_PROCESSOR       INT_MAX
    int last_processor;
    cpumask_t cache_coherent_map;
};

#include <asm/uaccess.h> /* for KERNEL_DS */
#include <asm/pgtable.h>

int
do_perfmon_op(unsigned long cmd,
              XEN_GUEST_HANDLE(void) arg1, unsigned long arg2);

void
ia64_fault(unsigned long vector, unsigned long isr, unsigned long ifa,
           unsigned long iim, unsigned long itir, unsigned long arg5,
           unsigned long arg6, unsigned long arg7, unsigned long stack);

void
ia64_lazy_load_fpu(struct vcpu *vcpu);

int construct_dom0(
    struct domain *d,
    unsigned long image_start, unsigned long image_len,
    unsigned long initrd_start, unsigned long initrd_len,
    char *cmdline);

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

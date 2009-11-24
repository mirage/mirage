#ifndef ASM_VHPT_H
#define ASM_VHPT_H

/* Size of the VHPT.  */
// XXX work around to avoid trigerring xenLinux software lock up detection.
# define	VHPT_SIZE_LOG2			16	// 64KB

/* Number of entries in the VHPT.  The size of an entry is 4*8B == 32B */
#define	VHPT_NUM_ENTRIES		(1 << (VHPT_SIZE_LOG2 - 5))

// FIXME: These should be automatically generated
#define	VLE_PGFLAGS_OFFSET		0
#define	VLE_ITIR_OFFSET			8
#define	VLE_TITAG_OFFSET		16
#define	VLE_CCHAIN_OFFSET		24

#ifndef __ASSEMBLY__
#include <xen/percpu.h>
#include <asm/vcpumask.h>

extern void domain_purge_swtc_entries(struct domain *d);
extern void domain_purge_swtc_entries_vcpu_dirty_mask(struct domain* d, vcpumask_t vcpu_dirty_mask);

//
// VHPT Long Format Entry (as recognized by hw)
//
struct vhpt_lf_entry {
    unsigned long page_flags;
    unsigned long itir;
    unsigned long ti_tag;
    unsigned long CChain;
};

#define INVALID_TI_TAG 0x8000000000000000L

extern void vhpt_init (void);
extern void gather_vhpt_stats(void);
extern void vhpt_multiple_insert(unsigned long vaddr, unsigned long pte,
				 unsigned long itir);
extern void vhpt_insert (unsigned long vadr, unsigned long pte,
			 unsigned long itir);
void local_vhpt_flush(void);
extern void vcpu_vhpt_flush(struct vcpu* v);

/* Currently the VHPT is allocated per CPU.  */
DECLARE_PER_CPU (unsigned long, vhpt_paddr);
DECLARE_PER_CPU (unsigned long, vhpt_pend);

#ifdef CONFIG_XEN_IA64_PERVCPU_VHPT
#if !VHPT_ENABLED
#error "VHPT_ENABLED must be set for CONFIG_XEN_IA64_PERVCPU_VHPT"
#endif
#endif

#include <xen/sched.h>
#ifdef CONFIG_XEN_IA64_PERVCPU_VHPT
void domain_set_vhpt_size(struct domain *d, int8_t vhpt_size_log2);
int pervcpu_vhpt_alloc(struct vcpu *v);
void pervcpu_vhpt_free(struct vcpu *v);
#else
#define domain_set_vhpt_size(d, vhpt_size_log2) do { } while (0)
#define pervcpu_vhpt_alloc(v)                   (0)
#define pervcpu_vhpt_free(v)                    do { } while (0)
#endif

static inline unsigned long
vcpu_vhpt_maddr(struct vcpu* v)
{
#ifdef CONFIG_XEN_IA64_PERVCPU_VHPT
    if (HAS_PERVCPU_VHPT(v->domain))
        return v->arch.vhpt_maddr;
#endif

#if 0
    // referencecing v->processor is racy.
    return per_cpu(vhpt_paddr, v->processor);
#endif
    BUG_ON(v != current);
    return __get_cpu_var(vhpt_paddr);
}

static inline unsigned long
vcpu_pta(struct vcpu* v)
{
#ifdef CONFIG_XEN_IA64_PERVCPU_VHPT
    if (HAS_PERVCPU_VHPT(v->domain))
        return v->arch.pta.val;
#endif
    return __va_ul(__get_cpu_var(vhpt_paddr)) | (1 << 8) |
        (VHPT_SIZE_LOG2 << 2) | VHPT_ENABLED;
}

static inline int
canonicalize_vhpt_size(int sz)
{
    /* minimum 32KB */
    if (sz < 15)
        return 15;
    /* maximum 8MB (since purging TR is hard coded) */
    if (sz > IA64_GRANULE_SHIFT - 1)
        return IA64_GRANULE_SHIFT - 1;
    return sz;
}


#endif /* !__ASSEMBLY */
#endif

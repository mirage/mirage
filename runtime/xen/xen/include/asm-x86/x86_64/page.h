
#ifndef __X86_64_PAGE_H__
#define __X86_64_PAGE_H__

#define L1_PAGETABLE_SHIFT      12
#define L2_PAGETABLE_SHIFT      21
#define L3_PAGETABLE_SHIFT      30
#define L4_PAGETABLE_SHIFT      39
#define PAGE_SHIFT              L1_PAGETABLE_SHIFT
#define ROOT_PAGETABLE_SHIFT    L4_PAGETABLE_SHIFT

#define PAGETABLE_ORDER         9
#define L1_PAGETABLE_ENTRIES    (1<<PAGETABLE_ORDER)
#define L2_PAGETABLE_ENTRIES    (1<<PAGETABLE_ORDER)
#define L3_PAGETABLE_ENTRIES    (1<<PAGETABLE_ORDER)
#define L4_PAGETABLE_ENTRIES    (1<<PAGETABLE_ORDER)
#define ROOT_PAGETABLE_ENTRIES  L4_PAGETABLE_ENTRIES

#define __PAGE_OFFSET           DIRECTMAP_VIRT_START
#define __XEN_VIRT_START        XEN_VIRT_START

/* These are architectural limits. Current CPUs support only 40-bit phys. */
#define PADDR_BITS              52
#define VADDR_BITS              48
#define PADDR_MASK              ((1UL << PADDR_BITS)-1)
#define VADDR_MASK              ((1UL << VADDR_BITS)-1)

#define is_canonical_address(x) (((long)(x) >> 47) == ((long)(x) >> 63))

#ifndef __ASSEMBLY__

#include <xen/config.h>
#include <asm/types.h>

extern unsigned long max_pdx;
extern unsigned long pfn_pdx_bottom_mask, ma_va_bottom_mask;
extern unsigned int pfn_pdx_hole_shift;
extern unsigned long pfn_hole_mask;
extern unsigned long pfn_top_mask, ma_top_mask;
extern void pfn_pdx_hole_setup(unsigned long);

#define page_to_pdx(pg)  ((pg) - frame_table)
#define pdx_to_page(pdx) (frame_table + (pdx))
/*
 * Note: These are solely for the use by page_{get,set}_owner(), and
 *       therefore don't need to handle the XEN_VIRT_{START,END} range.
 */
#define virt_to_pdx(va)  (((unsigned long)(va) - DIRECTMAP_VIRT_START) >> \
                          PAGE_SHIFT)
#define pdx_to_virt(pdx) ((void *)(DIRECTMAP_VIRT_START + \
                                   ((unsigned long)(pdx) << PAGE_SHIFT)))

extern int __mfn_valid(unsigned long mfn);

static inline unsigned long pfn_to_pdx(unsigned long pfn)
{
    return (pfn & pfn_pdx_bottom_mask) |
           ((pfn & pfn_top_mask) >> pfn_pdx_hole_shift);
}

static inline unsigned long pdx_to_pfn(unsigned long pdx)
{
    return (pdx & pfn_pdx_bottom_mask) |
           ((pdx << pfn_pdx_hole_shift) & pfn_top_mask);
}

static inline unsigned long __virt_to_maddr(unsigned long va)
{
    ASSERT(va >= XEN_VIRT_START);
    ASSERT(va < DIRECTMAP_VIRT_END);
    if ( va >= DIRECTMAP_VIRT_START )
        va -= DIRECTMAP_VIRT_START;
    else
    {
        ASSERT(va < XEN_VIRT_END);
        va += xen_phys_start - XEN_VIRT_START;
    }
    return (va & ma_va_bottom_mask) |
           ((va << pfn_pdx_hole_shift) & ma_top_mask);
}

static inline void *__maddr_to_virt(unsigned long ma)
{
    ASSERT(ma < DIRECTMAP_VIRT_END - DIRECTMAP_VIRT_START);
    return (void *)(DIRECTMAP_VIRT_START +
                    ((ma & ma_va_bottom_mask) |
                     ((ma & ma_top_mask) >> pfn_pdx_hole_shift)));
}

/* read access (should only be used for debug printk's) */
typedef u64 intpte_t;
#define PRIpte "016lx"

typedef struct { intpte_t l1; } l1_pgentry_t;
typedef struct { intpte_t l2; } l2_pgentry_t;
typedef struct { intpte_t l3; } l3_pgentry_t;
typedef struct { intpte_t l4; } l4_pgentry_t;
typedef l4_pgentry_t root_pgentry_t;

#endif /* !__ASSEMBLY__ */

#define pte_read_atomic(ptep)       (*(ptep))
#define pte_write_atomic(ptep, pte) (*(ptep) = (pte))
#define pte_write(ptep, pte)        (*(ptep) = (pte))

/* Given a virtual address, get an entry offset into a linear page table. */
#define l1_linear_offset(_a) (((_a) & VADDR_MASK) >> L1_PAGETABLE_SHIFT)
#define l2_linear_offset(_a) (((_a) & VADDR_MASK) >> L2_PAGETABLE_SHIFT)
#define l3_linear_offset(_a) (((_a) & VADDR_MASK) >> L3_PAGETABLE_SHIFT)
#define l4_linear_offset(_a) (((_a) & VADDR_MASK) >> L4_PAGETABLE_SHIFT)

#define is_guest_l1_slot(_s) (1)
#define is_guest_l2_slot(_d, _t, _s)                   \
    ( !is_pv_32bit_domain(_d) ||                       \
      !((_t) & PGT_pae_xen_l2) ||                      \
      ((_s) < COMPAT_L2_PAGETABLE_FIRST_XEN_SLOT(_d)) )
#define is_guest_l3_slot(_s) (1)
#define is_guest_l4_slot(_d, _s)                    \
    ( is_pv_32bit_domain(_d)                        \
      ? ((_s) == 0)                                 \
      : (((_s) < ROOT_PAGETABLE_FIRST_XEN_SLOT) ||  \
         ((_s) > ROOT_PAGETABLE_LAST_XEN_SLOT)))

#define root_get_pfn              l4e_get_pfn
#define root_get_flags            l4e_get_flags
#define root_get_intpte           l4e_get_intpte
#define root_empty                l4e_empty
#define root_from_paddr           l4e_from_paddr
#define PGT_root_page_table       PGT_l4_page_table

/*
 * PTE pfn and flags:
 *  40-bit pfn   = (pte[51:12])
 *  24-bit flags = (pte[63:52],pte[11:0])
 */

/* Extract flags into 24-bit integer, or turn 24-bit flags into a pte mask. */
#define get_pte_flags(x) (((int)((x) >> 40) & ~0xFFF) | ((int)(x) & 0xFFF))
#define put_pte_flags(x) (((intpte_t)((x) & ~0xFFF) << 40) | ((x) & 0xFFF))

/* Bit 23 of a 24-bit flag mask. This corresponds to bit 63 of a pte.*/
#define _PAGE_NX_BIT (1U<<23)
#define _PAGE_NX     (cpu_has_nx ? _PAGE_NX_BIT : 0U)

/* Bit 22 of a 24-bit flag mask. This corresponds to bit 62 of a pte.*/
#define _PAGE_GNTTAB (1U<<22)

/*
 * Disallow unused flag bits plus PAT/PSE, PCD, PWT and GLOBAL.
 * Permit the NX bit if the hardware supports it.
 * Note that range [62:52] is available for software use on x86/64.
 */
#define BASE_DISALLOW_MASK (0xFF800198U & ~_PAGE_NX)

#define L1_DISALLOW_MASK (BASE_DISALLOW_MASK | _PAGE_GNTTAB)
#define L2_DISALLOW_MASK (BASE_DISALLOW_MASK & ~_PAGE_PSE)
#define L3_DISALLOW_MASK (BASE_DISALLOW_MASK)
#define L4_DISALLOW_MASK (BASE_DISALLOW_MASK)

#define COMPAT_L3_DISALLOW_MASK 0xFFFFF198U

#define PAGE_HYPERVISOR         (__PAGE_HYPERVISOR         | _PAGE_GLOBAL)
#define PAGE_HYPERVISOR_NOCACHE (__PAGE_HYPERVISOR_NOCACHE | _PAGE_GLOBAL)

#define USER_MAPPINGS_ARE_GLOBAL
#ifdef USER_MAPPINGS_ARE_GLOBAL
/*
 * Bit 12 of a 24-bit flag mask. This corresponds to bit 52 of a pte.
 * This is needed to distinguish between user and kernel PTEs since _PAGE_USER
 * is asserted for both.
 */
#define _PAGE_GUEST_KERNEL (1U<<12)
/* Global bit is allowed to be set on L1 PTEs. Intended for user mappings. */
#undef L1_DISALLOW_MASK
#define L1_DISALLOW_MASK ((BASE_DISALLOW_MASK | _PAGE_GNTTAB) & ~_PAGE_GLOBAL)
#else
#define _PAGE_GUEST_KERNEL 0
#endif

#endif /* __X86_64_PAGE_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

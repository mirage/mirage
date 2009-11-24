#ifndef __X86_PAGE_H__
#define __X86_PAGE_H__

/*
 * It is important that the masks are signed quantities. This ensures that
 * the compiler sign-extends a 32-bit mask to 64 bits if that is required.
 */
#ifndef __ASSEMBLY__
#define PAGE_SIZE           (1L << PAGE_SHIFT)
#else
#define PAGE_SIZE           (1 << PAGE_SHIFT)
#endif
#define PAGE_MASK           (~(PAGE_SIZE-1))
#define PAGE_FLAG_MASK      (~0)

#ifndef __ASSEMBLY__
# include <asm/types.h>
# include <xen/lib.h>
#endif

#if defined(__i386__)
# include <asm/x86_32/page.h>
#elif defined(__x86_64__)
# include <asm/x86_64/page.h>
#endif

/* Read a pte atomically from memory. */
#define l1e_read_atomic(l1ep) \
    l1e_from_intpte(pte_read_atomic(&l1e_get_intpte(*(l1ep))))
#define l2e_read_atomic(l2ep) \
    l2e_from_intpte(pte_read_atomic(&l2e_get_intpte(*(l2ep))))
#define l3e_read_atomic(l3ep) \
    l3e_from_intpte(pte_read_atomic(&l3e_get_intpte(*(l3ep))))
#define l4e_read_atomic(l4ep) \
    l4e_from_intpte(pte_read_atomic(&l4e_get_intpte(*(l4ep))))

/* Write a pte atomically to memory. */
#define l1e_write_atomic(l1ep, l1e) \
    pte_write_atomic(&l1e_get_intpte(*(l1ep)), l1e_get_intpte(l1e))
#define l2e_write_atomic(l2ep, l2e) \
    pte_write_atomic(&l2e_get_intpte(*(l2ep)), l2e_get_intpte(l2e))
#define l3e_write_atomic(l3ep, l3e) \
    pte_write_atomic(&l3e_get_intpte(*(l3ep)), l3e_get_intpte(l3e))
#define l4e_write_atomic(l4ep, l4e) \
    pte_write_atomic(&l4e_get_intpte(*(l4ep)), l4e_get_intpte(l4e))

/*
 * Write a pte safely but non-atomically to memory.
 * The PTE may become temporarily not-present during the update.
 */
#define l1e_write(l1ep, l1e) \
    pte_write(&l1e_get_intpte(*(l1ep)), l1e_get_intpte(l1e))
#define l2e_write(l2ep, l2e) \
    pte_write(&l2e_get_intpte(*(l2ep)), l2e_get_intpte(l2e))
#define l3e_write(l3ep, l3e) \
    pte_write(&l3e_get_intpte(*(l3ep)), l3e_get_intpte(l3e))
#define l4e_write(l4ep, l4e) \
    pte_write(&l4e_get_intpte(*(l4ep)), l4e_get_intpte(l4e))

/* Get direct integer representation of a pte's contents (intpte_t). */
#define l1e_get_intpte(x)          ((x).l1)
#define l2e_get_intpte(x)          ((x).l2)
#define l3e_get_intpte(x)          ((x).l3)
#define l4e_get_intpte(x)          ((x).l4)

/* Get pfn mapped by pte (unsigned long). */
#define l1e_get_pfn(x)             \
    ((unsigned long)(((x).l1 & (PADDR_MASK&PAGE_MASK)) >> PAGE_SHIFT))
#define l2e_get_pfn(x)             \
    ((unsigned long)(((x).l2 & (PADDR_MASK&PAGE_MASK)) >> PAGE_SHIFT))
#define l3e_get_pfn(x)             \
    ((unsigned long)(((x).l3 & (PADDR_MASK&PAGE_MASK)) >> PAGE_SHIFT))
#define l4e_get_pfn(x)             \
    ((unsigned long)(((x).l4 & (PADDR_MASK&PAGE_MASK)) >> PAGE_SHIFT))

/* Get physical address of page mapped by pte (paddr_t). */
#define l1e_get_paddr(x)           \
    ((paddr_t)(((x).l1 & (PADDR_MASK&PAGE_MASK))))
#define l2e_get_paddr(x)           \
    ((paddr_t)(((x).l2 & (PADDR_MASK&PAGE_MASK))))
#define l3e_get_paddr(x)           \
    ((paddr_t)(((x).l3 & (PADDR_MASK&PAGE_MASK))))
#define l4e_get_paddr(x)           \
    ((paddr_t)(((x).l4 & (PADDR_MASK&PAGE_MASK))))

/* Get pointer to info structure of page mapped by pte (struct page_info *). */
#define l1e_get_page(x)           (mfn_to_page(l1e_get_pfn(x)))
#define l2e_get_page(x)           (mfn_to_page(l2e_get_pfn(x)))
#define l3e_get_page(x)           (mfn_to_page(l3e_get_pfn(x)))
#define l4e_get_page(x)           (mfn_to_page(l4e_get_pfn(x)))

/* Get pte access flags (unsigned int). */
#define l1e_get_flags(x)           (get_pte_flags((x).l1))
#define l2e_get_flags(x)           (get_pte_flags((x).l2))
#define l3e_get_flags(x)           (get_pte_flags((x).l3))
#define l4e_get_flags(x)           (get_pte_flags((x).l4))

/* Construct an empty pte. */
#define l1e_empty()                ((l1_pgentry_t) { 0 })
#define l2e_empty()                ((l2_pgentry_t) { 0 })
#define l3e_empty()                ((l3_pgentry_t) { 0 })
#define l4e_empty()                ((l4_pgentry_t) { 0 })

/* Construct a pte from a pfn and access flags. */
#define l1e_from_pfn(pfn, flags)   \
    ((l1_pgentry_t) { ((intpte_t)(pfn) << PAGE_SHIFT) | put_pte_flags(flags) })
#define l2e_from_pfn(pfn, flags)   \
    ((l2_pgentry_t) { ((intpte_t)(pfn) << PAGE_SHIFT) | put_pte_flags(flags) })
#define l3e_from_pfn(pfn, flags)   \
    ((l3_pgentry_t) { ((intpte_t)(pfn) << PAGE_SHIFT) | put_pte_flags(flags) })
#define l4e_from_pfn(pfn, flags)   \
    ((l4_pgentry_t) { ((intpte_t)(pfn) << PAGE_SHIFT) | put_pte_flags(flags) })

/* Construct a pte from a physical address and access flags. */
#ifndef __ASSEMBLY__
static inline l1_pgentry_t l1e_from_paddr(paddr_t pa, unsigned int flags)
{
    ASSERT((pa & ~(PADDR_MASK & PAGE_MASK)) == 0);
    return (l1_pgentry_t) { pa | put_pte_flags(flags) };
}
static inline l2_pgentry_t l2e_from_paddr(paddr_t pa, unsigned int flags)
{
    ASSERT((pa & ~(PADDR_MASK & PAGE_MASK)) == 0);
    return (l2_pgentry_t) { pa | put_pte_flags(flags) };
}
static inline l3_pgentry_t l3e_from_paddr(paddr_t pa, unsigned int flags)
{
    ASSERT((pa & ~(PADDR_MASK & PAGE_MASK)) == 0);
    return (l3_pgentry_t) { pa | put_pte_flags(flags) };
}
#if CONFIG_PAGING_LEVELS >= 4
static inline l4_pgentry_t l4e_from_paddr(paddr_t pa, unsigned int flags)
{
    ASSERT((pa & ~(PADDR_MASK & PAGE_MASK)) == 0);
    return (l4_pgentry_t) { pa | put_pte_flags(flags) };
}
#endif
#endif /* !__ASSEMBLY__ */

/* Construct a pte from its direct integer representation. */
#define l1e_from_intpte(intpte)    ((l1_pgentry_t) { (intpte_t)(intpte) })
#define l2e_from_intpte(intpte)    ((l2_pgentry_t) { (intpte_t)(intpte) })
#define l3e_from_intpte(intpte)    ((l3_pgentry_t) { (intpte_t)(intpte) })
#define l4e_from_intpte(intpte)    ((l4_pgentry_t) { (intpte_t)(intpte) })

/* Construct a pte from a page pointer and access flags. */
#define l1e_from_page(page, flags) (l1e_from_pfn(page_to_mfn(page),(flags)))
#define l2e_from_page(page, flags) (l2e_from_pfn(page_to_mfn(page),(flags)))
#define l3e_from_page(page, flags) (l3e_from_pfn(page_to_mfn(page),(flags)))
#define l4e_from_page(page, flags) (l4e_from_pfn(page_to_mfn(page),(flags)))

/* Add extra flags to an existing pte. */
#define l1e_add_flags(x, flags)    ((x).l1 |= put_pte_flags(flags))
#define l2e_add_flags(x, flags)    ((x).l2 |= put_pte_flags(flags))
#define l3e_add_flags(x, flags)    ((x).l3 |= put_pte_flags(flags))
#define l4e_add_flags(x, flags)    ((x).l4 |= put_pte_flags(flags))

/* Remove flags from an existing pte. */
#define l1e_remove_flags(x, flags) ((x).l1 &= ~put_pte_flags(flags))
#define l2e_remove_flags(x, flags) ((x).l2 &= ~put_pte_flags(flags))
#define l3e_remove_flags(x, flags) ((x).l3 &= ~put_pte_flags(flags))
#define l4e_remove_flags(x, flags) ((x).l4 &= ~put_pte_flags(flags))

/* Check if a pte's page mapping or significant access flags have changed. */
#define l1e_has_changed(x,y,flags) \
    ( !!(((x).l1 ^ (y).l1) & ((PADDR_MASK&PAGE_MASK)|put_pte_flags(flags))) )
#define l2e_has_changed(x,y,flags) \
    ( !!(((x).l2 ^ (y).l2) & ((PADDR_MASK&PAGE_MASK)|put_pte_flags(flags))) )
#define l3e_has_changed(x,y,flags) \
    ( !!(((x).l3 ^ (y).l3) & ((PADDR_MASK&PAGE_MASK)|put_pte_flags(flags))) )
#define l4e_has_changed(x,y,flags) \
    ( !!(((x).l4 ^ (y).l4) & ((PADDR_MASK&PAGE_MASK)|put_pte_flags(flags))) )

/* Pagetable walking. */
#define l2e_to_l1e(x)              ((l1_pgentry_t *)__va(l2e_get_paddr(x)))
#define l3e_to_l2e(x)              ((l2_pgentry_t *)__va(l3e_get_paddr(x)))
#define l4e_to_l3e(x)              ((l3_pgentry_t *)__va(l4e_get_paddr(x)))

/* Given a virtual address, get an entry offset into a page table. */
#define l1_table_offset(a)         \
    (((a) >> L1_PAGETABLE_SHIFT) & (L1_PAGETABLE_ENTRIES - 1))
#define l2_table_offset(a)         \
    (((a) >> L2_PAGETABLE_SHIFT) & (L2_PAGETABLE_ENTRIES - 1))
#define l3_table_offset(a)         \
    (((a) >> L3_PAGETABLE_SHIFT) & (L3_PAGETABLE_ENTRIES - 1))
#define l4_table_offset(a)         \
    (((a) >> L4_PAGETABLE_SHIFT) & (L4_PAGETABLE_ENTRIES - 1))

/* Convert a pointer to a page-table entry into pagetable slot index. */
#define pgentry_ptr_to_slot(_p)    \
    (((unsigned long)(_p) & ~PAGE_MASK) / sizeof(*(_p)))

#ifndef __ASSEMBLY__

/* Page-table type. */
#if CONFIG_PAGING_LEVELS == 3
/* x86_32 PAE */
typedef struct { u32 pfn; } pagetable_t;
#elif CONFIG_PAGING_LEVELS == 4
/* x86_64 */
typedef struct { u64 pfn; } pagetable_t;
#endif
#define pagetable_get_paddr(x)  ((paddr_t)(x).pfn << PAGE_SHIFT)
#define pagetable_get_page(x)   mfn_to_page((x).pfn)
#define pagetable_get_pfn(x)    ((x).pfn)
#define pagetable_get_mfn(x)    _mfn(((x).pfn))
#define pagetable_is_null(x)    ((x).pfn == 0)
#define pagetable_from_pfn(pfn) ((pagetable_t) { (pfn) })
#define pagetable_from_mfn(mfn) ((pagetable_t) { mfn_x(mfn) })
#define pagetable_from_page(pg) pagetable_from_pfn(page_to_mfn(pg))
#define pagetable_from_paddr(p) pagetable_from_pfn((p)>>PAGE_SHIFT)
#define pagetable_null()        pagetable_from_pfn(0)

void clear_page_sse2(void *);
#define clear_page(_p)      (cpu_has_xmm2 ?                             \
                             clear_page_sse2((void *)(_p)) :            \
                             (void)memset((void *)(_p), 0, PAGE_SIZE))
void copy_page_sse2(void *, const void *);
#define copy_page(_t,_f)    (cpu_has_xmm2 ?                             \
                             copy_page_sse2(_t, _f) :                   \
                             (void)memcpy(_t, _f, PAGE_SIZE))

/* Convert between Xen-heap virtual addresses and machine addresses. */
#define __pa(x)             (virt_to_maddr(x))
#define __va(x)             (maddr_to_virt(x))

/* Convert between Xen-heap virtual addresses and machine frame numbers. */
#define __virt_to_mfn(va)   (virt_to_maddr(va) >> PAGE_SHIFT)
#define __mfn_to_virt(mfn)  (maddr_to_virt((paddr_t)(mfn) << PAGE_SHIFT))

/* Convert between machine frame numbers and page-info structures. */
#define __mfn_to_page(mfn)  (frame_table + pfn_to_pdx(mfn))
#define __page_to_mfn(pg)   pdx_to_pfn((unsigned long)((pg) - frame_table))

/* Convert between machine addresses and page-info structures. */
#define __maddr_to_page(ma) __mfn_to_page((ma) >> PAGE_SHIFT)
#define __page_to_maddr(pg) ((paddr_t)__page_to_mfn(pg) << PAGE_SHIFT)

/* Convert between frame number and address formats.  */
#define __pfn_to_paddr(pfn) ((paddr_t)(pfn) << PAGE_SHIFT)
#define __paddr_to_pfn(pa)  ((unsigned long)((pa) >> PAGE_SHIFT))

/*
 * We define non-underscored wrappers for above conversion functions. These are
 * overridden in various source files while underscored versions remain intact.
 */
#define mfn_valid(mfn)      __mfn_valid(mfn)
#define virt_to_mfn(va)     __virt_to_mfn(va)
#define mfn_to_virt(mfn)    __mfn_to_virt(mfn)
#define virt_to_maddr(va)   __virt_to_maddr((unsigned long)(va))
#define maddr_to_virt(ma)   __maddr_to_virt((unsigned long)(ma))
#define mfn_to_page(mfn)    __mfn_to_page(mfn)
#define page_to_mfn(pg)     __page_to_mfn(pg)
#define maddr_to_page(ma)   __maddr_to_page(ma)
#define page_to_maddr(pg)   __page_to_maddr(pg)
#define virt_to_page(va)    __virt_to_page(va)
#define page_to_virt(pg)    __page_to_virt(pg)
#define pfn_to_paddr(pfn)   __pfn_to_paddr(pfn)
#define paddr_to_pfn(pa)    __paddr_to_pfn(pa)

#endif /* !defined(__ASSEMBLY__) */

/* High table entries are reserved by the hypervisor. */
#define DOMAIN_ENTRIES_PER_L2_PAGETABLE     0
#define HYPERVISOR_ENTRIES_PER_L2_PAGETABLE 0

#define DOMAIN_ENTRIES_PER_L4_PAGETABLE     \
    (l4_table_offset(HYPERVISOR_VIRT_START))
#define GUEST_ENTRIES_PER_L4_PAGETABLE     \
    (l4_table_offset(HYPERVISOR_VIRT_END))
#define HYPERVISOR_ENTRIES_PER_L4_PAGETABLE \
    (L4_PAGETABLE_ENTRIES - GUEST_ENTRIES_PER_L4_PAGETABLE  \
     + DOMAIN_ENTRIES_PER_L4_PAGETABLE)

/* Where to find each level of the linear mapping */
#define __linear_l1_table ((l1_pgentry_t *)(LINEAR_PT_VIRT_START))
#define __linear_l2_table \
 ((l2_pgentry_t *)(__linear_l1_table + l1_linear_offset(LINEAR_PT_VIRT_START)))
#define __linear_l3_table \
 ((l3_pgentry_t *)(__linear_l2_table + l2_linear_offset(LINEAR_PT_VIRT_START)))
#define __linear_l4_table \
 ((l4_pgentry_t *)(__linear_l3_table + l3_linear_offset(LINEAR_PT_VIRT_START)))


#ifndef __ASSEMBLY__
extern root_pgentry_t idle_pg_table[ROOT_PAGETABLE_ENTRIES];
#if CONFIG_PAGING_LEVELS == 3
extern l2_pgentry_t   idle_pg_table_l2[
    ROOT_PAGETABLE_ENTRIES * L2_PAGETABLE_ENTRIES];
#elif CONFIG_PAGING_LEVELS == 4
extern l2_pgentry_t  *compat_idle_pg_table_l2;
extern unsigned int   m2p_compat_vstart;
#endif
void paging_init(void);
void setup_idle_pagetable(void);
#endif /* !defined(__ASSEMBLY__) */

#define _PAGE_PRESENT  0x001U
#define _PAGE_RW       0x002U
#define _PAGE_USER     0x004U
#define _PAGE_PWT      0x008U
#define _PAGE_PCD      0x010U
#define _PAGE_ACCESSED 0x020U
#define _PAGE_DIRTY    0x040U
#define _PAGE_PAT      0x080U
#define _PAGE_PSE      0x080U
#define _PAGE_GLOBAL   0x100U
#define _PAGE_AVAIL0   0x200U
#define _PAGE_AVAIL1   0x400U
#define _PAGE_AVAIL2   0x800U
#define _PAGE_AVAIL    0xE00U
#define _PAGE_PSE_PAT 0x1000U

/*
 * Debug option: Ensure that granted mappings are not implicitly unmapped.
 * WARNING: This will need to be disabled to run OSes that use the spare PTE
 * bits themselves (e.g., *BSD).
 */
#ifdef NDEBUG
#undef _PAGE_GNTTAB
#endif
#ifndef _PAGE_GNTTAB
#define _PAGE_GNTTAB   0
#endif

#define __PAGE_HYPERVISOR \
    (_PAGE_PRESENT | _PAGE_RW | _PAGE_DIRTY | _PAGE_ACCESSED)
#define __PAGE_HYPERVISOR_NOCACHE \
    (_PAGE_PRESENT | _PAGE_RW | _PAGE_DIRTY | _PAGE_PCD | _PAGE_ACCESSED)

#define GRANT_PTE_FLAGS \
    (_PAGE_PRESENT | _PAGE_ACCESSED | _PAGE_DIRTY | _PAGE_NX | _PAGE_GNTTAB)

#ifndef __ASSEMBLY__

static inline int get_order_from_bytes(paddr_t size)
{
    int order;
    size = (size-1) >> PAGE_SHIFT;
    for ( order = 0; size; order++ )
        size >>= 1;
    return order;
}

static inline int get_order_from_pages(unsigned long nr_pages)
{
    int order;
    nr_pages--;
    for ( order = 0; nr_pages; order++ )
        nr_pages >>= 1;
    return order;
}

/* Allocator functions for Xen pagetables. */
void *alloc_xen_pagetable(void);
void free_xen_pagetable(void *v);
l2_pgentry_t *virt_to_xen_l2e(unsigned long v);
#ifdef __x86_64__
l3_pgentry_t *virt_to_xen_l3e(unsigned long v);
#endif

/* Map machine page range in Xen virtual address space. */
#define MAP_SMALL_PAGES _PAGE_AVAIL0 /* don't use superpages for the mapping */
int map_pages_to_xen(
    unsigned long virt,
    unsigned long mfn,
    unsigned long nr_mfns,
    unsigned int flags);
void destroy_xen_mappings(unsigned long v, unsigned long e);

/* Convert between PAT/PCD/PWT embedded in PTE flags and 3-bit cacheattr. */
static inline uint32_t pte_flags_to_cacheattr(uint32_t flags)
{
    return ((flags >> 5) & 4) | ((flags >> 3) & 3);
}
static inline uint32_t cacheattr_to_pte_flags(uint32_t cacheattr)
{
    return ((cacheattr & 4) << 5) | ((cacheattr & 3) << 3);
}

#endif /* !__ASSEMBLY__ */

#define PFN_DOWN(x)   ((x) >> PAGE_SHIFT)
#define PFN_UP(x)     (((x) + PAGE_SIZE-1) >> PAGE_SHIFT)

#endif /* __X86_PAGE_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

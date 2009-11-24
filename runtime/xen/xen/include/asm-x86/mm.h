
#ifndef __ASM_X86_MM_H__
#define __ASM_X86_MM_H__

#include <xen/config.h>
#include <xen/list.h>
#include <asm/io.h>
#include <asm/uaccess.h>

/*
 * Per-page-frame information.
 * 
 * Every architecture must ensure the following:
 *  1. 'struct page_info' contains a 'struct page_list_entry list'.
 *  2. Provide a PFN_ORDER() macro for accessing the order of a free page.
 */
#define PFN_ORDER(_pfn) ((_pfn)->v.free.order)

/*
 * This definition is solely for the use in struct page_info (and
 * struct page_list_head), intended to allow easy adjustment once x86-64
 * wants to support more than 16TB.
 * 'unsigned long' should be used for MFNs everywhere else.
 */
#define __pdx_t unsigned int

#undef page_list_entry
struct page_list_entry
{
    __pdx_t next, prev;
};

struct page_info
{
    union {
        /* Each frame can be threaded onto a doubly-linked list.
         *
         * For unused shadow pages, a list of pages of this order; for
         * pinnable shadows, if pinned, a list of other pinned shadows
         * (see sh_type_is_pinnable() below for the definition of
         * "pinnable" shadow types).
         */
        struct page_list_entry list;
        /* For non-pinnable shadows, a higher entry that points at us. */
        paddr_t up;
    };

    /* Reference count and various PGC_xxx flags and fields. */
    unsigned long count_info;

    /* Context-dependent fields follow... */
    union {

        /* Page is in use: ((count_info & PGC_count_mask) != 0). */
        struct {
            /* Type reference count and various PGT_xxx flags and fields. */
            unsigned long type_info;
        } inuse;

        /* Page is in use as a shadow: count_info == 0. */
        struct {
            unsigned long type:5;   /* What kind of shadow is this? */
            unsigned long pinned:1; /* Is the shadow pinned? */
            unsigned long count:26; /* Reference count */
        } sh;

        /* Page is on a free list: ((count_info & PGC_count_mask) == 0). */
        struct {
            /* Do TLBs need flushing for safety before next page use? */
            bool_t need_tlbflush;
        } free;

    } u;

    union {

        /* Page is in use, but not as a shadow. */
        struct {
            /* Owner of this page (zero if page is anonymous). */
            __pdx_t _domain;
        } inuse;

        /* Page is in use as a shadow. */
        struct {
            /* GMFN of guest page we're a shadow of. */
            __pdx_t back;
        } sh;

        /* Page is on a free list (including shadow code free lists). */
        struct {
            /* Order-size of the free chunk this page is the head of. */
            unsigned int order;
        } free;

    } v;

    union {
        /*
         * Timestamp from 'TLB clock', used to avoid extra safety flushes.
         * Only valid for: a) free pages, and b) pages with zero type count
         * (except page table pages when the guest is in shadow mode).
         */
        u32 tlbflush_timestamp;

        /*
         * When PGT_partial is true then this field is valid and indicates
         * that PTEs in the range [0, @nr_validated_ptes) have been validated.
         * An extra page reference must be acquired (or not dropped) whenever
         * PGT_partial gets set, and it must be dropped when the flag gets
         * cleared. This is so that a get() leaving a page in partially
         * validated state (where the caller would drop the reference acquired
         * due to the getting of the type [apparently] failing [-EAGAIN])
         * would not accidentally result in a page left with zero general
         * reference count, but non-zero type reference count (possible when
         * the partial get() is followed immediately by domain destruction).
         * Likewise, the ownership of the single type reference for partially
         * (in-)validated pages is tied to this flag, i.e. the instance
         * setting the flag must not drop that reference, whereas the instance
         * clearing it will have to.
         *
         * If @partial_pte is positive then PTE at @nr_validated_ptes+1 has
         * been partially validated. This implies that the general reference
         * to the page (acquired from get_page_from_lNe()) would be dropped
         * (again due to the apparent failure) and hence must be re-acquired
         * when resuming the validation, but must not be dropped when picking
         * up the page for invalidation.
         *
         * If @partial_pte is negative then PTE at @nr_validated_ptes+1 has
         * been partially invalidated. This is basically the opposite case of
         * above, i.e. the general reference to the page was not dropped in
         * put_page_from_lNe() (due to the apparent failure), and hence it
         * must be dropped when the put operation is resumed (and completes),
         * but it must not be acquired if picking up the page for validation.
         */
        struct {
            u16 nr_validated_ptes;
            s8 partial_pte;
        };

        /*
         * Guest pages with a shadow.  This does not conflict with
         * tlbflush_timestamp since page table pages are explicitly not
         * tracked for TLB-flush avoidance when a guest runs in shadow mode.
         */
        u32 shadow_flags;

        /* When in use as a shadow, next shadow in this hash chain. */
        __pdx_t next_shadow;
    };
};

#undef __pdx_t

#define PG_shift(idx)   (BITS_PER_LONG - (idx))
#define PG_mask(x, idx) (x ## UL << PG_shift(idx))

 /* The following page types are MUTUALLY EXCLUSIVE. */
#define PGT_none          PG_mask(0, 3) /* no special uses of this page */
#define PGT_l1_page_table PG_mask(1, 3) /* using as an L1 page table? */
#define PGT_l2_page_table PG_mask(2, 3) /* using as an L2 page table? */
#define PGT_l3_page_table PG_mask(3, 3) /* using as an L3 page table? */
#define PGT_l4_page_table PG_mask(4, 3) /* using as an L4 page table? */
#define PGT_seg_desc_page PG_mask(5, 3) /* using this page in a GDT/LDT? */
#define PGT_writable_page PG_mask(7, 3) /* has writable mappings? */
#define PGT_type_mask     PG_mask(7, 3) /* Bits 29-31. */

 /* Owning guest has pinned this page to its current type? */
#define _PGT_pinned       PG_shift(4)
#define PGT_pinned        PG_mask(1, 4)
 /* Has this page been validated for use as its current type? */
#define _PGT_validated    PG_shift(5)
#define PGT_validated     PG_mask(1, 5)
 /* PAE only: is this an L2 page directory containing Xen-private mappings? */
#define _PGT_pae_xen_l2   PG_shift(6)
#define PGT_pae_xen_l2    PG_mask(1, 6)
/* Has this page been *partially* validated for use as its current type? */
#define _PGT_partial      PG_shift(7)
#define PGT_partial       PG_mask(1, 7)
 /* Page is locked? */
#define _PGT_locked       PG_shift(8)
#define PGT_locked        PG_mask(1, 8)

 /* Count of uses of this frame as its current type. */
#define PGT_count_width   PG_shift(8)
#define PGT_count_mask    ((1UL<<PGT_count_width)-1)

 /* Cleared when the owning guest 'frees' this page. */
#define _PGC_allocated    PG_shift(1)
#define PGC_allocated     PG_mask(1, 1)
 /* Page is Xen heap? */
#define _PGC_xen_heap     PG_shift(2)
#define PGC_xen_heap      PG_mask(1, 2)
 /* Set when is using a page as a page table */
#define _PGC_page_table   PG_shift(3)
#define PGC_page_table    PG_mask(1, 3)
 /* 3-bit PAT/PCD/PWT cache-attribute hint. */
#define PGC_cacheattr_base PG_shift(6)
#define PGC_cacheattr_mask PG_mask(7, 6)
 /* Page is broken? */
#define _PGC_broken       PG_shift(7)
#define PGC_broken        PG_mask(1, 7)
 /* Mutually-exclusive page states: { inuse, offlining, offlined, free }. */
#define PGC_state         PG_mask(3, 9)
#define PGC_state_inuse   PG_mask(0, 9)
#define PGC_state_offlining PG_mask(1, 9)
#define PGC_state_offlined PG_mask(2, 9)
#define PGC_state_free    PG_mask(3, 9)
#define page_state_is(pg, st) (((pg)->count_info&PGC_state) == PGC_state_##st)

 /* Count of references to this frame. */
#define PGC_count_width   PG_shift(9)
#define PGC_count_mask    ((1UL<<PGC_count_width)-1)

#if defined(__i386__)
#define is_xen_heap_page(page) is_xen_heap_mfn(page_to_mfn(page))
#define is_xen_heap_mfn(mfn) ({                         \
    unsigned long _mfn = (mfn);                         \
    (_mfn < paddr_to_pfn(xenheap_phys_end));            \
})
#define is_xen_fixed_mfn(mfn) is_xen_heap_mfn(mfn)
#else
#define is_xen_heap_page(page) ((page)->count_info & PGC_xen_heap)
#define is_xen_heap_mfn(mfn) \
    (__mfn_valid(mfn) && is_xen_heap_page(__mfn_to_page(mfn)))
#define is_xen_fixed_mfn(mfn)                     \
    ((((mfn) << PAGE_SHIFT) >= __pa(&_start)) &&  \
     (((mfn) << PAGE_SHIFT) <= __pa(&_end)))
#endif

#if defined(__i386__)
#define PRtype_info "08lx" /* should only be used for printk's */
#elif defined(__x86_64__)
#define PRtype_info "016lx"/* should only be used for printk's */
#endif

/* The order of the largest allocation unit we use for shadow pages */
#define SHADOW_MAX_ORDER 2 /* Need up to 16k allocs for 32-bit on PAE/64 */

/* The number of out-of-sync shadows we allow per vcpu (prime, please) */
#define SHADOW_OOS_PAGES 3

/* OOS fixup entries */
#define SHADOW_OOS_FIXUPS 2

#define page_get_owner(_p)                                              \
    ((struct domain *)((_p)->v.inuse._domain ?                          \
                       pdx_to_virt((_p)->v.inuse._domain) : NULL))
#define page_set_owner(_p,_d)                                           \
    ((_p)->v.inuse._domain = (_d) ? virt_to_pdx(_d) : 0)

#define maddr_get_owner(ma)   (page_get_owner(maddr_to_page((ma))))
#define vaddr_get_owner(va)   (page_get_owner(virt_to_page((va))))

#define XENSHARE_writable 0
#define XENSHARE_readonly 1
extern void share_xen_page_with_guest(
    struct page_info *page, struct domain *d, int readonly);
extern void share_xen_page_with_privileged_guests(
    struct page_info *page, int readonly);

#define frame_table ((struct page_info *)FRAMETABLE_VIRT_START)
extern unsigned long max_page;
extern unsigned long total_pages;
void init_frametable(void);

#define PDX_GROUP_COUNT ((1 << L2_PAGETABLE_SHIFT) / \
                         (sizeof(*frame_table) & -sizeof(*frame_table)))
extern unsigned long pdx_group_valid[];

/* Convert between Xen-heap virtual addresses and page-info structures. */
static inline struct page_info *__virt_to_page(const void *v)
{
    unsigned long va = (unsigned long)v;

#ifdef __x86_64__
    ASSERT(va >= XEN_VIRT_START);
    ASSERT(va < DIRECTMAP_VIRT_END);
    if ( va < XEN_VIRT_END )
        va += DIRECTMAP_VIRT_START - XEN_VIRT_START + xen_phys_start;
    else
        ASSERT(va >= DIRECTMAP_VIRT_START);
#else
    ASSERT(va - DIRECTMAP_VIRT_START < DIRECTMAP_VIRT_END);
#endif
    return frame_table + ((va - DIRECTMAP_VIRT_START) >> PAGE_SHIFT);
}

static inline void *__page_to_virt(const struct page_info *pg)
{
    ASSERT((unsigned long)pg - FRAMETABLE_VIRT_START < FRAMETABLE_VIRT_END);
    return (void *)(DIRECTMAP_VIRT_START +
                    ((unsigned long)pg - FRAMETABLE_VIRT_START) /
                    (sizeof(*pg) / (sizeof(*pg) & -sizeof(*pg))) *
                    (PAGE_SIZE / (sizeof(*pg) & -sizeof(*pg))));
}

int free_page_type(struct page_info *page, unsigned long type,
                   int preemptible);
int _shadow_mode_refcounts(struct domain *d);

void cleanup_page_cacheattr(struct page_info *page);

int is_iomem_page(unsigned long mfn);

struct domain *page_get_owner_and_reference(struct page_info *page);
void put_page(struct page_info *page);
int  get_page(struct page_info *page, struct domain *domain);
void put_page_type(struct page_info *page);
int  get_page_type(struct page_info *page, unsigned long type);
int  put_page_type_preemptible(struct page_info *page);
int  get_page_type_preemptible(struct page_info *page, unsigned long type);
int  get_page_from_l1e(
    l1_pgentry_t l1e, struct domain *l1e_owner, struct domain *pg_owner);
void put_page_from_l1e(l1_pgentry_t l1e, struct domain *l1e_owner);

static inline void put_page_and_type(struct page_info *page)
{
    put_page_type(page);
    put_page(page);
}

static inline int put_page_and_type_preemptible(struct page_info *page,
                                                int preemptible)
{
    int rc = 0;

    if ( preemptible )
        rc = put_page_type_preemptible(page);
    else
        put_page_type(page);
    if ( likely(rc == 0) )
        put_page(page);
    return rc;
}

static inline int get_page_and_type(struct page_info *page,
                                    struct domain *domain,
                                    unsigned long type)
{
    int rc = get_page(page, domain);

    if ( likely(rc) && unlikely(!get_page_type(page, type)) )
    {
        put_page(page);
        rc = 0;
    }

    return rc;
}

#define ASSERT_PAGE_IS_TYPE(_p, _t)                            \
    ASSERT(((_p)->u.inuse.type_info & PGT_type_mask) == (_t)); \
    ASSERT(((_p)->u.inuse.type_info & PGT_count_mask) != 0)
#define ASSERT_PAGE_IS_DOMAIN(_p, _d)                          \
    ASSERT(((_p)->count_info & PGC_count_mask) != 0);          \
    ASSERT(page_get_owner(_p) == (_d))

// Quick test for whether a given page can be represented directly in CR3.
//
#if CONFIG_PAGING_LEVELS == 3
#define MFN_FITS_IN_CR3(_MFN) !(mfn_x(_MFN) >> 20)

/* returns a lowmem machine address of the copied L3 root table */
unsigned long
pae_copy_root(struct vcpu *v, l3_pgentry_t *l3tab);
#endif /* CONFIG_PAGING_LEVELS == 3 */

int check_descriptor(const struct domain *, struct desc_struct *d);

extern int opt_allow_hugepage;

/******************************************************************************
 * With shadow pagetables, the different kinds of address start 
 * to get get confusing.
 * 
 * Virtual addresses are what they usually are: the addresses that are used 
 * to accessing memory while the guest is running.  The MMU translates from 
 * virtual addresses to machine addresses. 
 * 
 * (Pseudo-)physical addresses are the abstraction of physical memory the
 * guest uses for allocation and so forth.  For the purposes of this code, 
 * we can largely ignore them.
 *
 * Guest frame numbers (gfns) are the entries that the guest puts in its
 * pagetables.  For normal paravirtual guests, they are actual frame numbers,
 * with the translation done by the guest.  
 * 
 * Machine frame numbers (mfns) are the entries that the hypervisor puts
 * in the shadow page tables.
 *
 * Elsewhere in the xen code base, the name "gmfn" is generally used to refer
 * to a "machine frame number, from the guest's perspective", or in other
 * words, pseudo-physical frame numbers.  However, in the shadow code, the
 * term "gmfn" means "the mfn of a guest page"; this combines naturally with
 * other terms such as "smfn" (the mfn of a shadow page), gl2mfn (the mfn of a
 * guest L2 page), etc...
 */

/* With this defined, we do some ugly things to force the compiler to
 * give us type safety between mfns and gfns and other integers.
 * TYPE_SAFE(int foo) defines a foo_t, and _foo() and foo_x() functions 
 * that translate beween int and foo_t.
 * 
 * It does have some performance cost because the types now have 
 * a different storage attribute, so may not want it on all the time. */

#ifndef NDEBUG
#define TYPE_SAFETY 1
#endif

#ifdef TYPE_SAFETY
#define TYPE_SAFE(_type,_name)                                  \
typedef struct { _type _name; } _name##_t;                      \
static inline _name##_t _##_name(_type n) { return (_name##_t) { n }; } \
static inline _type _name##_x(_name##_t n) { return n._name; }
#else
#define TYPE_SAFE(_type,_name)                                          \
typedef _type _name##_t;                                                \
static inline _name##_t _##_name(_type n) { return n; }                 \
static inline _type _name##_x(_name##_t n) { return n; }
#endif

TYPE_SAFE(unsigned long,mfn);

/* Macro for printk formats: use as printk("%"PRI_mfn"\n", mfn_x(foo)); */
#define PRI_mfn "05lx"


/*
 * The MPT (machine->physical mapping table) is an array of word-sized
 * values, indexed on machine frame number. It is expected that guest OSes
 * will use it to store a "physical" frame number to give the appearance of
 * contiguous (or near contiguous) physical memory.
 */
#undef  machine_to_phys_mapping
#define machine_to_phys_mapping  ((unsigned long *)RDWR_MPT_VIRT_START)
#define INVALID_M2P_ENTRY        (~0UL)
#define VALID_M2P(_e)            (!((_e) & (1UL<<(BITS_PER_LONG-1))))

#ifdef CONFIG_COMPAT
#define compat_machine_to_phys_mapping ((unsigned int *)RDWR_COMPAT_MPT_VIRT_START)
#define set_gpfn_from_mfn(mfn, pfn) \
    ((void)((mfn) >= (RDWR_COMPAT_MPT_VIRT_END - RDWR_COMPAT_MPT_VIRT_START) / 4 || \
            (compat_machine_to_phys_mapping[(mfn)] = (unsigned int)(pfn))), \
     machine_to_phys_mapping[(mfn)] = (pfn))
#else
#define set_gpfn_from_mfn(mfn, pfn) (machine_to_phys_mapping[(mfn)] = (pfn))
#endif
#define get_gpfn_from_mfn(mfn)      (machine_to_phys_mapping[(mfn)])

#define mfn_to_gmfn(_d, mfn)                            \
    ( (paging_mode_translate(_d))                       \
      ? get_gpfn_from_mfn(mfn)                          \
      : (mfn) )

#define INVALID_MFN             (~0UL)

#define compat_pfn_to_cr3(pfn) (((unsigned)(pfn) << 12) | ((unsigned)(pfn) >> 20))
#define compat_cr3_to_pfn(cr3) (((unsigned)(cr3) >> 12) | ((unsigned)(cr3) << 20))

#ifdef MEMORY_GUARD
void memguard_init(void);
void memguard_guard_range(void *p, unsigned long l);
void memguard_unguard_range(void *p, unsigned long l);
#else
#define memguard_init()                ((void)0)
#define memguard_guard_range(_p,_l)    ((void)0)
#define memguard_unguard_range(_p,_l)  ((void)0)
#endif

void memguard_guard_stack(void *p);

int  ptwr_do_page_fault(struct vcpu *, unsigned long,
                        struct cpu_user_regs *);

int audit_adjust_pgtables(struct domain *d, int dir, int noisy);

#ifndef NDEBUG

#define AUDIT_SHADOW_ALREADY_LOCKED ( 1u << 0 )
#define AUDIT_ERRORS_OK             ( 1u << 1 )
#define AUDIT_QUIET                 ( 1u << 2 )

void _audit_domain(struct domain *d, int flags);
#define audit_domain(_d) _audit_domain((_d), AUDIT_ERRORS_OK)
void audit_domains(void);

#else

#define _audit_domain(_d, _f) ((void)0)
#define audit_domain(_d)      ((void)0)
#define audit_domains()       ((void)0)

#endif

int new_guest_cr3(unsigned long pfn);
void make_cr3(struct vcpu *v, unsigned long mfn);
void update_cr3(struct vcpu *v);
void propagate_page_fault(unsigned long addr, u16 error_code);
void *do_page_walk(struct vcpu *v, unsigned long addr);

int __sync_lazy_execstate(void);

/* Arch-specific portion of memory_op hypercall. */
long arch_memory_op(int op, XEN_GUEST_HANDLE(void) arg);
long subarch_memory_op(int op, XEN_GUEST_HANDLE(void) arg);
int compat_arch_memory_op(int op, XEN_GUEST_HANDLE(void));
int compat_subarch_memory_op(int op, XEN_GUEST_HANDLE(void));

int steal_page(
    struct domain *d, struct page_info *page, unsigned int memflags);
int donate_page(
    struct domain *d, struct page_info *page, unsigned int memflags);

int map_ldt_shadow_page(unsigned int);

#ifdef CONFIG_COMPAT
void domain_set_alloc_bitsize(struct domain *d);
unsigned int domain_clamp_alloc_bitsize(struct domain *d, unsigned int bits);
#else
# define domain_set_alloc_bitsize(d) ((void)0)
# define domain_clamp_alloc_bitsize(d, b) (b)
#endif

unsigned long domain_get_maximum_gpfn(struct domain *d);

extern struct domain *dom_xen, *dom_io;	/* for vmcoreinfo */

#endif /* __ASM_X86_MM_H__ */

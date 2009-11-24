/*
 * Copyright (c) 2006 Isaku Yamahata <yamahata at valinux co jp>
 *                    VA Linux Systems Japan K.K.
 *                    dom0 vp model support
 */
#ifndef __ASM_IA64_MM_H__
#define __ASM_IA64_MM_H__

#include <xen/config.h>
#ifdef LINUX_2_6
#include <linux/gfp.h>
#endif
#include <xen/list.h>
#include <xen/spinlock.h>
#include <xen/perfc.h>

#include <asm/processor.h>
#include <asm/atomic.h>
#include <asm/tlbflush.h>
#include <asm/flushtlb.h>
#include <asm/io.h>

#include <public/xen.h>

/*
 * The following is for page_alloc.c.
 */

typedef unsigned long page_flags_t;

/*
 * Per-page-frame information.
 * 
 * Every architecture must ensure the following:
 *  1. 'struct page_info' contains a 'struct list_head list'.
 *  2. Provide a PFN_ORDER() macro for accessing the order of a free page.
 */
#define PFN_ORDER(_pfn)	((_pfn)->u.free.order)

#define PRtype_info "016lx"

#ifdef CONFIG_IA64_SHRINK_PAGE_LIST
/*
 * See include/xen/mm.h.
 * To compress page_list_entry, all the physical address must
 * be addressed by (32 + PAGE_SHIFT) .
 * However this is lower than IA64_MAX_PHYS_BITS = 50.
 */
#undef page_list_entry
struct page_list_entry
{
    u32 next, prev;
};
#endif

#ifdef CONFIG_IA64_PICKLE_DOMAIN
typedef u32 __ia64_domain_t;
#else
typedef unsigned long __ia64_domain_t;
#endif

struct page_info
{
    /* Each frame can be threaded onto a doubly-linked list. */
    struct page_list_entry list;

    /* Reference count and various PGC_xxx flags and fields. */
    unsigned long count_info;

    /* Context-dependent fields follow... */
    union {

        /* Page is in use: ((count_info & PGC_count_mask) != 0). */
        struct {
            /* Type reference count and various PGT_xxx flags and fields. */
            unsigned long type_info;
            /* Owner of this page (NULL if page is anonymous). */
            __ia64_domain_t _domain; /* pickled format */
        } inuse;

        /* Page is on a free list: ((count_info & PGC_count_mask) == 0). */
        struct {
            /* Order-size of the free chunk this page is the head of. */
            u32 order;
            /* Do TLBs need flushing for safety before next page use? */
            bool_t need_tlbflush;
        } free;

    } u;

    /* Timestamp from 'TLB clock', used to reduce need for safety flushes. */
    u32 tlbflush_timestamp;
};

#define set_page_count(p,v) 	atomic_set(&(p)->_count, v - 1)

/*
 * Still small set of flags defined by far on IA-64.
 * IA-64 should make it a definition same as x86_64.
 */
#define PG_shift(idx)   (BITS_PER_LONG - (idx))
#define PG_mask(x, idx) (x ## UL << PG_shift(idx))

/* The following page types are MUTUALLY EXCLUSIVE. */
#define PGT_none          PG_mask(0, 3) /* no special uses of this page */
#define PGT_l1_page_table PG_mask(1, 3) /* using as an L1 page table? */
#define PGT_l2_page_table PG_mask(2, 3) /* using as an L2 page table? */
#define PGT_l3_page_table PG_mask(3, 3) /* using as an L3 page table? */
#define PGT_l4_page_table PG_mask(4, 3) /* using as an L4 page table? */
 /* Value 5 reserved. See asm-x86/mm.h */
 /* Value 6 reserved. See asm-x86/mm.h */
#define PGT_writable_page PG_mask(7, 3) /* has writable mappings? */
#define PGT_type_mask     PG_mask(7, 3) /* Bits 29-31. */

 /* Owning guest has pinned this page to its current type? */
#define _PGT_pinned       PG_shift(4)
#define PGT_pinned        PG_mask(1, 4)
 /* Has this page been validated for use as its current type? */
#define _PGT_validated    PG_shift(5)
#define PGT_validated     PG_mask(1, 5)

 /* Count of uses of this frame as its current type. */
#define PGT_count_width   PG_shift(7)
#define PGT_count_mask    ((1UL<<PGT_count_width)-1)

 /* Cleared when the owning guest 'frees' this page. */
#define _PGC_allocated    PG_shift(1)
#define PGC_allocated     PG_mask(1, 1)
 /* Page is Xen heap? */
# define _PGC_xen_heap    PG_shift(2)
# define PGC_xen_heap     PG_mask(1, 2)
 /* bit PG_shift(3) reserved. See asm-x86/mm.h */
 /* PG_mask(7, 6) reserved. See asm-x86/mm.h*/

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

extern unsigned long xen_fixed_mfn_start;
extern unsigned long xen_fixed_mfn_end;
#define is_xen_heap_page(page)  ((page)->count_info & PGC_xen_heap)
#define is_xen_heap_mfn(mfn)    (mfn_valid(mfn) &&                      \
                                 is_xen_heap_page(mfn_to_page(mfn)))
#define is_xen_fixed_mfn(mfn)                                           \
    (xen_fixed_mfn_start <= (mfn) && (mfn) <= xen_fixed_mfn_end)

#ifdef CONFIG_IA64_PICKLE_DOMAIN
#define page_get_owner(_p)                                              \
    ((struct domain *)((_p)->v.inuse._domain ?                          \
                       mfn_to_virt((_p)->v.inuse._domain) : NULL))
#define page_set_owner(_p,_d)                                           \
    ((_p)->v.inuse._domain = (_d) ? virt_to_mfn(_d) : 0)
#else
#define page_get_owner(_p)      ((struct domain *)(_p)->u.inuse._domain)
#define page_set_owner(_p, _d)	((_p)->u.inuse._domain = (unsigned long)(_d))
#endif

#define XENSHARE_writable 0
#define XENSHARE_readonly 1
void share_xen_page_with_guest(struct page_info *page,
                               struct domain *d, int readonly);
void share_xen_page_with_privileged_guests(struct page_info *page,
                                           int readonly);

extern unsigned long frametable_pg_dir[];
extern struct page_info *frame_table;
extern unsigned long frame_table_size;
extern struct list_head free_list;
extern spinlock_t free_list_lock;
extern unsigned int free_pfns;
extern unsigned long max_page;

extern void __init init_frametable(void);
void add_to_domain_alloc_list(unsigned long ps, unsigned long pe);

static inline void put_page(struct page_info *page)
{
    unsigned long nx, x, y = page->count_info;

    do {
        ASSERT((y & PGC_count_mask) != 0);
        x = y;
        nx = x - 1;
    }
    while (unlikely((y = cmpxchg_rel(&page->count_info, x, nx)) != x));

    if (unlikely((nx & PGC_count_mask) == 0))
        free_domheap_page(page);
}

static inline struct domain *page_get_owner_and_reference(
    struct page_info *page)
{
    unsigned long x, y = page->count_info;

    do {
        x = y;
        /*
         * Count ==  0: Page is not allocated, so we cannot take a reference.
         * Count == -1: Reference count would wrap, which is invalid.
         * Count == -2: Remaining unused ref is reserved for get_page_light().
         */
        /*
         * On ia64, get_page_light() isn't defined so that it doesn't
         * make sense to take care of Count == -2.
         * Just for consistency with x86.
         */
        if ( unlikely(((x + 2) & PGC_count_mask) <= 2) )
            return NULL;
        y = cmpxchg_acq(&page->count_info, x, x + 1);
    } while (unlikely(y != x));

    return page_get_owner(page);
}

/* count_info and ownership are checked atomically. */
static inline int get_page(struct page_info *page,
                           struct domain *domain)
{
    struct domain *owner = page_get_owner_and_reference(page);

    if (likely(owner == domain))
        return 1;

    if (owner != NULL)
        put_page(page);

    /* if (!domain->is_dying) */ /* XXX: header inclusion hell */
    gdprintk(XENLOG_INFO,
             "Error pfn %lx: rd=%p, od=%p, caf=%016lx, taf=%" PRtype_info "\n",
             page_to_mfn(page), domain,
             owner, page->count_info, page->u.inuse.type_info);
    return 0;
}

int is_iomem_page(unsigned long mfn);

extern void put_page_type(struct page_info *page);
extern int get_page_type(struct page_info *page, unsigned long type);

static inline void put_page_and_type(struct page_info *page)
{
    put_page_type(page);
    put_page(page);
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

#define	set_machinetophys(_mfn, _pfn) do { } while(0);

#ifdef MEMORY_GUARD
void *memguard_init(void *heap_start);
void memguard_guard_stack(void *p);
void memguard_guard_range(void *p, unsigned long l);
void memguard_unguard_range(void *p, unsigned long l);
#else
#define memguard_init(_s)              (_s)
#define memguard_guard_stack(_p)       ((void)0)
#define memguard_guard_range(_p,_l)    ((void)0)
#define memguard_unguard_range(_p,_l)  ((void)0)
#endif

// prototype of misc memory stuff
//unsigned long __get_free_pages(unsigned int mask, unsigned int order);
//void __free_pages(struct page_info *page, unsigned int order);
void *pgtable_quicklist_alloc(void);
void pgtable_quicklist_free(void *pgtable_entry);

// FOLLOWING FROM linux-2.6.7/include/mm.h

/*
 * This struct defines a memory VMM memory area. There is one of these
 * per VM-area/task.  A VM area is any part of the process virtual memory
 * space that has a special rule for the page-fault handlers (ie a shared
 * library, the executable area etc).
 */
struct vm_area_struct {
	struct mm_struct * vm_mm;	/* The address space we belong to. */
	unsigned long vm_start;		/* Our start address within vm_mm. */
	unsigned long vm_end;		/* The first byte after our end address
					   within vm_mm. */

	/* linked list of VM areas per task, sorted by address */
	struct vm_area_struct *vm_next;

	pgprot_t vm_page_prot;		/* Access permissions of this VMA. */
	unsigned long vm_flags;		/* Flags, listed below. */

#ifndef XEN
	struct rb_node vm_rb;

// XEN doesn't need all the backing store stuff
	/*
	 * For areas with an address space and backing store,
	 * linkage into the address_space->i_mmap prio tree, or
	 * linkage to the list of like vmas hanging off its node, or
	 * linkage of vma in the address_space->i_mmap_nonlinear list.
	 */
	union {
		struct {
			struct list_head list;
			void *parent;	/* aligns with prio_tree_node parent */
			struct vm_area_struct *head;
		} vm_set;

		struct prio_tree_node prio_tree_node;
	} shared;

	/*
	 * A file's MAP_PRIVATE vma can be in both i_mmap tree and anon_vma
	 * list, after a COW of one of the file pages.  A MAP_SHARED vma
	 * can only be in the i_mmap tree.  An anonymous MAP_PRIVATE, stack
	 * or brk vma (with NULL file) can only be in an anon_vma list.
	 */
	struct list_head anon_vma_node;	/* Serialized by anon_vma->lock */
	struct anon_vma *anon_vma;	/* Serialized by page_table_lock */

	/* Function pointers to deal with this struct. */
	struct vm_operations_struct * vm_ops;

	/* Information about our backing store: */
	unsigned long vm_pgoff;		/* Offset (within vm_file) in PAGE_SIZE
					   units, *not* PAGE_CACHE_SIZE */
	struct file * vm_file;		/* File we map to (can be NULL). */
	void * vm_private_data;		/* was vm_pte (shared mem) */

#ifdef CONFIG_NUMA
	struct mempolicy *vm_policy;	/* NUMA policy for the VMA */
#endif
#endif
};
/*
 * vm_flags..
 */
#define VM_READ		0x00000001	/* currently active flags */
#define VM_WRITE	0x00000002
#define VM_EXEC		0x00000004
#define VM_SHARED	0x00000008

#define VM_MAYREAD	0x00000010	/* limits for mprotect() etc */
#define VM_MAYWRITE	0x00000020
#define VM_MAYEXEC	0x00000040
#define VM_MAYSHARE	0x00000080

#define VM_GROWSDOWN	0x00000100	/* general info on the segment */
#define VM_GROWSUP	0x00000200
#define VM_SHM		0x00000400	/* shared memory area, don't swap out */
#define VM_DENYWRITE	0x00000800	/* ETXTBSY on write attempts.. */

#define VM_EXECUTABLE	0x00001000
#define VM_LOCKED	0x00002000
#define VM_IO           0x00004000	/* Memory mapped I/O or similar */

					/* Used by sys_madvise() */
#define VM_SEQ_READ	0x00008000	/* App will access data sequentially */
#define VM_RAND_READ	0x00010000	/* App will not benefit from clustered reads */

#define VM_DONTCOPY	0x00020000      /* Do not copy this vma on fork */
#define VM_DONTEXPAND	0x00040000	/* Cannot expand with mremap() */
#define VM_RESERVED	0x00080000	/* Don't unmap it from swap_out */
#define VM_ACCOUNT	0x00100000	/* Is a VM accounted object */
#define VM_HUGETLB	0x00400000	/* Huge TLB Page VM */
#define VM_NONLINEAR	0x00800000	/* Is non-linear (remap_file_pages) */

#ifndef VM_STACK_DEFAULT_FLAGS		/* arch can override this */
#define VM_STACK_DEFAULT_FLAGS VM_DATA_DEFAULT_FLAGS
#endif

#ifdef CONFIG_STACK_GROWSUP
#define VM_STACK_FLAGS	(VM_GROWSUP | VM_STACK_DEFAULT_FLAGS | VM_ACCOUNT)
#else
#define VM_STACK_FLAGS	(VM_GROWSDOWN | VM_STACK_DEFAULT_FLAGS | VM_ACCOUNT)
#endif

#if 0	/* removed when rebasing to 2.6.13 */
/*
 * The zone field is never updated after free_area_init_core()
 * sets it, so none of the operations on it need to be atomic.
 * We'll have up to (MAX_NUMNODES * MAX_NR_ZONES) zones total,
 * so we use (MAX_NODES_SHIFT + MAX_ZONES_SHIFT) here to get enough bits.
 */
#define NODEZONE_SHIFT (sizeof(page_flags_t)*8 - MAX_NODES_SHIFT - MAX_ZONES_SHIFT)
#define NODEZONE(node, zone)	((node << ZONES_SHIFT) | zone)

static inline unsigned long page_zonenum(struct page_info *page)
{
	return (page->flags >> NODEZONE_SHIFT) & (~(~0UL << ZONES_SHIFT));
}
static inline unsigned long page_to_nid(struct page_info *page)
{
	return (page->flags >> (NODEZONE_SHIFT + ZONES_SHIFT));
}

struct zone;
extern struct zone *zone_table[];

static inline struct zone *page_zone(struct page_info *page)
{
	return zone_table[page->flags >> NODEZONE_SHIFT];
}

static inline void set_page_zone(struct page_info *page, unsigned long nodezone_num)
{
	page->flags &= ~(~0UL << NODEZONE_SHIFT);
	page->flags |= nodezone_num << NODEZONE_SHIFT;
}
#endif

#ifndef CONFIG_DISCONTIGMEM          /* Don't use mapnrs, do it properly */
extern unsigned long max_mapnr;
#endif

static inline void *lowmem_page_address(struct page_info *page)
{
	return __va(page_to_mfn(page) << PAGE_SHIFT);
}

#if defined(CONFIG_HIGHMEM) && !defined(WANT_PAGE_VIRTUAL)
#define HASHED_PAGE_VIRTUAL
#endif

#if defined(WANT_PAGE_VIRTUAL)
#define page_address(page) ((page)->virtual)
#define set_page_address(page, address)			\
	do {						\
		(page)->virtual = (address);		\
	} while(0)
#define page_address_init()  do { } while(0)
#endif

#if defined(HASHED_PAGE_VIRTUAL)
void *page_address(struct page_info *page);
void set_page_address(struct page_info *page, void *virtual);
void page_address_init(void);
#endif

#if !defined(HASHED_PAGE_VIRTUAL) && !defined(WANT_PAGE_VIRTUAL)
#define page_address(page) lowmem_page_address(page)
#define set_page_address(page, address)  do { } while(0)
#define page_address_init()  do { } while(0)
#endif


#ifndef CONFIG_DEBUG_PAGEALLOC
static inline void
kernel_map_pages(struct page_info *page, int numpages, int enable)
{
}
#endif

extern unsigned long num_physpages;
extern unsigned long totalram_pages;
extern int nr_swap_pages;

extern void alloc_dom_xen_and_dom_io(void);
extern int mm_teardown(struct domain* d);
extern void mm_final_teardown(struct domain* d);
extern struct page_info * assign_new_domain_page(struct domain *d, unsigned long mpaddr);
extern void assign_new_domain0_page(struct domain *d, unsigned long mpaddr);
extern int __assign_domain_page(struct domain *d, unsigned long mpaddr, unsigned long physaddr, unsigned long flags);
extern void assign_domain_page(struct domain *d, unsigned long mpaddr, unsigned long physaddr);
extern void assign_domain_io_page(struct domain *d, unsigned long mpaddr, unsigned long flags);
extern int deassign_domain_mmio_page(struct domain *d, unsigned long mpaddr,
                        unsigned long phys_addr, unsigned long size);
struct p2m_entry;
extern unsigned long lookup_domain_mpa(struct domain *d, unsigned long mpaddr, struct p2m_entry* entry);
extern void *domain_mpa_to_imva(struct domain *d, unsigned long mpaddr);
extern volatile pte_t *lookup_noalloc_domain_pte(struct domain* d, unsigned long mpaddr);
extern unsigned long assign_domain_mmio_page(struct domain *d, unsigned long mpaddr, unsigned long phys_addr, unsigned long size, unsigned long flags);
extern unsigned long assign_domain_mach_page(struct domain *d, unsigned long mpaddr, unsigned long size, unsigned long flags);
int domain_page_mapped(struct domain *d, unsigned long mpaddr);
int efi_mmio(unsigned long physaddr, unsigned long size);
extern unsigned long ____lookup_domain_mpa(struct domain *d, unsigned long mpaddr);
extern unsigned long do_dom0vp_op(unsigned long cmd, unsigned long arg0, unsigned long arg1, unsigned long arg2, unsigned long arg3);
extern unsigned long dom0vp_zap_physmap(struct domain *d, unsigned long gpfn, unsigned int extent_order);
extern unsigned long dom0vp_add_physmap(struct domain* d, unsigned long gpfn, unsigned long mfn, unsigned long flags, domid_t domid);
extern unsigned long dom0vp_add_physmap_with_gmfn(struct domain* d, unsigned long gpfn, unsigned long gmfn, unsigned long flags, domid_t domid);
#ifdef CONFIG_XEN_IA64_EXPOSE_P2M
extern void expose_p2m_init(void);
extern unsigned long dom0vp_expose_p2m(struct domain* d, unsigned long conv_start_gpfn, unsigned long assign_start_gpfn, unsigned long expose_size, unsigned long granule_pfn);
extern void foreign_p2m_init(struct domain* d);
extern void foreign_p2m_destroy(struct domain* d);
extern unsigned long dom0vp_expose_foreign_p2m(struct domain* dest_dom, unsigned long dest_gpfn, domid_t domid, XEN_GUEST_HANDLE(char) buffer, unsigned long flags);
extern unsigned long dom0vp_unexpose_foreign_p2m(struct domain* dest_dom, unsigned long dest_gpfn, domid_t domid);
extern unsigned long dom0vp_get_memmap(domid_t domid, XEN_GUEST_HANDLE(char) buffer);
#else
#define expose_p2m_init()       do { } while (0)
#define dom0vp_expose_p2m(d, conv_start_gpfn, assign_start_gpfn, expose_size, granule_pfn)	(-ENOSYS)
#define foreign_p2m_init(d)	do { } while (0)
#define foreign_p2m_destroy(d)	do { } while (0)
#define dom0vp_expose_foreign_p2m(dest_dom, dest_gpfn, domid, buffer, flags)	(-ENOSYS)
#define dom0vp_unexpose_foreign_p2m(dest_dom, dest_gpfn, domid)	(-ENOSYS)
#define __dom0vp_add_memdesc(d, memmap_info, memdesc)	(-ENOSYS)
#define dom0vp_get_memmap(domid, buffer)		(-ENOSYS)
#endif

int
p2m_pod_decrease_reservation(struct domain *d,
                             xen_pfn_t gpfn, unsigned int order);
int guest_physmap_mark_populate_on_demand(struct domain *d, unsigned long gfn,
                                          unsigned int order);

extern volatile unsigned long *mpt_table;
extern unsigned long gmfn_to_mfn_foreign(struct domain *d, unsigned long gpfn);
extern u64 translate_domain_pte(u64 pteval, u64 address, u64 itir__,
				u64* itir, struct p2m_entry* entry);
#define machine_to_phys_mapping	mpt_table

#define INVALID_M2P_ENTRY        (~0UL)
#define VALID_M2P(_e)            (!((_e) & (1UL<<63)))

#define set_gpfn_from_mfn(mfn, pfn) (machine_to_phys_mapping[(mfn)] = (pfn))
#define get_gpfn_from_mfn(mfn)      (machine_to_phys_mapping[(mfn)])

/* If pmt table is provided by control pannel later, we need __get_user
* here. However if it's allocated by HV, we should access it directly
*/

#define mfn_to_gmfn(_d, mfn)			\
    get_gpfn_from_mfn(mfn)

#define gmfn_to_mfn(_d, gpfn)			\
    gmfn_to_mfn_foreign((_d), (gpfn))

#define __gpfn_invalid(_d, gpfn)			\
	(lookup_domain_mpa((_d), ((gpfn)<<PAGE_SHIFT), NULL) == INVALID_MFN)

#define __gmfn_valid(_d, gpfn)	!__gpfn_invalid(_d, gpfn)

#define __gpa_to_mpa(_d, gpa)   \
    ((gmfn_to_mfn((_d),(gpa)>>PAGE_SHIFT)<<PAGE_SHIFT)|((gpa)&~PAGE_MASK))

#define __mpa_to_gpa(madr) \
    ((get_gpfn_from_mfn((madr) >> PAGE_SHIFT) << PAGE_SHIFT) | \
    ((madr) & ~PAGE_MASK))

/* Internal use only: returns 0 in case of bad address.  */
extern unsigned long paddr_to_maddr(unsigned long paddr);

/* Arch-specific portion of memory_op hypercall. */
long arch_memory_op(int op, XEN_GUEST_HANDLE(void) arg);

int steal_page(
    struct domain *d, struct page_info *page, unsigned int memflags);
int donate_page(
    struct domain *d, struct page_info *page, unsigned int memflags);

#define domain_clamp_alloc_bitsize(d, b) (b)

unsigned long domain_get_maximum_gpfn(struct domain *d);

extern struct domain *dom_xen, *dom_io;	/* for vmcoreinfo */

#endif /* __ASM_IA64_MM_H__ */

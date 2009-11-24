/******************************************************************************
 * include/asm-x86/paging.h
 *
 * physical-to-machine mappings for automatically-translated domains.
 *
 * Copyright (c) 2007 Advanced Micro Devices (Wei Huang)
 * Parts of this code are Copyright (c) 2006-2007 by XenSource Inc.
 * Parts of this code are Copyright (c) 2006 by Michael A Fetterman
 * Parts based on earlier work by Michael A Fetterman, Ian Pratt et al.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef _XEN_P2M_H
#define _XEN_P2M_H

#include <xen/config.h>
#include <xen/paging.h>

/*
 * The phys_to_machine_mapping maps guest physical frame numbers 
 * to machine frame numbers.  It only exists for paging_mode_translate 
 * guests. It is organised in page-table format, which:
 *
 * (1) allows us to use it directly as the second pagetable in hardware-
 *     assisted paging and (hopefully) iommu support; and 
 * (2) lets us map it directly into the guest vcpus' virtual address space 
 *     as a linear pagetable, so we can read and write it easily.
 *
 * For (2) we steal the address space that would have normally been used
 * by the read-only MPT map in a non-translated guest.  (For 
 * paging_mode_external() guests this mapping is in the monitor table.)
 */
#define phys_to_machine_mapping ((l1_pgentry_t *)RO_MPT_VIRT_START)

#ifdef __x86_64__
#define HAVE_GRANT_MAP_P2M
#endif

/*
 * The upper levels of the p2m pagetable always contain full rights; all 
 * variation in the access control bits is made in the level-1 PTEs.
 * 
 * In addition to the phys-to-machine translation, each p2m PTE contains
 * *type* information about the gfn it translates, helping Xen to decide
 * on the correct course of action when handling a page-fault to that
 * guest frame.  We store the type in the "available" bits of the PTEs
 * in the table, which gives us 8 possible types on 32-bit systems.
 * Further expansions of the type system will only be supported on
 * 64-bit Xen.
 */
typedef enum {
    p2m_invalid = 0,            /* Nothing mapped here */
    p2m_ram_rw = 1,             /* Normal read/write guest RAM */
    p2m_ram_logdirty = 2,       /* Temporarily read-only for log-dirty */
    p2m_ram_ro = 3,             /* Read-only; writes are silently dropped */
    p2m_mmio_dm = 4,            /* Reads and write go to the device model */
    p2m_mmio_direct = 5,        /* Read/write mapping of genuine MMIO area */
    p2m_populate_on_demand = 6, /* Place-holder for empty memory */

    /* Note that these can only be used if HAVE_GRANT_MAP_P2M is
       defined.  They get defined anyway so as to avoid lots of
       #ifdef's everywhere else. */
    p2m_grant_map_rw = 7,       /* Read/write grant mapping */
    p2m_grant_map_ro = 8,       /* Read-only grant mapping */
} p2m_type_t;

typedef enum {
    p2m_query = 0,              /* Do not populate a PoD entries      */
    p2m_alloc = 1,              /* Automatically populate PoD entries */
    p2m_guest = 2,              /* Guest demand-fault; implies alloc  */
} p2m_query_t;

/* We use bitmaps and maks to handle groups of types */
#define p2m_to_mask(_t) (1UL << (_t))

/* RAM types, which map to real machine frames */
#define P2M_RAM_TYPES (p2m_to_mask(p2m_ram_rw)          \
                       | p2m_to_mask(p2m_ram_logdirty)  \
                       | p2m_to_mask(p2m_ram_ro))

/* Grant mapping types, which map to a real machine frame in another
 * VM */
#define P2M_GRANT_TYPES (p2m_to_mask(p2m_grant_map_rw)  \
                         | p2m_to_mask(p2m_grant_map_ro) )

/* MMIO types, which don't have to map to anything in the frametable */
#define P2M_MMIO_TYPES (p2m_to_mask(p2m_mmio_dm)        \
                        | p2m_to_mask(p2m_mmio_direct))

/* Read-only types, which must have the _PAGE_RW bit clear in their PTEs */
#define P2M_RO_TYPES (p2m_to_mask(p2m_ram_logdirty)     \
                      | p2m_to_mask(p2m_ram_ro)         \
                      | p2m_to_mask(p2m_grant_map_ro) )

#define P2M_MAGIC_TYPES (p2m_to_mask(p2m_populate_on_demand))

/* Useful predicates */
#define p2m_is_ram(_t) (p2m_to_mask(_t) & P2M_RAM_TYPES)
#define p2m_is_mmio(_t) (p2m_to_mask(_t) & P2M_MMIO_TYPES)
#define p2m_is_readonly(_t) (p2m_to_mask(_t) & P2M_RO_TYPES)
#define p2m_is_magic(_t) (p2m_to_mask(_t) & P2M_MAGIC_TYPES)
#define p2m_is_grant(_t) (p2m_to_mask(_t) & P2M_GRANT_TYPES)
/* Grant types are *not* considered valid, because they can be
   unmapped at any time and, unless you happen to be the shadow or p2m
   implementations, there's no way of synchronising against that. */
#define p2m_is_valid(_t) (p2m_to_mask(_t) & (P2M_RAM_TYPES | P2M_MMIO_TYPES))
#define p2m_has_emt(_t)  (p2m_to_mask(_t) & (P2M_RAM_TYPES | p2m_to_mask(p2m_mmio_direct)))

/* Populate-on-demand */
#define POPULATE_ON_DEMAND_MFN  (1<<9)
#define POD_PAGE_ORDER 9


struct p2m_domain {
    /* Lock that protects updates to the p2m */
    spinlock_t         lock;
    int                locker;   /* processor which holds the lock */
    const char        *locker_function; /* Func that took it */

    /* Pages used to construct the p2m */
    struct page_list_head pages;

    /* Functions to call to get or free pages for the p2m */
    struct page_info * (*alloc_page  )(struct domain *d);
    void               (*free_page   )(struct domain *d,
                                       struct page_info *pg);
    int                (*set_entry   )(struct domain *d, unsigned long gfn,
                                       mfn_t mfn, unsigned int page_order,
                                       p2m_type_t p2mt);
    mfn_t              (*get_entry   )(struct domain *d, unsigned long gfn,
                                       p2m_type_t *p2mt,
                                       p2m_query_t q);
    mfn_t              (*get_entry_current)(unsigned long gfn,
                                            p2m_type_t *p2mt,
                                            p2m_query_t q);
    void               (*change_entry_type_global)(struct domain *d,
                                                   p2m_type_t ot,
                                                   p2m_type_t nt);

    /* Highest guest frame that's ever been mapped in the p2m */
    unsigned long max_mapped_pfn;

    /* Populate-on-demand variables
     * NB on locking.  {super,single,count} are
     * covered by d->page_alloc_lock, since they're almost always used in
     * conjunction with that functionality.  {entry_count} is covered by
     * the domain p2m lock, since it's almost always used in conjunction
     * with changing the p2m tables.
     *
     * At this point, both locks are held in two places.  In both,
     * the order is [p2m,page_alloc]:
     * + p2m_pod_decrease_reservation() calls p2m_pod_cache_add(),
     *   which grabs page_alloc
     * + p2m_pod_demand_populate() grabs both; the p2m lock to avoid
     *   double-demand-populating of pages, the page_alloc lock to
     *   protect moving stuff from the PoD cache to the domain page list.
     */
    struct {
        struct page_list_head super,   /* List of superpages                */
                         single;       /* Non-super lists                   */
        int              count,        /* # of pages in cache lists         */
                         entry_count;  /* # of pages in p2m marked pod      */
        unsigned         reclaim_super; /* Last gpfn of a scan */
        unsigned         reclaim_single; /* Last gpfn of a scan */
        unsigned         max_guest;    /* gpfn of max guest demand-populate */
    } pod;
};

/*
 * The P2M lock.  This protects all updates to the p2m table.
 * Updates are expected to be safe against concurrent reads,
 * which do *not* require the lock.
 *
 * Locking discipline: always acquire this lock before the shadow or HAP one
 */

#define p2m_lock_init(_p2m)                     \
    do {                                        \
        spin_lock_init(&(_p2m)->lock);          \
        (_p2m)->locker = -1;                    \
        (_p2m)->locker_function = "nobody";     \
    } while (0)

#define p2m_lock(_p2m)                                          \
    do {                                                        \
        if ( unlikely((_p2m)->locker == current->processor) )   \
        {                                                       \
            printk("Error: p2m lock held by %s\n",              \
                   (_p2m)->locker_function);                    \
            BUG();                                              \
        }                                                       \
        spin_lock(&(_p2m)->lock);                               \
        ASSERT((_p2m)->locker == -1);                           \
        (_p2m)->locker = current->processor;                    \
        (_p2m)->locker_function = __func__;                     \
    } while (0)

#define p2m_unlock(_p2m)                                \
    do {                                                \
        ASSERT((_p2m)->locker == current->processor);   \
        (_p2m)->locker = -1;                            \
        (_p2m)->locker_function = "nobody";             \
        spin_unlock(&(_p2m)->lock);                     \
    } while (0)

#define p2m_locked_by_me(_p2m)                            \
    (current->processor == (_p2m)->locker)


/* Extract the type from the PTE flags that store it */
static inline p2m_type_t p2m_flags_to_type(unsigned long flags)
{
    /* Type is stored in the "available" bits */
#ifdef __x86_64__
    return (flags >> 9) & 0x3fff;
#else
    return (flags >> 9) & 0x7;
#endif
}

/* Read the current domain's p2m table.  Do not populate PoD pages. */
static inline mfn_t gfn_to_mfn_type_current(unsigned long gfn, p2m_type_t *t,
                                            p2m_query_t q)
{
    return current->domain->arch.p2m->get_entry_current(gfn, t, q);
}

/* Read another domain's P2M table, mapping pages as we go.
 * Do not populate PoD pages. */
static inline
mfn_t gfn_to_mfn_type_foreign(struct domain *d, unsigned long gfn, p2m_type_t *t,
                              p2m_query_t q)
{
    return d->arch.p2m->get_entry(d, gfn, t, q);
}

/* General conversion function from gfn to mfn */
static inline mfn_t _gfn_to_mfn_type(struct domain *d,
                                     unsigned long gfn, p2m_type_t *t,
                                     p2m_query_t q)
{
    if ( !paging_mode_translate(d) )
    {
        /* Not necessarily true, but for non-translated guests, we claim
         * it's the most generic kind of memory */
        *t = p2m_ram_rw;
        return _mfn(gfn);
    }
    if ( likely(current->domain == d) )
        return gfn_to_mfn_type_current(gfn, t, q);
    else
        return gfn_to_mfn_type_foreign(d, gfn, t, q);
}

#define gfn_to_mfn(d, g, t) _gfn_to_mfn_type((d), (g), (t), p2m_alloc)
#define gfn_to_mfn_query(d, g, t) _gfn_to_mfn_type((d), (g), (t), p2m_query)
#define gfn_to_mfn_guest(d, g, t) _gfn_to_mfn_type((d), (g), (t), p2m_guest)

#define gfn_to_mfn_current(g, t) gfn_to_mfn_type_current((g), (t), p2m_alloc)
#define gfn_to_mfn_foreign(d, g, t) gfn_to_mfn_type_foreign((d), (g), (t), p2m_alloc)

/* Compatibility function exporting the old untyped interface */
static inline unsigned long gmfn_to_mfn(struct domain *d, unsigned long gpfn)
{
    mfn_t mfn;
    p2m_type_t t;
    mfn = gfn_to_mfn(d, gpfn, &t);
    if ( p2m_is_valid(t) )
        return mfn_x(mfn);
    return INVALID_MFN;
}

/* General conversion function from mfn to gfn */
static inline unsigned long mfn_to_gfn(struct domain *d, mfn_t mfn)
{
    if ( paging_mode_translate(d) )
        return get_gpfn_from_mfn(mfn_x(mfn));
    else
        return mfn_x(mfn);
}

/* Init the datastructures for later use by the p2m code */
int p2m_init(struct domain *d);

/* Allocate a new p2m table for a domain. 
 *
 * The alloc_page and free_page functions will be used to get memory to
 * build the p2m, and to release it again at the end of day. 
 *
 * Returns 0 for success or -errno. */
int p2m_alloc_table(struct domain *d,
                    struct page_info * (*alloc_page)(struct domain *d),
                    void (*free_page)(struct domain *d, struct page_info *pg));

/* Return all the p2m resources to Xen. */
void p2m_teardown(struct domain *d);
void p2m_final_teardown(struct domain *d);

/* Dump PoD information about the domain */
void p2m_pod_dump_data(struct domain *d);

/* Move all pages from the populate-on-demand cache to the domain page_list
 * (usually in preparation for domain destruction) */
void p2m_pod_empty_cache(struct domain *d);

/* Set populate-on-demand cache size so that the total memory allocated to a
 * domain matches target */
int p2m_pod_set_mem_target(struct domain *d, unsigned long target);

/* Call when decreasing memory reservation to handle PoD entries properly.
 * Will return '1' if all entries were handled and nothing more need be done.*/
int
p2m_pod_decrease_reservation(struct domain *d,
                             xen_pfn_t gpfn,
                             unsigned int order);

/* Called by p2m code when demand-populating a PoD page */
int
p2m_pod_demand_populate(struct domain *d, unsigned long gfn,
                        unsigned int order,
                        p2m_query_t q);

/* Add a page to a domain's p2m table */
int guest_physmap_add_entry(struct domain *d, unsigned long gfn,
                            unsigned long mfn, unsigned int page_order, 
                            p2m_type_t t);

/* Set a p2m range as populate-on-demand */
int guest_physmap_mark_populate_on_demand(struct domain *d, unsigned long gfn,
                                          unsigned int order);

/* Untyped version for RAM only, for compatibility 
 *
 * Return 0 for success
 */
static inline int guest_physmap_add_page(struct domain *d, unsigned long gfn,
                                         unsigned long mfn,
                                         unsigned int page_order)
{
    return guest_physmap_add_entry(d, gfn, mfn, page_order, p2m_ram_rw);
}

/* Remove a page from a domain's p2m table */
void guest_physmap_remove_page(struct domain *d, unsigned long gfn,
                               unsigned long mfn, unsigned int page_order);

/* Change types across all p2m entries in a domain */
void p2m_change_type_global(struct domain *d, p2m_type_t ot, p2m_type_t nt);
void p2m_change_entry_type_global(struct domain *d, p2m_type_t ot, p2m_type_t nt);

/* Compare-exchange the type of a single p2m entry */
p2m_type_t p2m_change_type(struct domain *d, unsigned long gfn,
                           p2m_type_t ot, p2m_type_t nt);

/* Set mmio addresses in the p2m table (for pass-through) */
int set_mmio_p2m_entry(struct domain *d, unsigned long gfn, mfn_t mfn);
int clear_mmio_p2m_entry(struct domain *d, unsigned long gfn);

#endif /* _XEN_P2M_H */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 */

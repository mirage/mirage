/******************************************************************************
 * tlb_track.h
 *
 * Copyright (c) 2006 Isaku Yamahata <yamahata at valinux co jp>
 *                    VA Linux Systems Japan K.K.
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
 *
 */

#ifndef __TLB_TRACK_H__
#define __TLB_TRACK_H__

#ifdef CONFIG_XEN_IA64_TLB_TRACK

#include <xen/sched.h>
#include <xen/perfc.h>
#include <asm/domain.h>
#include <xen/list.h>
#include <asm/p2m_entry.h>
#include <asm/vcpumask.h>

// TODO: compact this structure.
struct tlb_track_entry {
    struct list_head   list;

    volatile pte_t*     ptep;           // corresponding p2m entry

    /* XXX should we use TR_ENTRY? */
    pte_t               pte_val;        // mfn and other flags
                                        // pte_val.p = 1:
                                        //   tlb entry is inserted.
                                        // pte_val.p = 0: 
                                        //   once tlb entry is inserted, so
                                        //   this entry is created. But tlb
                                        //   purge is isseued, so this
                                        //   virtual address need not to be
                                        //   purged.
    unsigned long       vaddr;          // virtual address
    unsigned long       rid;            // rid

    cpumask_t           pcpu_dirty_mask;
    vcpumask_t          vcpu_dirty_mask;

#ifdef CONFIG_TLB_TRACK_CNT
#define TLB_TRACK_CNT_FORCE_MANY        256 /* XXX how many? */
    unsigned long       cnt;
#endif
};

struct tlb_track {

/* see __gnttab_map_grant_ref()
   A domain can map granted-page up to MAPTRACK_MAX_ENTRIES pages. */
#define TLB_TRACK_LIMIT_ENTRIES                                     \
    (MAPTRACK_MAX_ENTRIES * (PAGE_SIZE / sizeof(struct tlb_track)))

    spinlock_t                  free_list_lock;
    struct list_head            free_list;
    unsigned int                limit;
    unsigned int                num_entries;
    unsigned int                num_free;
    struct page_list_head       page_list;

    /* XXX hash table size */
    spinlock_t                  hash_lock;
    unsigned int                hash_size;
    unsigned int                hash_shift;
    unsigned int                hash_mask;
    struct list_head*           hash;
};

int tlb_track_create(struct domain* d);
void tlb_track_destroy(struct domain* d);

void tlb_track_free_entry(struct tlb_track* tlb_track,
                          struct tlb_track_entry* entry);

void
__vcpu_tlb_track_insert_or_dirty(struct vcpu *vcpu, unsigned long vaddr,
                                 struct p2m_entry* entry);
static inline void
vcpu_tlb_track_insert_or_dirty(struct vcpu *vcpu, unsigned long vaddr,
                               struct p2m_entry* entry)
{
    /* optimization.
       non-tracking pte is most common. */
    perfc_incr(tlb_track_iod);
    if (!pte_tlb_tracking(entry->used)) {
        perfc_incr(tlb_track_iod_not_tracked);
        return;
    }

    __vcpu_tlb_track_insert_or_dirty(vcpu, vaddr, entry);
}


/* return value
 * NULL if this entry is used
 * entry if this entry isn't used
 */
enum TLB_TRACK_RET {
    TLB_TRACK_NOT_TRACKED,
    TLB_TRACK_NOT_FOUND,
    TLB_TRACK_FOUND,
    TLB_TRACK_MANY,
    TLB_TRACK_AGAIN,
};
typedef enum TLB_TRACK_RET TLB_TRACK_RET_T;

TLB_TRACK_RET_T
tlb_track_search_and_remove(struct tlb_track* tlb_track, 
                            volatile pte_t* ptep, pte_t old_pte, 
                            struct tlb_track_entry** entryp);

void
__tlb_track_entry_printf(const char* func, int line,
                         const struct tlb_track_entry* entry);
#define tlb_track_entry_printf(entry)                       \
    __tlb_track_entry_printf(__func__, __LINE__, (entry))
#else
//define as nop
#define tlb_track_create(d)                     do { } while (0)
#define tlb_track_destroy(d)                    do { } while (0)
#define tlb_track_free_entry(tlb_track, entry)  do { } while (0)
#define vcpu_tlb_track_insert_or_dirty(vcpu, vaddr, entry)      \
                                                do { } while (0)
#define tlb_track_search_and_remove(tlb_track, ptep, old_pte, entryp)   \
                                                do { } while (0)
#define tlb_track_entry_printf(entry)           do { } while (0)
#endif /* CONFIG_XEN_IA64_TLB_TRACK */

#endif /* __TLB_TRACK_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

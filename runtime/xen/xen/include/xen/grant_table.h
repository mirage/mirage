/******************************************************************************
 * include/xen/grant_table.h
 * 
 * Mechanism for granting foreign access to page frames, and receiving
 * page-ownership transfers.
 * 
 * Copyright (c) 2004-2005 K A Fraser
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

#ifndef __XEN_GRANT_TABLE_H__
#define __XEN_GRANT_TABLE_H__

#include <xen/config.h>
#include <public/grant_table.h>
#include <asm/grant_table.h>

/* Active grant entry - used for shadowing GTF_permit_access grants. */
struct active_grant_entry {
    u32           pin;    /* Reference count information.             */
    domid_t       domid;  /* Domain being granted access.             */
    domid_t       trans_dom;
    uint32_t      trans_gref;
    unsigned long frame;  /* Frame being granted.                     */
    unsigned long gfn;    /* Guest's idea of the frame being granted. */
    unsigned      is_sub_page:1; /* True if this is a sub-page grant. */
    unsigned      start:15; /* For sub-page grants, the start offset
                               in the page.                           */
    unsigned      length:16; /* For sub-page grants, the length of the
                                grant.                                */
};

 /* Count of writable host-CPU mappings. */
#define GNTPIN_hstw_shift    (0)
#define GNTPIN_hstw_inc      (1 << GNTPIN_hstw_shift)
#define GNTPIN_hstw_mask     (0xFFU << GNTPIN_hstw_shift)
 /* Count of read-only host-CPU mappings. */
#define GNTPIN_hstr_shift    (8)
#define GNTPIN_hstr_inc      (1 << GNTPIN_hstr_shift)
#define GNTPIN_hstr_mask     (0xFFU << GNTPIN_hstr_shift)
 /* Count of writable device-bus mappings. */
#define GNTPIN_devw_shift    (16)
#define GNTPIN_devw_inc      (1 << GNTPIN_devw_shift)
#define GNTPIN_devw_mask     (0xFFU << GNTPIN_devw_shift)
 /* Count of read-only device-bus mappings. */
#define GNTPIN_devr_shift    (24)
#define GNTPIN_devr_inc      (1 << GNTPIN_devr_shift)
#define GNTPIN_devr_mask     (0xFFU << GNTPIN_devr_shift)

#ifndef DEFAULT_MAX_NR_GRANT_FRAMES /* to allow arch to override */
/* Default maximum size of a grant table. [POLICY] */
#define DEFAULT_MAX_NR_GRANT_FRAMES   32
#endif
#ifndef max_nr_grant_frames /* to allow arch to override */
/* The maximum size of a grant table. */
extern unsigned int max_nr_grant_frames;
#endif

/*
 * Tracks a mapping of another domain's grant reference. Each domain has a
 * table of these, indexes into which are returned as a 'mapping handle'.
 */
struct grant_mapping {
    u32      ref;           /* grant ref */
    u16      flags;         /* 0-4: GNTMAP_* ; 5-15: unused */
    domid_t  domid;         /* granting domain */
};

/* Fairly arbitrary. [POLICY] */
#define MAPTRACK_MAX_ENTRIES 16384

/* Per-domain grant information. */
struct grant_table {
    /* Table size. Number of frames shared with guest */
    unsigned int          nr_grant_frames;
    /* Shared grant table (see include/public/grant_table.h). */
    union {
        void **shared_raw;
        struct grant_entry_v1 **shared_v1;
        union grant_entry_v2 **shared_v2;
    };
    /* Number of grant status frames shared with guest (for version 2) */
    unsigned int          nr_status_frames;
    /* State grant table (see include/public/grant_table.h). */
    grant_status_t       **status;
    /* Active grant table. */
    struct active_grant_entry **active;
    /* Mapping tracking table. */
    struct grant_mapping **maptrack;
    unsigned int          maptrack_head;
    unsigned int          maptrack_limit;
    /* Lock protecting updates to active and shared grant tables. */
    spinlock_t            lock;
    /* The defined versions are 1 and 2.  Set to 0 if we don't know
       what version to use yet. */
    unsigned              gt_version;
};

/* Create/destroy per-domain grant table context. */
int grant_table_create(
    struct domain *d);
void grant_table_destroy(
    struct domain *d);

/* Domain death release of granted mappings of other domains' memory. */
void
gnttab_release_mappings(
    struct domain *d);

/* Increase the size of a domain's grant table.
 * Caller must hold d's grant table lock.
 */
int
gnttab_grow_table(struct domain *d, unsigned int req_nr_frames);

/* Number of grant table frames. Caller must hold d's grant table lock. */
static inline unsigned int nr_grant_frames(struct grant_table *gt)
{
    return gt->nr_grant_frames;
}

/* Number of status grant table frames. Caller must hold d's gr. table lock.*/
static inline unsigned int nr_status_frames(struct grant_table *gt)
{
    return gt->nr_status_frames;
}

#define GRANT_STATUS_PER_PAGE (PAGE_SIZE / sizeof(grant_status_t))
#define GRANT_PER_PAGE (PAGE_SIZE / sizeof(grant_entry_v2_t))
/* Number of grant table status entries. Caller must hold d's gr. table lock.*/
static inline unsigned int grant_to_status_frames(int grant_frames)
{
    return (grant_frames * GRANT_PER_PAGE + GRANT_STATUS_PER_PAGE - 1) /
        GRANT_STATUS_PER_PAGE;
}

static inline unsigned int
num_act_frames_from_sha_frames(const unsigned int num)
{
    /* How many frames are needed for the active grant table,
     * given the size of the shared grant table? */
    unsigned act_per_page = PAGE_SIZE / sizeof(struct active_grant_entry);
    unsigned sha_per_page = PAGE_SIZE / sizeof(grant_entry_v1_t);
    unsigned num_sha_entries = num * sha_per_page;
    unsigned num_act_frames =
        (num_sha_entries + (act_per_page-1)) / act_per_page;
    return num_act_frames;
}

static inline unsigned int
nr_active_grant_frames(struct grant_table *gt)
{
    return num_act_frames_from_sha_frames(nr_grant_frames(gt));
}

#endif /* __XEN_GRANT_TABLE_H__ */

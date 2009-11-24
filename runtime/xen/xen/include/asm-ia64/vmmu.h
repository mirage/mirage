
/* -*-  Mode:C; c-basic-offset:4; tab-width:4; indent-tabs-mode:nil -*- */
/*
 * vmmu.h: virtual memory management unit related APIs and data structure.
 * Copyright (c) 2004, Intel Corporation.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307 USA.
 *
 *  Yaozu Dong (Eddie Dong) (Eddie.dong@intel.com)
 */

#ifndef XEN_TLBthash_H
#define XEN_TLBthash_H

#define     MAX_CCN_DEPTH       (15)       // collision chain depth
#define     DEFAULT_VTLB_SZ     (14) // 16K hash + 16K c-chain for VTLB
#define     DEFAULT_VHPT_SZ     (23) // 8M hash + 8M c-chain for VHPT
#define     VTLB(v,_x)          (v->arch.vtlb._x)
#define     VHPT(v,_x)          (v->arch.vhpt._x)

#ifndef __ASSEMBLY__

#include <xen/config.h>
#include <xen/types.h>
#include <public/xen.h>
#include <asm/tlb.h>
#include <asm/regionreg.h>
#include <asm/vmx_mm_def.h>
#include <asm/bundle.h>

enum {
    ISIDE_TLB=0,
    DSIDE_TLB=1
};
#endif /* __ASSEMBLY__ */

#define VTLB_PTE_P_BIT      0
#define VTLB_PTE_P         (1UL<<VTLB_PTE_P_BIT)

#define ITIR_RV_MASK            (((1UL<<32)-1)<<32 | 0x3)
#define PAGE_FLAGS_RV_MASK      (0x2 | (0x3UL<<50)|(((1UL<<11)-1)<<53))
#define PAGE_FLAGS_AR_PL_MASK   ((0x7UL<<9)|(0x3UL<<7))

#ifndef __ASSEMBLY__
typedef struct thash_data {
    union {
        struct {
            u64 p    :  1; // 0
            u64 rv1  :  1; // 1
            u64 ma   :  3; // 2-4
            u64 a    :  1; // 5
            u64 d    :  1; // 6
            u64 pl   :  2; // 7-8
            u64 ar   :  3; // 9-11
            u64 ppn  : 38; // 12-49
            u64 rv2  :  2; // 50-51
            u64 ed   :  1; // 52
            u64 ig1  :  3; // 53-63
        };
        u64 page_flags;
    };                  // same for VHPT and TLB

    union {
        struct {
            u64 rv3  :  2; // 0-1
            u64 ps   :  6; // 2-7
            u64 key  : 24; // 8-31
            u64 rv4  : 32; // 32-63
        };
        u64 itir;
    };
    union {
        struct {        // For TLB
            u64 ig2  :  12; // 0-11
            u64 vpn  :  49; // 12-60
            u64 vrn  :   3; // 61-63
        };
        u64 vadr;
        u64 ifa;
        struct {        // For VHPT
            u64 tag  :  63; // 0-62
            u64 ti   :  1;  // 63, invalid entry for VHPT
        };
        u64  etag;      // extended tag for VHPT
    };
    union {
        struct thash_data *next;
        u64  rid;  // only used in guest TR
//        u64  tr_idx;
    };
} thash_data_t;

#define INVALIDATE_VHPT_HEADER(hdata)   \
{   ((hdata)->page_flags)=0;            \
    ((hdata)->itir)=PAGE_SHIFT<<2;      \
    ((hdata)->etag)=1UL<<63;            \
    ((hdata)->next)=0;}

#define INVALIDATE_TLB_HEADER(hash)   INVALIDATE_VHPT_HEADER(hash)

#define INVALIDATE_HASH_HEADER(hcb,hash)    INVALIDATE_VHPT_HEADER(hash)

#define INVALID_VHPT(hdata)     ((hdata)->ti)
#define INVALID_TLB(hdata)      ((hdata)->ti)
#define INVALID_TR(hdata)      (!(hdata)->p)
#define INVALID_ENTRY(hcb, hdata)       INVALID_VHPT(hdata)

static inline u64 thash_translate(thash_data_t *hdata, u64 vadr)
{
    int ps = hdata->ps;
    return (hdata->ppn >> (ps - 12) << ps) | (vadr & ((1UL << ps) - 1));
}

typedef struct thash_cb {
    /* THASH base information */
    thash_data_t    *hash; // hash table pointer, aligned at thash_sz.
    u64     hash_sz;        // size of above data.
    void    *cch_buf;       // base address of collision chain.
    u64     cch_sz;         // size of above data.
    u64     cch_free_idx;   // index of free entry.
    thash_data_t *cch_freelist;
    PTA     pta;
} thash_cb_t;

/*
 * Allocate and initialize internal control data before service.
 */
extern int thash_alloc(thash_cb_t *hcb, u64 sz, char *what);

extern void thash_free(thash_cb_t *hcb);

/*
 * Insert an entry to hash table. 
 *    NOTES:
 *      1: TLB entry may be TR, TC or Foreign Map. For TR entry,
 *         itr[]/dtr[] need to be updated too.
 *      2: Inserting to collision chain may trigger recycling if
 *         the buffer for collision chain is empty.
 *      3: The new entry is inserted at the hash table.
 *         (I.e. head of the collision chain)
 *      4: Return the entry in hash table or collision chain.
 *
 */
//extern void thash_insert(thash_cb_t *hcb, thash_data_t *entry, u64 va);
//extern void thash_tr_insert(thash_cb_t *hcb, thash_data_t *entry, u64 va, int idx);
extern int vtr_find_overlap(struct vcpu *vcpu, u64 va, u64 ps, int is_data);

/*
 * Find and purge overlap entries in hash table and its collision chain.
 *    PARAS:
 *      1: in: TLB format entry, rid:ps must be same with vrr[].
 *             rid, va & ps identify the address space for purge
 *      2: section can be combination of TR, TC and FM. (thash_SECTION_XX)
 *      3: cl means I side or D side.
 *    NOTES:
 *
 */
extern void thash_purge_entries(struct vcpu *v, u64 va, u64 ps);
extern void thash_purge_entries_remote(struct vcpu *v, u64 va, u64 ps);
extern int thash_purge_and_insert(struct vcpu *v, u64 pte, u64 itir, u64 ifa, int type);

/*
 * Purge all TCs or VHPT entries including those in Hash table.
 *
 */
extern void thash_purge_all(struct vcpu *v);
extern void vmx_vcpu_flush_vtlb_all(struct vcpu *v);

/*
 * Lookup the hash table and its collision chain to find an entry
 * covering this address rid:va.
 *
 */
extern thash_data_t *vtlb_lookup(struct vcpu *v,u64 va,int is_data);


extern int init_domain_tlb(struct vcpu *v);
extern void free_domain_tlb(struct vcpu *v);
extern thash_data_t * vhpt_lookup(u64 va);
extern unsigned long fetch_code(struct vcpu *vcpu, u64 gip, IA64_BUNDLE *pbundle);
extern void emulate_io_inst(struct vcpu *vcpu, u64 padr, u64 ma, u64 iot);
extern void emulate_io_update(struct vcpu *vcpu, u64 word, u64 d, u64 d1);
extern int vhpt_enabled(struct vcpu *vcpu, uint64_t vadr, vhpt_ref_t ref);
extern void thash_vhpt_insert(struct vcpu *v, u64 pte, u64 itir, u64 ifa,
                              int type);
extern u64 guest_vhpt_lookup(u64 iha, u64 *pte);
extern int vhpt_access_rights_fixup(struct vcpu *v, u64 ifa, int is_data);

/*
 *  Purge machine tlb.
 *  INPUT
 *      rr:     guest rr.
 *      va:     only bits 0:60 is valid
 *      size:   bits format (1<<size) for the address range to purge.
 *
 */
static inline void machine_tlb_purge(u64 va, u64 ps)
{
    ia64_ptcl(va, ps << 2);
}

static inline void vmx_vcpu_set_tr (thash_data_t *trp, u64 pte, u64 itir, u64 va, u64 rid)
{
    trp->page_flags = pte;
    trp->itir = itir;
    trp->vadr = va;
    trp->rid = rid;
}

#endif  /* __ASSEMBLY__ */

#endif  /* XEN_TLBthash_H */

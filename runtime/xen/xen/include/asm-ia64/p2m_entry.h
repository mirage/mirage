/******************************************************************************
 * p2m_entry.h
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

#ifndef __ASM_P2M_ENTRY_H__
#define __ASM_P2M_ENTRY_H__

#include <asm/pgtable.h>

struct p2m_entry {
#define P2M_PTE_ALWAYS_RETRY	((volatile pte_t*) -1)
    volatile pte_t*     ptep;
    pte_t               used;
};

static inline void
p2m_entry_set(struct p2m_entry* entry, volatile pte_t* ptep, pte_t used)
{
    entry->ptep = ptep;
    entry->used = used;
}

static inline void
p2m_entry_set_retry(struct p2m_entry* entry)
{
    entry->ptep = P2M_PTE_ALWAYS_RETRY;
}

static inline int
p2m_entry_retry(struct p2m_entry* entry)
{
    /* XXX see lookup_domain_pte().
       NULL is set for invalid gpaddr for the time being. */
    if (entry->ptep == NULL)
        return 0;

    if (entry->ptep == P2M_PTE_ALWAYS_RETRY)
        return 1;

#ifdef CONFIG_XEN_IA64_TLB_TRACK
    return ((pte_val(*entry->ptep) & ~_PAGE_TLB_TRACK_MASK) !=
            (pte_val(entry->used) & ~_PAGE_TLB_TRACK_MASK));
#else
    return (pte_val(*entry->ptep) != pte_val(entry->used));
#endif
}

#endif // __ASM_P2M_ENTRY_H__

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

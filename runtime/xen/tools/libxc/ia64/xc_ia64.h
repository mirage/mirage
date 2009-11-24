/*
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
 * Foundation, 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * Copyright (c) 2007 Isaku Yamahata <yamahata at valinux co jp>
 *                    VA Linux Systems Japan K.K.
 *
 */

#ifndef _XC_IA64_H_
#define _XC_IA64_H_

int xc_ia64_copy_memmap(int xc_handle, uint32_t domid,
                        shared_info_t *live_shinfo,
                        xen_ia64_memmap_info_t **memmap_info_p,
                        unsigned long *memmap_info_num_pages_p);

struct xen_ia64_p2m_table {
    unsigned long size;
    unsigned long *p2m;
};

void xc_ia64_p2m_init(struct xen_ia64_p2m_table *p2m_table);
int xc_ia64_p2m_map(struct xen_ia64_p2m_table *p2m_table, int xc_handle,
                    uint32_t domid, struct xen_ia64_memmap_info *memmap_info,
                    unsigned long flag);
void xc_ia64_p2m_unmap(struct xen_ia64_p2m_table *p2m_table);
int xc_ia64_p2m_present(struct xen_ia64_p2m_table *p2m_table,
                        unsigned long gpfn);
int xc_ia64_p2m_allocated(struct xen_ia64_p2m_table *p2m_table,
                          unsigned long gpfn);

unsigned long xc_ia64_p2m_mfn(struct xen_ia64_p2m_table *p2m_table,
                              unsigned long gpfn);


#endif /* _XC_IA64_H_ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

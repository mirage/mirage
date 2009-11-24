/******************************************************************************
 *
 * Copyright (c) 2007 Isaku Yamahata <yamahata at valinux co jp>
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
#ifndef __ASM_XEN_IA64_DOM_FW_UTILS_H__
#define __ASM_XEN_IA64_DOM_FW_UTILS_H__

uint32_t xen_ia64_version(struct domain *unused); 
int xen_ia64_fpswa_revision(struct domain *d, unsigned int *revision); 
int xen_ia64_is_vcpu_allocated(struct domain *d, uint32_t vcpu); 
int xen_ia64_is_running_on_sim(struct domain *unused);
int xen_ia64_is_dom0(struct domain *d);
void xen_ia64_set_convmem_end(struct domain *d, uint64_t convmem_end);
void dom_fw_copy_to(struct domain *d, unsigned long dest_gpaddr,
                    void *src, size_t size); 
void dom_fw_copy_from(void* dest, struct domain *d, unsigned long src_gpaddr,
                      size_t size); 

#endif /* __ASM_XEN_IA64_DOM_FW_UTILS_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

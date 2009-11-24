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

#ifndef XC_CORE_IA64_H
#define XC_CORE_IA64_H

#include "ia64/xc_ia64.h"

#define ELF_ARCH_DATA           ELFDATA2LSB
#define ELF_ARCH_MACHINE        EM_IA_64

struct xc_core_arch_context {
    size_t mapped_regs_size;
    int nr_vcpus;
    mapped_regs_t** mapped_regs;

    struct xen_ia64_p2m_table p2m_table;
};

void
xc_core_arch_context_init(struct xc_core_arch_context* arch_ctxt);
void
xc_core_arch_context_free(struct xc_core_arch_context* arch_ctxt);
int
xc_core_arch_context_get(struct xc_core_arch_context* arch_ctxt,
                         vcpu_guest_context_any_t* ctxt,
                         int xc_handle, uint32_t domid);
int
xc_core_arch_context_get_shdr(struct xc_core_arch_context* arch_ctxt, 
                              struct xc_core_section_headers *sheaders,
                              struct xc_core_strtab *strtab,
                              uint64_t *filesz, uint64_t offset);
int
xc_core_arch_context_dump(struct xc_core_arch_context* arch_ctxt,
                          void* args, dumpcore_rtn_t dump_rtn);

int
xc_core_arch_gpfn_may_present(struct xc_core_arch_context *arch_ctxt,
                              unsigned long pfn);

#endif /* XC_CORE_IA64_H */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

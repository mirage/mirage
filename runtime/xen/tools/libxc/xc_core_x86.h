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

#ifndef XC_CORE_X86_H
#define XC_CORE_X86_H

#define ELF_ARCH_DATA           ELFDATA2LSB
#define ELF_ARCH_MACHINE       (guest_width == 8 ? EM_X86_64 : EM_386)

struct xc_core_arch_context {
    /* nothing */
};

#define xc_core_arch_context_init(arch_ctxt)            do {} while (0)
#define xc_core_arch_context_free(arch_ctxt)            do {} while (0)
#define xc_core_arch_context_get(arch_ctxt, ctxt, xc_handle, domid) \
                                                                (0)
#define xc_core_arch_context_dump(arch_ctxt, args, dump_rtn)    (0)

int
xc_core_arch_gpfn_may_present(struct xc_core_arch_context *arch_ctxt,
                              unsigned long pfn);
static inline int
xc_core_arch_context_get_shdr(struct xc_core_arch_context *arch_ctxt, 
                              struct xc_core_section_headers *sheaders,
                              struct xc_core_strtab *strtab,
                              uint64_t *filesz, uint64_t offset)
{
    *filesz = 0;
    return 0;
}

#endif /* XC_CORE_X86_H */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

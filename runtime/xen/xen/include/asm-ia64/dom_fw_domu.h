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
#ifndef __ASM_IA64_DOM_FW_DOMU_H__
#define __ASM_IA64_DOM_FW_DOMU_H__

#include <asm/dom_fw_common.h>

void efi_systable_init_domu(struct fw_tables *tables);

int
complete_domu_memmap(domain_t *d,
                     struct fw_tables *tables,
                     unsigned long maxmem,
                     unsigned long memmap_info_pfn,
                     unsigned long reserved_size);

#endif /* __ASM_IA64_DOM_FW_DOMU_H__ */
/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */


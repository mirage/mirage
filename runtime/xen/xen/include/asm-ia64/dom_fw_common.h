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
#ifndef __ASM_IA64_DOM_FW_COMMON_H__
#define __ASM_IA64_DOM_FW_COMMON_H__

#ifdef __XEN__
#include <linux/efi.h>
#include <asm/sal.h>
#include <xen/sched.h>
typedef struct domain domain_t;
#else
#include "xc_efi.h"
#include "ia64/sal.h"
#include "xg_private.h"
typedef struct xc_dom_image domain_t;

#define XENLOG_INFO     "info:"
#define XENLOG_WARNING	"Warning:"
#define XENLOG_GUEST	""
#define printk(fmt, args ...)	xc_dom_printf(fmt, ## args)

#define BUG_ON(p)	assert(!(p))
#define BUILD_BUG_ON(condition) ((void)sizeof(struct { int:-!!(condition); }))

//for sort in linux/sort.h.
#define sort(base, num, size, cmp, swap) qsort((base), (num), (size), (cmp))
#endif

#include <asm/fpswa.h>

#define ONE_MB          (1UL << 20)
#define FW_VENDOR       "X\0e\0n\0/\0i\0a\0\066\0\064\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"

#define NFUNCPTRS               16
#define NUM_EFI_SYS_TABLES      6

struct fw_tables {
    efi_system_table_t                  efi_systab;
    efi_runtime_services_t              efi_runtime;
    efi_config_table_t                  efi_tables[NUM_EFI_SYS_TABLES];

    struct ia64_sal_systab              sal_systab;
    struct ia64_sal_desc_entry_point    sal_ed;
    struct ia64_sal_desc_ap_wakeup      sal_wakeup;
    /* End of SAL descriptors.  Do not forget to update checkum bound.  */

    fpswa_interface_t                   fpswa_inf;
    unsigned long                       func_ptrs[2*NFUNCPTRS];
    struct xen_sal_data                 sal_data;
    unsigned char                       fw_vendor[sizeof(FW_VENDOR)];

    /*
     * These four member for domain builder internal use at virtualized
     * efi memmap creation. They should be zero-cleared after use.
     */
    unsigned long                       fw_tables_size;
    unsigned long                       fw_end_paddr;   
    unsigned long                       fw_tables_end_paddr;
    unsigned long                       num_mds;

    efi_memory_desc_t                   efi_memmap[0];
};
#define FW_FIELD_MPA(field)                                     \
    FW_TABLES_BASE_PADDR + offsetof(struct fw_tables, field)

void
xen_ia64_efi_make_md(efi_memory_desc_t *md,
                     uint32_t type, uint64_t attr, 
                     uint64_t start, uint64_t end);
struct fake_acpi_tables;
void dom_fw_fake_acpi(domain_t *d, struct fake_acpi_tables *tables);
int efi_mdt_cmp(const void *a, const void *b); 

struct ia64_boot_param;
int dom_fw_init(domain_t *d, uint64_t brkimm, struct xen_ia64_boot_param *bp,
                struct fw_tables *tables, unsigned long hypercalls_imva,
                unsigned long maxmem);

// XEN_DOMCTL_arch_setup hypercall abuse
// struct ia64_boot_param::domain_{start, size} 
// to pass memmap_pfn and memmap_size.
// This imposes arch_setup hypercall must be done before
// setting bp->domain_{size, start} and the domain builder must clean it later.
#define XEN_IA64_MEMMAP_INFO_NUM_PAGES(bp)      (bp)->domain_size
#define XEN_IA64_MEMMAP_INFO_PFN(bp)            (bp)->domain_start

#endif /* __ASM_IA64_DOM_FW_COMMON_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

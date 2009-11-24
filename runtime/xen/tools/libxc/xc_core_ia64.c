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

#include "xg_private.h"
#include "xc_core.h"
#include "xc_efi.h"
#include "xc_dom.h"
#include <inttypes.h>

int
xc_core_arch_gpfn_may_present(struct xc_core_arch_context *arch_ctxt,
                              unsigned long pfn)
{
    if (arch_ctxt->p2m_table.p2m == NULL)
        return 1; /* default to trying to map the page */

    return xc_ia64_p2m_present(&arch_ctxt->p2m_table, pfn);
}

static int
xc_memory_map_cmp(const void *lhs__, const void *rhs__)
{
    const struct xc_core_memory_map *lhs =
        (const struct xc_core_memory_map *)lhs__;
    const struct xc_core_memory_map *rhs =
        (const struct xc_core_memory_map *)rhs__;

    if (lhs->addr < rhs->addr)
        return -1;
    if (lhs->addr > rhs->addr)
        return 1;

    /* memory map overlap isn't allowed. complain */
    DPRINTF("duplicated addresses are detected "
            "(0x%" PRIx64 ", 0x%" PRIx64 "), "
            "(0x%" PRIx64 ", 0x%" PRIx64 ")\n",
            lhs->addr, lhs->size, rhs->addr, rhs->size);
    return 0;
}

int
xc_core_arch_auto_translated_physmap(const xc_dominfo_t *info)
{
    /*
     * on ia64, both paravirtualize domain and hvm domain are
     * auto_translated_physmap mode
     */
    return 1;
}

/* see setup_guest() @ xc_linux_build.c */
static int
memory_map_get_old_domu(int xc_handle, xc_dominfo_t *info,
                        shared_info_any_t *live_shinfo,
                        xc_core_memory_map_t **mapp, unsigned int *nr_entries)
{
    xc_core_memory_map_t *map = NULL;

    map = malloc(sizeof(*map));
    if ( map == NULL )
    {
        PERROR("Could not allocate memory");
        goto out;
    }

    map->addr = 0;
    map->size = info->max_memkb * 1024;

    *mapp = map;
    *nr_entries = 1;
    return 0;

out:
    if ( map != NULL )
        free(map);
    return -1;
}

/* see setup_guest() @ xc_ia64_hvm_build.c */
static int
memory_map_get_old_hvm(int xc_handle, xc_dominfo_t *info, 
                       shared_info_any_t *live_shinfo,
                       xc_core_memory_map_t **mapp, unsigned int *nr_entries)
{
    const xc_core_memory_map_t gfw_map[] = {
        {IO_PAGE_START, IO_PAGE_SIZE},
        {STORE_PAGE_START, STORE_PAGE_SIZE},
        {BUFFER_IO_PAGE_START, BUFFER_IO_PAGE_SIZE},
        {BUFFER_PIO_PAGE_START, BUFFER_PIO_PAGE_SIZE},
        {GFW_START, GFW_SIZE},
    };
    const unsigned int nr_gfw_map = sizeof(gfw_map)/sizeof(gfw_map[0]);
    xc_core_memory_map_t *map = NULL;
    unsigned int i;
    
#define VGA_IO_END      (VGA_IO_START + VGA_IO_SIZE)
    /* [0, VGA_IO_START) [VGA_IO_END, 3GB), [4GB, ...) + gfw_map */
    map = malloc((3 + nr_gfw_map) * sizeof(*map));
    if ( map == NULL )
    {
        PERROR("Could not allocate memory");
        goto out;
    }

    for ( i = 0; i < nr_gfw_map; i++ )
        map[i] = gfw_map[i];
    map[i].addr = 0;
    map[i].size = info->max_memkb * 1024;
    i++;
    if ( map[i - 1].size < VGA_IO_END )
    {
        map[i - 1].size = VGA_IO_START;
    }
    else
    {
        map[i].addr = VGA_IO_END;
        map[i].size = map[i - 1].size - VGA_IO_END;
        map[i - 1].size = VGA_IO_START;
        i++;
        if ( map[i - 1].addr + map[i - 1].size > MMIO_START )
        {
            map[i].addr = MMIO_START + 1 * MEM_G;
            map[i].size = map[i - 1].addr + map[i - 1].size - MMIO_START;
            map[i - 1].size = MMIO_START - map[i - 1].addr;
            i++;
        }
    }
    *mapp = map;
    *nr_entries = i;
    qsort(map, *nr_entries, sizeof(map[0]), &xc_memory_map_cmp);
    return 0;

out:
    if ( map != NULL )
        free(map);
    return -1;
}

static int
memory_map_get_old(int xc_handle, xc_dominfo_t *info, 
                   shared_info_any_t *live_shinfo,
                   xc_core_memory_map_t **mapp, unsigned int *nr_entries)
{
    if ( info->hvm )
        return memory_map_get_old_hvm(xc_handle, info, live_shinfo,
                                      mapp, nr_entries);
    if ( live_shinfo == NULL )
        return -1;
    return memory_map_get_old_domu(xc_handle, info, live_shinfo,
                                   mapp, nr_entries);
}

int
xc_core_arch_memory_map_get(int xc_handle,
                            struct xc_core_arch_context *arch_ctxt,
                            xc_dominfo_t *info,
                            shared_info_any_t *live_shinfo,
                            xc_core_memory_map_t **mapp,
                            unsigned int *nr_entries)
{
    int ret = -1;

    xen_ia64_memmap_info_t *memmap_info = NULL;
    xc_core_memory_map_t *map;
    char *start;
    char *end;
    char *p;
    efi_memory_desc_t *md;

    if ( live_shinfo == NULL )
    {
        ERROR("can't access shared info");
        goto old;
    }

    /* copy before use in case someone updating them */
    if (xc_ia64_copy_memmap(xc_handle, info->domid, &live_shinfo->s,
                            &memmap_info, NULL)) {
        goto old;
    }

    *nr_entries = memmap_info->efi_memmap_size / memmap_info->efi_memdesc_size;
    map = malloc(*nr_entries * sizeof(*md));
    if ( map == NULL )
    {
        PERROR("Could not allocate memory for memmap.");
        free(memmap_info);
        return -1;
    }
    *mapp = map;

    *nr_entries = 0;
    start = (char*)&memmap_info->memdesc;
    end = start + memmap_info->efi_memmap_size;
    for ( p = start; p < end; p += memmap_info->efi_memdesc_size )
    {
        md = (efi_memory_desc_t*)p;
        if ( md->type != EFI_CONVENTIONAL_MEMORY ||
             md->attribute != EFI_MEMORY_WB ||
             md->num_pages == 0 )
            continue;

        map[*nr_entries].addr = md->phys_addr;
        map[*nr_entries].size = md->num_pages << EFI_PAGE_SHIFT;
        (*nr_entries)++;
    }
    ret = 0;

    xc_ia64_p2m_map(&arch_ctxt->p2m_table, xc_handle, info->domid,
                    memmap_info, 0);
    if ( memmap_info != NULL )
        free(memmap_info);
    qsort(map, *nr_entries, sizeof(map[0]), &xc_memory_map_cmp);
    return ret;
    
old:
    DPRINTF("Falling back old method.\n");
    return memory_map_get_old(xc_handle, info, live_shinfo, mapp, nr_entries);
}

int
xc_core_arch_map_p2m(int xc_handle, unsigned int guest_width, xc_dominfo_t *info,
                     shared_info_any_t *live_shinfo, xen_pfn_t **live_p2m,
                     unsigned long *pfnp)
{
    /*
     * on ia64, both paravirtualize domain and hvm domain are
     * auto_translated_physmap mode
     */
    errno = ENOSYS;
    return -1;
}

void
xc_core_arch_context_init(struct xc_core_arch_context* arch_ctxt)
{
    arch_ctxt->mapped_regs_size =
        (XMAPPEDREGS_SIZE < PAGE_SIZE) ? PAGE_SIZE: XMAPPEDREGS_SIZE;
    arch_ctxt->nr_vcpus = 0;
    arch_ctxt->mapped_regs = NULL;

    xc_ia64_p2m_init(&arch_ctxt->p2m_table);
}

void
xc_core_arch_context_free(struct xc_core_arch_context* arch_ctxt)
{
    int i;
    for ( i = 0; i < arch_ctxt->nr_vcpus; i++ )
        if ( arch_ctxt->mapped_regs[i] != NULL )
            munmap(arch_ctxt->mapped_regs[i], arch_ctxt->mapped_regs_size);
    free(arch_ctxt->mapped_regs);
    xc_ia64_p2m_unmap(&arch_ctxt->p2m_table);
}

int
xc_core_arch_context_get(struct xc_core_arch_context* arch_ctxt,
                         vcpu_guest_context_any_t* ctxt_any,
                         int xc_handle, uint32_t domid)
{
    vcpu_guest_context_t *ctxt = &ctxt_any->c;
    mapped_regs_t* mapped_regs;

    if ( ctxt->privregs_pfn == VGC_PRIVREGS_HVM )
        return 0;       /* VTi domain case */

    if ( ctxt->privregs_pfn == INVALID_P2M_ENTRY )
    {
        PERROR("Could not get mmapped privregs gmfn");
        errno = ENOENT;
        return -1;
    }
    if ( !(arch_ctxt->nr_vcpus & (arch_ctxt->nr_vcpus - 1)) ) {
        unsigned int nr = arch_ctxt->nr_vcpus ? arch_ctxt->nr_vcpus << 1 : 1;
        mapped_regs_t** new = realloc(arch_ctxt->mapped_regs,
                                      nr * sizeof(*new));

        if ( !new )
        {
            PERROR("Could not alloc mapped regs pointer array");
            return -1;
        }
        memset(new + arch_ctxt->nr_vcpus, 0,
               (nr - arch_ctxt->nr_vcpus) * sizeof(*new));
        arch_ctxt->mapped_regs = new;
    }

    mapped_regs = xc_map_foreign_range(xc_handle, domid,
                                       arch_ctxt->mapped_regs_size,
                                       PROT_READ, ctxt->privregs_pfn);
    if ( mapped_regs == NULL )
    {
        PERROR("Could not map mapped privregs");
        return -1;
    }
    arch_ctxt->mapped_regs[arch_ctxt->nr_vcpus] = mapped_regs;
    arch_ctxt->nr_vcpus++;
    return 0;
}

int
xc_core_arch_context_get_shdr(struct xc_core_arch_context *arch_ctxt, 
                              struct xc_core_section_headers *sheaders,
                              struct xc_core_strtab *strtab,
                              uint64_t *filesz, uint64_t offset)
{
    int sts = -1;
    Elf64_Shdr *shdr;

    if ( arch_ctxt->nr_vcpus == 0 )
    {
        /* VTi domain case */
        *filesz = 0;
        return 0;       
    }

    /* mmapped priv regs */
    shdr = xc_core_shdr_get(sheaders);
    if ( shdr == NULL )
    {
        PERROR("Could not get section header for .xen_ia64_mapped_regs");
        return sts;
    }
    *filesz = arch_ctxt->mapped_regs_size * arch_ctxt->nr_vcpus;
    sts = xc_core_shdr_set(shdr, strtab, XEN_DUMPCORE_SEC_IA64_MAPPED_REGS,
                           SHT_PROGBITS, offset, *filesz,
                           __alignof__(*arch_ctxt->mapped_regs[0]),
                           arch_ctxt->mapped_regs_size);
    return sts;
}

int
xc_core_arch_context_dump(struct xc_core_arch_context* arch_ctxt,
                          void* args, dumpcore_rtn_t dump_rtn)
{
    int sts = 0;
    int i;
    
    /* ia64 mapped_regs: .xen_ia64_mapped_regs */
    for ( i = 0; i < arch_ctxt->nr_vcpus; i++ )
    {
        sts = dump_rtn(args, (char*)arch_ctxt->mapped_regs[i],
                       arch_ctxt->mapped_regs_size);
        if ( sts != 0 )
            break;
    }
    return sts;
}

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

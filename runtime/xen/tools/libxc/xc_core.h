/*
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
 * Foundation, 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */

#ifndef XC_CORE_H
#define XC_CORE_H

#include "xen/version.h"
#include "xg_private.h"
#include "xen/libelf/elfstructs.h"

/* section names */
#define XEN_DUMPCORE_SEC_NOTE                   ".note.Xen"
#define XEN_DUMPCORE_SEC_PRSTATUS               ".xen_prstatus"
#define XEN_DUMPCORE_SEC_SHARED_INFO            ".xen_shared_info"
#define XEN_DUMPCORE_SEC_P2M                    ".xen_p2m"
#define XEN_DUMPCORE_SEC_PFN                    ".xen_pfn"
#define XEN_DUMPCORE_SEC_PAGES                  ".xen_pages"

#define XEN_DUMPCORE_SEC_IA64_MAPPED_REGS       ".xen_ia64_mapped_regs"

/* elf note name */
#define XEN_DUMPCORE_ELFNOTE_NAME               "Xen"
/* note numbers are defined in xen/elfnote.h */

struct elfnote {
    uint32_t    namesz; /* Elf_Note note; */
    uint32_t    descsz;
    uint32_t    type;
    char        name[4]; /* sizeof("Xen") = 4
                          * Fotunately this is 64bit aligned so that
                          * we can use same structore for both 32/64bit
                          */
};

struct xen_dumpcore_elfnote_none_desc {
    /* nothing */
};

struct xen_dumpcore_elfnote_header_desc {
    uint64_t    xch_magic;
    uint64_t    xch_nr_vcpus;
    uint64_t    xch_nr_pages;
    uint64_t    xch_page_size;
};

struct xen_dumpcore_elfnote_xen_version_desc {
    uint64_t                    major_version;
    uint64_t                    minor_version;
    xen_extraversion_t          extra_version;
    xen_compile_info_t          compile_info;
    xen_capabilities_info_t     capabilities;
    xen_changeset_info_t        changeset;
    xen_platform_parameters_t   platform_parameters;
    uint64_t                    pagesize;
};

#define XEN_DUMPCORE_FORMAT_VERSION(major, minor)  \
    ((major) << 32) | ((minor) & 0xffffffff)
#define XEN_DUMPCORE_FORMAT_MAJOR(version)      ((major) >> 32)
#define XEN_DUMPCORE_FORMAT_MINOR(version)      ((minor) & 0xffffffff)

#define XEN_DUMPCORE_FORMAT_MAJOR_CURRENT       ((uint64_t)0)
#define XEN_DUMPCORE_FORMAT_MINOR_CURRENT       ((uint64_t)1)
#define XEN_DUMPCORE_FORMAT_VERSION_CURRENT                         \
    XEN_DUMPCORE_FORMAT_VERSION(XEN_DUMPCORE_FORMAT_MAJOR_CURRENT,  \
                                XEN_DUMPCORE_FORMAT_MINOR_CURRENT)

struct xen_dumpcore_elfnote_format_version_desc {
    uint64_t    version;
};


struct xen_dumpcore_elfnote_none {
    struct elfnote                              elfnote;
    struct xen_dumpcore_elfnote_none_desc       none;
};

struct xen_dumpcore_elfnote_header {
    struct elfnote                              elfnote;
    struct xen_dumpcore_elfnote_header_desc     header;
};

struct xen_dumpcore_elfnote_xen_version {
    struct elfnote                                     elfnote;
    struct xen_dumpcore_elfnote_xen_version_desc        xen_version;
};

struct xen_dumpcore_elfnote_format_version {
    struct elfnote                                      elfnote;
    struct xen_dumpcore_elfnote_format_version_desc     format_version;
};

#define XC_CORE_INVALID_PFN     (~(uint64_t)0)
#define XC_CORE_INVALID_GMFN    (~(uint64_t)0)
struct xen_dumpcore_p2m {
    uint64_t    pfn;
    uint64_t    gmfn;
};


struct xc_core_strtab;
struct xc_core_section_headers;

Elf64_Shdr*
xc_core_shdr_get(struct xc_core_section_headers *sheaders);
int
xc_core_shdr_set(Elf64_Shdr *shdr,
                 struct xc_core_strtab *strtab,
                 const char *name, uint32_t type,
                 uint64_t offset, uint64_t size,
                 uint64_t addralign, uint64_t entsize);

struct xc_core_memory_map {
    uint64_t    addr;
    uint64_t    size;
};
typedef struct xc_core_memory_map xc_core_memory_map_t;
int xc_core_arch_auto_translated_physmap(const xc_dominfo_t *info);
struct xc_core_arch_context;
int xc_core_arch_memory_map_get(int xc_handle,
                                struct xc_core_arch_context *arch_ctxt,
                                xc_dominfo_t *info, shared_info_any_t *live_shinfo,
                                xc_core_memory_map_t **mapp,
                                unsigned int *nr_entries);
int xc_core_arch_map_p2m(int xc_handle, unsigned int guest_width,
                         xc_dominfo_t *info, shared_info_any_t *live_shinfo,
                         xen_pfn_t **live_p2m, unsigned long *pfnp);

int xc_core_arch_map_p2m_writable(int xc_handle, unsigned int guest_width,
                                  xc_dominfo_t *info,
                                  shared_info_any_t *live_shinfo,
                                  xen_pfn_t **live_p2m, unsigned long *pfnp);


#if defined (__i386__) || defined (__x86_64__)
# include "xc_core_x86.h"
#elif defined (__ia64__)
# include "xc_core_ia64.h"
#else
# error "unsupported architecture"
#endif

#ifndef ELF_CORE_EFLAGS
# define ELF_CORE_EFLAGS 0
#endif

#endif /* XC_CORE_H */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

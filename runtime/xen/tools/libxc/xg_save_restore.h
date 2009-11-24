/*
** xg_save_restore.h
**
** Defintions and utilities for save / restore.
*/

#include "xc_private.h"

#include <xen/foreign/x86_32.h>
#include <xen/foreign/x86_64.h>

/*
** We process save/restore/migrate in batches of pages; the below
** determines how many pages we (at maximum) deal with in each batch.
*/
#define MAX_BATCH_SIZE 1024   /* up to 1024 pages (4MB) at a time */

/* When pinning page tables at the end of restore, we also use batching. */
#define MAX_PIN_BATCH  1024



/*
** Determine various platform information required for save/restore, in
** particular:
**
**    - the maximum MFN on this machine, used to compute the size of
**      the M2P table;
**
**    - the starting virtual address of the the hypervisor; we use this
**      to determine which parts of guest address space(s) do and don't
**      require canonicalization during save/restore; and
**
**    - the number of page-table levels for save/ restore. This should
**      be a property of the domain, but for the moment we just read it
**      from the hypervisor.
**
**    - The width of a guest word (unsigned long), in bytes.
**
** Returns 1 on success, 0 on failure.
*/
static inline int get_platform_info(int xc_handle, uint32_t dom,
                                    /* OUT */ unsigned long *max_mfn,
                                    /* OUT */ unsigned long *hvirt_start,
                                    /* OUT */ unsigned int *pt_levels,
                                    /* OUT */ unsigned int *guest_width)
{
    xen_capabilities_info_t xen_caps = "";
    xen_platform_parameters_t xen_params;
    DECLARE_DOMCTL;

    if (xc_version(xc_handle, XENVER_platform_parameters, &xen_params) != 0)
        return 0;

    if (xc_version(xc_handle, XENVER_capabilities, &xen_caps) != 0)
        return 0;

    *max_mfn = xc_memory_op(xc_handle, XENMEM_maximum_ram_page, NULL);

    *hvirt_start = xen_params.virt_start;

    memset(&domctl, 0, sizeof(domctl));
    domctl.domain = dom;
    domctl.cmd = XEN_DOMCTL_get_address_size;

    if ( do_domctl(xc_handle, &domctl) != 0 )
        return 0; 

    *guest_width = domctl.u.address_size.size / 8;

    /* 64-bit tools will see the 64-bit hvirt_start, but 32-bit guests 
     * will be using the compat one. */
    if ( *guest_width < sizeof (unsigned long) )
        /* XXX need to fix up a way of extracting this value from Xen if
         * XXX it becomes variable for domU */
        *hvirt_start = 0xf5800000;

    if (strstr(xen_caps, "xen-3.0-x86_64"))
        /* Depends on whether it's a compat 32-on-64 guest */
        *pt_levels = ( (*guest_width == 8) ? 4 : 3 );
    else if (strstr(xen_caps, "xen-3.0-x86_32p"))
        *pt_levels = 3;
    else if (strstr(xen_caps, "xen-3.0-x86_32"))
        *pt_levels = 2;
    else
        return 0;

    return 1;
}


/*
** Save/restore deal with the mfn_to_pfn (M2P) and pfn_to_mfn (P2M) tables.
** The M2P simply holds the corresponding PFN, while the top bit of a P2M
** entry tell us whether or not the the PFN is currently mapped.
*/

#define PFN_TO_KB(_pfn) ((_pfn) << (PAGE_SHIFT - 10))


/*
** The M2P is made up of some number of 'chunks' of at least 2MB in size.
** The below definitions and utility function(s) deal with mapping the M2P
** regarldess of the underlying machine memory size or architecture.
*/
#define M2P_SHIFT       L2_PAGETABLE_SHIFT_PAE
#define M2P_CHUNK_SIZE  (1 << M2P_SHIFT)
#define M2P_SIZE(_m)    ROUNDUP(((_m) * sizeof(xen_pfn_t)), M2P_SHIFT)
#define M2P_CHUNKS(_m)  (M2P_SIZE((_m)) >> M2P_SHIFT)

/* Returns TRUE if the PFN is currently mapped */
#define is_mapped(pfn_type) (!((pfn_type) & 0x80000000UL))


#define GET_FIELD(_p, _f) ((guest_width==8) ? ((_p)->x64._f) : ((_p)->x32._f))

#define SET_FIELD(_p, _f, _v) do {              \
    if (guest_width == 8)                       \
        (_p)->x64._f = (_v);                    \
    else                                        \
        (_p)->x32._f = (_v);                    \
} while (0)

#define UNFOLD_CR3(_c)                                                  \
  ((uint64_t)((guest_width == 8)                                        \
              ? ((_c) >> 12)                                            \
              : (((uint32_t)(_c) >> 12) | ((uint32_t)(_c) << 20))))

#define FOLD_CR3(_c)                                                    \
  ((uint64_t)((guest_width == 8)                                        \
              ? ((uint64_t)(_c)) << 12                                  \
              : (((uint32_t)(_c) << 12) | ((uint32_t)(_c) >> 20))))

#define MEMCPY_FIELD(_d, _s, _f) do {                              \
    if (guest_width == 8)                                          \
        memcpy(&(_d)->x64._f, &(_s)->x64._f,sizeof((_d)->x64._f)); \
    else                                                           \
        memcpy(&(_d)->x32._f, &(_s)->x32._f,sizeof((_d)->x32._f)); \
} while (0)

#define MEMSET_ARRAY_FIELD(_p, _f, _v) do {                        \
    if (guest_width == 8)                                          \
        memset(&(_p)->x64._f[0], (_v), sizeof((_p)->x64._f));      \
    else                                                           \
        memset(&(_p)->x32._f[0], (_v), sizeof((_p)->x32._f));      \
} while (0)

#ifndef MAX
#define MAX(_a, _b) ((_a) >= (_b) ? (_a) : (_b))
#endif
#ifndef MIN
#define MIN(_a, _b) ((_a) <= (_b) ? (_a) : (_b))
#endif

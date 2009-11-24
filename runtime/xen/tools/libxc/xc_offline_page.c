/******************************************************************************
 * xc_offline_page.c
 *
 * Helper functions to offline/online one page
 *
 * Copyright (c) 2003, K A Fraser.
 * Copyright (c) 2009, Intel Corporation.
 */

#include <inttypes.h>
#include <time.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>
#include <xs.h>
#include <xc_core.h>

#include "xc_private.h"
#include "xc_dom.h"
#include "xg_private.h"
#include "xg_save_restore.h"

struct domain_mem_info{
    int domid;
    unsigned int pt_level;
    unsigned int guest_width;
    uint32_t *pfn_type;
    xen_pfn_t *p2m_table;
    unsigned long p2m_size;
    xen_pfn_t *m2p_table;
    int max_mfn;
};

struct pte_backup_entry
{
    xen_pfn_t table_mfn;
    int offset;
};

#define DEFAULT_BACKUP_COUNT 1024
struct pte_backup
{
    struct pte_backup_entry *entries;
    int max;
    int cur;
};

/* Global definition for some MACRO */
int guest_width, p2m_size;

int xc_mark_page_online(int xc, unsigned long start,
                        unsigned long end, uint32_t *status)
{
    DECLARE_SYSCTL;
    int ret = -1;

    if ( !status || (end < start) )
        return -EINVAL;

    if (lock_pages(status, sizeof(uint32_t)*(end - start + 1)))
    {
        ERROR("Could not lock memory for xc_mark_page_online\n");
        return -EINVAL;
    }

    sysctl.cmd = XEN_SYSCTL_page_offline_op;
    sysctl.u.page_offline.start = start;
    sysctl.u.page_offline.cmd = sysctl_page_online;
    sysctl.u.page_offline.end = end;
    set_xen_guest_handle(sysctl.u.page_offline.status, status);
    ret = xc_sysctl(xc, &sysctl);

    unlock_pages(status, sizeof(uint32_t)*(end - start + 1));

    return ret;
}

int xc_mark_page_offline(int xc, unsigned long start,
                          unsigned long end, uint32_t *status)
{
    DECLARE_SYSCTL;
    int ret = -1;

    if ( !status || (end < start) )
        return -EINVAL;

    if (lock_pages(status, sizeof(uint32_t)*(end - start + 1)))
    {
        ERROR("Could not lock memory for xc_mark_page_offline");
        return -EINVAL;
    }

    sysctl.cmd = XEN_SYSCTL_page_offline_op;
    sysctl.u.page_offline.start = start;
    sysctl.u.page_offline.cmd = sysctl_page_offline;
    sysctl.u.page_offline.end = end;
    set_xen_guest_handle(sysctl.u.page_offline.status, status);
    ret = xc_sysctl(xc, &sysctl);

    unlock_pages(status, sizeof(uint32_t)*(end - start + 1));

    return ret;
}

int xc_query_page_offline_status(int xc, unsigned long start,
                                 unsigned long end, uint32_t *status)
{
    DECLARE_SYSCTL;
    int ret = -1;

    if ( !status || (end < start) )
        return -EINVAL;

    if (lock_pages(status, sizeof(uint32_t)*(end - start + 1)))
    {
        ERROR("Could not lock memory for xc_query_page_offline_status\n");
        return -EINVAL;
    }

    sysctl.cmd = XEN_SYSCTL_page_offline_op;
    sysctl.u.page_offline.start = start;
    sysctl.u.page_offline.cmd = sysctl_query_page_offline;
    sysctl.u.page_offline.end = end;
    set_xen_guest_handle(sysctl.u.page_offline.status, status);
    ret = xc_sysctl(xc, &sysctl);

    unlock_pages(status, sizeof(uint32_t)*(end - start + 1));

    return ret;
}

 /*
  * There should no update to the grant when domain paused
  */
static int xc_is_page_granted_v1(int xc_handle, xen_pfn_t gpfn,
                                 grant_entry_v1_t *gnttab, int gnt_num)
{
    int i = 0;

    if (!gnttab)
        return 0;

    for (i = 0; i < gnt_num; i++)
        if ( ((gnttab[i].flags & GTF_type_mask) !=  GTF_invalid) &&
             (gnttab[i].frame == gpfn) )
             break;

   return (i != gnt_num);
}

static int xc_is_page_granted_v2(int xc_handle, xen_pfn_t gpfn,
                                 grant_entry_v2_t *gnttab, int gnt_num)
{
    int i = 0;

    if (!gnttab)
        return 0;

    for (i = 0; i < gnt_num; i++)
        if ( ((gnttab[i].hdr.flags & GTF_type_mask) !=  GTF_invalid) &&
             (gnttab[i].full_page.frame == gpfn) )
             break;

   return (i != gnt_num);
}

static xen_pfn_t pfn_to_mfn(xen_pfn_t pfn, xen_pfn_t *p2m, int gwidth)
{
  return ((xen_pfn_t) ((gwidth==8)?
                       (((uint64_t *)p2m)[(pfn)]):
                       ((((uint32_t *)p2m)[(pfn)]) == 0xffffffffU ?
                            (-1UL) :
                            (((uint32_t *)p2m)[(pfn)]))));
}

static int get_pt_level(int xc_handle, uint32_t domid,
                        unsigned int *pt_level,
                        unsigned int *gwidth)
{
    DECLARE_DOMCTL;
    xen_capabilities_info_t xen_caps = "";

    if (xc_version(xc_handle, XENVER_capabilities, &xen_caps) != 0)
        return -1;

    memset(&domctl, 0, sizeof(domctl));
    domctl.domain = domid;
    domctl.cmd = XEN_DOMCTL_get_address_size;

    if ( do_domctl(xc_handle, &domctl) != 0 )
        return -1;

    *gwidth = domctl.u.address_size.size / 8;

    if (strstr(xen_caps, "xen-3.0-x86_64"))
        /* Depends on whether it's a compat 32-on-64 guest */
        *pt_level = ( (*gwidth == 8) ? 4 : 3 );
    else if (strstr(xen_caps, "xen-3.0-x86_32p"))
        *pt_level = 3;
    else if (strstr(xen_caps, "xen-3.0-x86_32"))
        *pt_level = 2;
    else
        return -1;

    return 0;
}

static int close_mem_info(int xc_handle, struct domain_mem_info *minfo)
{
    if (minfo->pfn_type)
        free(minfo->pfn_type);
    munmap(minfo->m2p_table, M2P_SIZE(minfo->max_mfn));
    munmap(minfo->p2m_table, P2M_FLL_ENTRIES * PAGE_SIZE);
    minfo->p2m_table = minfo->m2p_table = NULL;

    return 0;
}

static int init_mem_info(int xc_handle, int domid,
                 struct domain_mem_info *minfo,
                 xc_dominfo_t *info)
{
    uint64_aligned_t shared_info_frame;
    shared_info_any_t *live_shinfo = NULL;
    int i, rc;

    /* Only be initialized once */
    if (minfo->pfn_type || minfo->m2p_table || minfo->p2m_table)
        return -EINVAL;

    if ( get_pt_level(xc_handle, domid, &minfo->pt_level,
                      &minfo->guest_width) )
    {
        ERROR("Unable to get PT level info.");
        return -EFAULT;
    }
    guest_width = minfo->guest_width;

    shared_info_frame = info->shared_info_frame;

    live_shinfo = xc_map_foreign_range(xc_handle, domid,
                     PAGE_SIZE, PROT_READ, shared_info_frame);
    if ( !live_shinfo )
    {
        ERROR("Couldn't map live_shinfo");
        return -EFAULT;
    }

    if ( (rc = xc_core_arch_map_p2m_writable(xc_handle, minfo->guest_width,
              info, live_shinfo, &minfo->p2m_table,  &minfo->p2m_size)) )
    {
        ERROR("Couldn't map p2m table %x\n", rc);
        goto failed;
    }
    munmap(live_shinfo, PAGE_SIZE);
    live_shinfo = NULL;

    p2m_size = minfo->p2m_size;

    minfo->max_mfn = xc_memory_op(xc_handle, XENMEM_maximum_ram_page, NULL);
    if ( !(minfo->m2p_table =
        xc_map_m2p(xc_handle, minfo->max_mfn, PROT_READ, NULL)) )
    {
        ERROR("Failed to map live M2P table");
        goto failed;
    }

    /* Get pfn type */
    minfo->pfn_type = malloc(sizeof(uint32_t) * minfo->p2m_size);
    if (!minfo->pfn_type)
    {
        ERROR("Failed to malloc pfn_type\n");
        goto failed;
    }
    memset(minfo->pfn_type, 0, sizeof(uint32_t) * minfo->p2m_size);

    for (i = 0; i < minfo->p2m_size; i++)
        minfo->pfn_type[i] = pfn_to_mfn(i, minfo->p2m_table,
                                        minfo->guest_width);

    if ( lock_pages(minfo->pfn_type, minfo->p2m_size * sizeof(uint32_t)) )
    {
        ERROR("Unable to lock pfn_type array");
        goto failed;
    }

    for (i = 0; i < minfo->p2m_size ; i+=1024)
    {
        int count = ((p2m_size - i ) > 1024 ) ? 1024: (p2m_size - i);
        if ( ( rc = xc_get_pfn_type_batch(xc_handle, domid, count,
                  minfo->pfn_type + i)) )
        {
            ERROR("Failed to get pfn_type %x\n", rc);
            goto unlock;
        }
    }
    return 0;

unlock:
    unlock_pages(minfo->pfn_type, minfo->p2m_size * sizeof(uint32_t));
failed:
    if (minfo->pfn_type)
    {
        minfo->pfn_type = NULL;
        free(minfo->pfn_type);
    }
    if (live_shinfo)
        munmap(live_shinfo, PAGE_SIZE);
    munmap(minfo->m2p_table, M2P_SIZE(minfo->max_mfn));
    munmap(minfo->p2m_table, P2M_FLL_ENTRIES * PAGE_SIZE);
    minfo->p2m_table = minfo->m2p_table = NULL;

    return -1;
}

static int backup_ptes(xen_pfn_t table_mfn, int offset,
                       struct pte_backup *backup)
{
    if (!backup)
        return -EINVAL;

    if (backup->max == backup->cur)
    {
        backup->entries = realloc(backup->entries,
                            backup->max * 2 * sizeof(struct pte_backup_entry));
        if (backup->entries == NULL)
            return -1;
        else
            backup->max *= 2;
    }

    backup->entries[backup->cur].table_mfn = table_mfn;
    backup->entries[backup->cur++].offset = offset;

    return 0;
}

/*
 * return:
 * 1 when MMU update is required
 * 0 when no changes
 * <0 when error happen
 */
typedef int (*pte_func)(uint64_t pte, uint64_t *new_pte,
                       unsigned long table_mfn, int table_offset,
                       struct pte_backup *backup,
                       unsigned long no_use);

static int __clear_pte(uint64_t pte, uint64_t *new_pte,
                       unsigned long table_mfn, int table_offset,
                       struct pte_backup *backup,
                       unsigned long mfn)
{
    /* If no new_pte pointer, same as no changes needed */
    if (!new_pte || !backup)
        return -EINVAL;

    if ( !(pte & _PAGE_PRESENT))
        return 0;

    /* XXX Check for PSE bit here */
    /* Hit one entry */
    if ( ((pte >> PAGE_SHIFT_X86) & MFN_MASK_X86) == mfn)
    {
        *new_pte = pte & ~_PAGE_PRESENT;
        if (!backup_ptes(table_mfn, table_offset, backup))
            return 1;
    }

    return 0;
}

static int __update_pte(uint64_t pte, uint64_t *new_pte,
                      unsigned long table_mfn, int table_offset,
                      struct pte_backup *backup,
                      unsigned long new_mfn)
{
    int index;

    if (!new_pte)
        return 0;

    for (index = 0; index < backup->cur; index ++)
        if ( (backup->entries[index].table_mfn == table_mfn) &&
             (backup->entries[index].offset == table_offset) )
            break;

    if (index != backup->cur)
    {
        if (pte & _PAGE_PRESENT)
            ERROR("Page present while in backup ptes\n");
        pte &= ~MFN_MASK_X86;
        pte |= (new_mfn << PAGE_SHIFT_X86) | _PAGE_PRESENT;
        *new_pte = pte;
        return 1;
    }

    return 0;
}

static int change_pte(int xc_handle, int domid,
                     struct domain_mem_info *minfo,
                     struct pte_backup *backup,
                     struct xc_mmu *mmu,
                     pte_func func,
                     unsigned long data)
{
    int pte_num, rc;
    uint64_t i;
    void *content = NULL;

    pte_num = PAGE_SIZE / ((minfo->pt_level == 2) ? 4 : 8);

    for (i = 0; i < minfo->p2m_size; i++)
    {
        xen_pfn_t table_mfn = pfn_to_mfn(i, minfo->p2m_table,
                                         minfo->guest_width);
        uint64_t pte, new_pte;
        int j;

        if ( table_mfn == INVALID_P2M_ENTRY )
            continue;

        if ( minfo->pfn_type[i] & XEN_DOMCTL_PFINFO_LTABTYPE_MASK )
        {
            content = xc_map_foreign_range(xc_handle, domid, PAGE_SIZE,
                                            PROT_READ, table_mfn);
            if (!content)
                goto failed;

            for (j = 0; j < pte_num; j++)
            {
                if ( minfo->pt_level == 2 )
                    pte = ((const uint32_t*)content)[j];
                else
                    pte = ((const uint64_t*)content)[j];

                rc = func(pte, &new_pte, table_mfn, j, backup, data);

                switch (rc)
                {
                    case 1:
                    if ( xc_add_mmu_update(xc_handle, mmu,
                          table_mfn << PAGE_SHIFT |
                          j * ( (minfo->pt_level == 2) ?
                              sizeof(uint32_t): sizeof(uint64_t)) |
                          MMU_PT_UPDATE_PRESERVE_AD,
                          new_pte) )
                        goto failed;
                    break;

                    case 0:
                    break;

                    default:
                    goto failed;
                }
            }
        }

        munmap(content, PAGE_SIZE);
        content = NULL;
    }

    if ( xc_flush_mmu_updates(xc_handle, mmu) )
        goto failed;

    return 0;
failed:
    /* XXX Shall we take action if we have fail to swap? */
    if (content)
        munmap(content, PAGE_SIZE);

    return -1;
}

static int update_pte(int xc_handle, int domid,
                     struct domain_mem_info *minfo,
                     struct pte_backup *backup,
                     struct xc_mmu *mmu,
                     unsigned long new_mfn)
{
    return change_pte(xc_handle, domid,  minfo, backup, mmu,
                      __update_pte, new_mfn);
}

static int clear_pte(int xc_handle, int domid,
                     struct domain_mem_info *minfo,
                     struct pte_backup *backup,
                     struct xc_mmu *mmu,
                     xen_pfn_t mfn)
{
    return change_pte(xc_handle, domid, minfo, backup, mmu,
                      __clear_pte, mfn);
}

static int exchange_page(int xc_handle, xen_pfn_t mfn,
                     xen_pfn_t *new_mfn, int domid)
{
    int rc;
    xen_pfn_t out_mfn;

	struct xen_memory_exchange exchange = {
		.in = {
			.nr_extents   = 1,
			.extent_order = 0,
			.domid        = domid
		},
		.out = {
			.nr_extents   = 1,
			.extent_order = 0,
			.domid        = domid
		}
    };
    set_xen_guest_handle(exchange.in.extent_start, &mfn);
    set_xen_guest_handle(exchange.out.extent_start, &out_mfn);

    rc = xc_memory_op(xc_handle, XENMEM_exchange, &exchange);

    if (!rc)
        *new_mfn = out_mfn;

    return rc;
}

/*
 * Check if a page can be exchanged successfully
 */

static int is_page_exchangable(int xc_handle, int domid, xen_pfn_t mfn,
                               xc_dominfo_t *info)
{
    uint32_t status;
    int rc;

    /* domain checking */
    if ( !domid || (domid > DOMID_FIRST_RESERVED) )
    {
        DPRINTF("Dom0's page can't be LM");
        return 0;
    }
    if (info->hvm)
    {
        DPRINTF("Currently we can only live change PV guest's page\n");
        return 0;
    }

    /* Check if pages are offline pending or not */
    rc = xc_query_page_offline_status(xc_handle, mfn, mfn, &status);

    if ( rc || !(status & PG_OFFLINE_STATUS_OFFLINE_PENDING) )
    {
        ERROR("Page %lx is not offline pending %x\n",
          mfn, status);
        return 0;
    }

    return 1;
}

/* The domain should be suspended when called here */
int xc_exchange_page(int xc_handle, int domid, xen_pfn_t mfn)
{
    xc_dominfo_t info;
    struct domain_mem_info minfo;
    struct xc_mmu *mmu = NULL;
    struct pte_backup old_ptes = {NULL, 0, 0};
    grant_entry_v1_t *gnttab_v1 = NULL;
    grant_entry_v2_t *gnttab_v2 = NULL;
    struct mmuext_op mops;
    int gnt_num, unpined = 0;
    void *old_p, *backup = NULL;
    int rc, result = -1;
    uint32_t status;
    xen_pfn_t new_mfn, gpfn;

    if ( xc_domain_getinfo(xc_handle, domid, 1, &info) != 1 )
    {
        ERROR("Could not get domain info");
        return -EFAULT;
    }

    if (!info.shutdown || info.shutdown_reason != SHUTDOWN_suspend)
    {
        ERROR("Can't exchange page unless domain is suspended\n");
        return -EINVAL;
    }

    if (!is_page_exchangable(xc_handle, domid, mfn, &info))
    {
        ERROR("Could not exchange page\n");
        return -EINVAL;
    }

    /* Get domain's memory information */
    memset(&minfo, 0, sizeof(minfo));
    init_mem_info(xc_handle, domid, &minfo, &info);
    gpfn = minfo.m2p_table[mfn];

    /* Don't exchange CR3 for PAE guest in PAE host environment */
    if (minfo.guest_width > sizeof(long))
    {
        if ( (minfo.pfn_type[gpfn] & XEN_DOMCTL_PFINFO_LTABTYPE_MASK) ==
                    XEN_DOMCTL_PFINFO_L3TAB )
            goto failed;
    }

    gnttab_v2 = xc_gnttab_map_table_v2(xc_handle, domid, &gnt_num);
    if (!gnttab_v2)
    {
        gnttab_v1 = xc_gnttab_map_table_v1(xc_handle, domid, &gnt_num);
        if (!gnttab_v1)
        {
            ERROR("Failed to map grant table\n");
            goto failed;
        }
    }

    if (gnttab_v1
        ? xc_is_page_granted_v1(xc_handle, mfn, gnttab_v1, gnt_num)
        : xc_is_page_granted_v2(xc_handle, mfn, gnttab_v2, gnt_num))
    {
        ERROR("Page %lx is granted now\n", mfn);
        goto failed;
    }

    /* allocate required data structure */
    backup = malloc(PAGE_SIZE);
    if (!backup)
    {
        ERROR("Failed to allocate backup pages pointer\n");
        goto failed;
    }

    old_ptes.max = DEFAULT_BACKUP_COUNT;
    old_ptes.entries = malloc(sizeof(struct pte_backup_entry) *
                              DEFAULT_BACKUP_COUNT);

    if (!old_ptes.entries)
    {
        ERROR("Faield to allocate backup\n");
        goto failed;
    }
    old_ptes.cur = 0;

    /* Unpin the page if it is pined */
    if (minfo.pfn_type[gpfn] & XEN_DOMCTL_PFINFO_LPINTAB)
    {
        mops.cmd = MMUEXT_UNPIN_TABLE;
        mops.arg1.mfn = mfn;

        if ( xc_mmuext_op(xc_handle, &mops, 1, domid) < 0 )
        {
            ERROR("Failed to unpin page %lx", mfn);
            goto failed;
        }
        mops.arg1.mfn = mfn;
        unpined = 1;
    }

    /* backup the content */
    old_p = xc_map_foreign_range(xc_handle, domid, PAGE_SIZE,
      PROT_READ, mfn);
    if (!old_p)
    {
        ERROR("Failed to map foreign page %lx\n", mfn);
        goto failed;
    }

    memcpy(backup, old_p, PAGE_SIZE);
    munmap(old_p, PAGE_SIZE);

    mmu = xc_alloc_mmu_updates(xc_handle, domid);
    if ( mmu == NULL )
    {
        ERROR("%s: failed at %d\n", __FUNCTION__, __LINE__);
        goto failed;
    }

    /* Firstly update all pte to be invalid to remove the reference */
    rc = clear_pte(xc_handle, domid,  &minfo, &old_ptes, mmu, mfn);

    if (rc)
    {
        ERROR("clear pte failed\n");
        goto failed;
    }

    rc = exchange_page(xc_handle, mfn, &new_mfn, domid);

    if (rc)
    {
        ERROR("Exchange the page failed\n");
        /* Exchange fail means there are refere to the page still */
        rc = update_pte(xc_handle, domid, &minfo, &old_ptes, mmu, mfn);
        if (rc)
            result = -2;
        goto failed;
    }

    rc = update_pte(xc_handle, domid, &minfo, &old_ptes, mmu, new_mfn);

    if (rc)
    {
        ERROR("update pte failed guest may be broken now\n");
        /* No recover action now for swap fail */
        result = -2;
        goto failed;
    }

    /* Check if pages are offlined already */
    rc = xc_query_page_offline_status(xc_handle, mfn, mfn,
                            &status);

    if (rc)
    {
        ERROR("Fail to query offline status\n");
    }else if ( !(status & PG_OFFLINE_STATUS_OFFLINED) )
    {
        ERROR("page is still online or pending\n");
        goto failed;
    }
    else
    {
        void *new_p;
        IPRINTF("Now page is offlined %lx\n", mfn);
        /* Update the p2m table */
        minfo.p2m_table[gpfn] = new_mfn;

        new_p = xc_map_foreign_range(xc_handle, domid, PAGE_SIZE,
                                     PROT_READ|PROT_WRITE, new_mfn);
        memcpy(new_p, backup, PAGE_SIZE);
        munmap(new_p, PAGE_SIZE);
        mops.arg1.mfn = new_mfn;
        result = 0;
    }

failed:

    if (unpined && (minfo.pfn_type[mfn] & XEN_DOMCTL_PFINFO_LPINTAB))
    {
        switch ( minfo.pfn_type[mfn] & XEN_DOMCTL_PFINFO_LTABTYPE_MASK )
        {
            case XEN_DOMCTL_PFINFO_L1TAB:
                mops.cmd = MMUEXT_PIN_L1_TABLE;
                break;

            case XEN_DOMCTL_PFINFO_L2TAB:
                mops.cmd = MMUEXT_PIN_L2_TABLE;
                break;

            case XEN_DOMCTL_PFINFO_L3TAB:
                mops.cmd = MMUEXT_PIN_L3_TABLE;
                break;

            case XEN_DOMCTL_PFINFO_L4TAB:
                mops.cmd = MMUEXT_PIN_L4_TABLE;
                break;

            default:
                ERROR("Unpined for non pate table page\n");
                break;
        }

        if ( xc_mmuext_op(xc_handle, &mops, 1, domid) < 0 )
        {
            ERROR("failed to pin the mfn again\n");
            result = -2;
        }
    }

    if (mmu)
        free(mmu);

    if (old_ptes.entries)
        free(old_ptes.entries);

    if (backup)
        free(backup);

    if (gnttab_v1)
        munmap(gnttab_v1, gnt_num / (PAGE_SIZE/sizeof(grant_entry_v1_t)));
    if (gnttab_v2)
        munmap(gnttab_v2, gnt_num / (PAGE_SIZE/sizeof(grant_entry_v2_t)));

    close_mem_info(xc_handle, &minfo);

    return result;
}

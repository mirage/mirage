/******************************************************************************
 * xc_domain_restore.c
 *
 * Restore the state of a guest session.
 *
 * Copyright (c) 2003, K A Fraser.
 * Copyright (c) 2006, Intel Corporation
 * Copyright (c) 2007, XenSource Inc.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307 USA.
 *
 */

#include <stdlib.h>
#include <unistd.h>

#include "xg_private.h"
#include "xg_save_restore.h"
#include "xc_dom.h"

#include <xen/hvm/ioreq.h>
#include <xen/hvm/params.h>

/* max mfn of the current host machine */
static unsigned long max_mfn;

/* virtual starting address of the hypervisor */
static unsigned long hvirt_start;

/* #levels of page tables used by the current guest */
static unsigned int pt_levels;

/* number of pfns this guest has (i.e. number of entries in the P2M) */
static unsigned long p2m_size;

/* number of 'in use' pfns in the guest (i.e. #P2M entries with a valid mfn) */
static unsigned long nr_pfns;

/* Live mapping of the table mapping each PFN to its current MFN. */
static xen_pfn_t *live_p2m = NULL;

/* A table mapping each PFN to its new MFN. */
static xen_pfn_t *p2m = NULL;

/* Address size of the guest, in bytes */
unsigned int guest_width;

/* If have enough continuous memory for super page allocation */
static unsigned no_superpage_mem = 0;

/*
**
**
*/
#define SUPERPAGE_PFN_SHIFT  9
#define SUPERPAGE_NR_PFNS    (1UL << SUPERPAGE_PFN_SHIFT)

/*
 * Setting bit 31 force to allocate super page even not all pfns come out,
 * bit 30 indicate that not is in a super page tracking.
 */
#define FORCE_SP_SHIFT           31
#define FORCE_SP_MASK            (1UL << FORCE_SP_SHIFT)

#define INVALID_SUPER_PAGE       ((1UL << 30) + 1)
#define SUPER_PAGE_START(pfn)    (((pfn) & (SUPERPAGE_NR_PFNS-1)) == 0 )
#define SUPER_PAGE_TRACKING(pfn) ( (pfn) != INVALID_SUPER_PAGE )
#define SUPER_PAGE_DONE(pfn)     ( SUPER_PAGE_START(pfn) )

static int super_page_populated(unsigned long pfn)
{
    int i;
    pfn &= ~(SUPERPAGE_NR_PFNS - 1);
    for ( i = pfn; i < pfn + SUPERPAGE_NR_PFNS; i++ )
    {
        if ( p2m[i] != INVALID_P2M_ENTRY )
            return 1;
    }
    return 0;
}

/*
 * Break a 2M page and move contents of [extent start, next_pfn-1] to
 * some new allocated 4K pages
 */
static int break_super_page(int xc_handle,
                            uint32_t dom,
                            xen_pfn_t next_pfn)
{
    xen_pfn_t *page_array, start_pfn, mfn;
    uint8_t *ram_base, *save_buf;
    unsigned long i;
    int tot_pfns, rc = 0;

    tot_pfns = (next_pfn & (SUPERPAGE_NR_PFNS - 1));

    start_pfn = next_pfn & ~(SUPERPAGE_NR_PFNS - 1);
    for ( i = start_pfn; i < start_pfn + SUPERPAGE_NR_PFNS; i++ )
    {
        /* check the 2M page are populated */
        if ( p2m[i] == INVALID_P2M_ENTRY ) {
            DPRINTF("Previous super page was populated wrongly!\n");
            return 1;
        }
    }

    page_array = (xen_pfn_t*)malloc(tot_pfns * sizeof(xen_pfn_t));
    save_buf = (uint8_t*)malloc(tot_pfns * PAGE_SIZE);

    if ( !page_array || !save_buf )
    {
        ERROR("alloc page_array failed\n");
        errno = ENOMEM;
        rc = 1;
        goto out;
    }

    /* save previous super page contents */
    for ( i = 0; i < tot_pfns; i++ )
    {
        /* only support HVM, as the mfn of the 2M page is missing */
        page_array[i] = start_pfn + i;
    }

    ram_base = xc_map_foreign_batch(xc_handle, dom, PROT_READ,
                                    page_array, tot_pfns);

    if ( ram_base == NULL )
    {
        ERROR("map batch failed\n");
        rc = 1;
        goto out;
    }

    memcpy(save_buf, ram_base, tot_pfns * PAGE_SIZE);
    munmap(ram_base, tot_pfns * PAGE_SIZE);

    /* free the super page */
    if ( xc_domain_memory_decrease_reservation(xc_handle, dom, 1,
                                   SUPERPAGE_PFN_SHIFT, &start_pfn) != 0 )
    {
        ERROR("free 2M page failure @ 0x%ld.\n", next_pfn);
        rc = 1;
        goto out;
    }

    start_pfn = next_pfn & ~(SUPERPAGE_NR_PFNS - 1);
    for ( i = start_pfn; i < start_pfn + SUPERPAGE_NR_PFNS; i++ )
    {
        p2m[i] = INVALID_P2M_ENTRY;
    }

    for ( i = start_pfn; i < start_pfn + tot_pfns; i++ )
    {
        mfn = i;
        if (xc_domain_memory_populate_physmap(xc_handle, dom, 1, 0,
                                              0, &mfn) != 0)
        {
            ERROR("Failed to allocate physical memory.!\n");
            errno = ENOMEM;
            rc = 1;
            goto out;
        }
        p2m[i] = mfn;
    }

    /* restore contents */
    for ( i = 0; i < tot_pfns; i++ )
    {
        page_array[i] = start_pfn + i;
    }

    ram_base = xc_map_foreign_batch(xc_handle, dom, PROT_WRITE,
                                    page_array, tot_pfns);
    if ( ram_base == NULL )
    {
        ERROR("map batch failed\n");
        rc = 1;
        goto out;
    }

    memcpy(ram_base, save_buf, tot_pfns * PAGE_SIZE);
    munmap(ram_base, tot_pfns * PAGE_SIZE);

out:
    free(page_array);
    free(save_buf);
    return rc;
}


/*
 * According to pfn list allocate pages: one 2M page or series of 4K pages.
 * Also optimistically allocate a 2M page even when not all pages in the 2M
 * extent come out, and fix it up in next batch:
 * If new pages fit the missing one in the 2M extent, do nothing; Else take
 * place of the original 2M page by some 4K pages.
 */
static int allocate_mfn_list(int xc_handle,
                              uint32_t dom,
                              unsigned long nr_extents,
                              xen_pfn_t *batch_buf,
                              xen_pfn_t *next_pfn,
                              int superpages)
{
    unsigned int i;
    unsigned long mfn, pfn, sp_pfn;

    /*Check if force super page, then clear it */
    unsigned force_super_page = !!(*next_pfn & FORCE_SP_MASK);
    *next_pfn &= ~FORCE_SP_MASK;

    sp_pfn = *next_pfn;

    if ( !superpages ||
         no_superpage_mem ||
         !SUPER_PAGE_TRACKING(sp_pfn) )
        goto normal_page;

    if ( !batch_buf )
    {
        /* Break previous 2M page, if 512 pages split across a batch boundary */
        if ( SUPER_PAGE_TRACKING(sp_pfn) &&
             !SUPER_PAGE_DONE(sp_pfn))
        {
            /* break previously allocated super page*/
            if ( break_super_page(xc_handle, dom, sp_pfn) != 0 )
            {
                ERROR("Break previous super page fail!\n");
                return 1;
            }
        }

        /* follwing pages fit the order in 2M extent */
        return 0;
    }

    /*
     * We try to allocate a 2M page only when:
     * user require this(superpages),
     * AND have enough memory,
     * AND is in the tracking,
     * AND tracked all pages in 2M extent, OR partial 2M extent for speculation
     * AND any page in 2M extent are not populated
     */
    if ( !SUPER_PAGE_DONE(sp_pfn) && !force_super_page )
        goto normal_page;

    pfn = batch_buf[0] & ~XEN_DOMCTL_PFINFO_LTAB_MASK;
    if  ( super_page_populated(pfn) )
        goto normal_page;

    pfn &= ~(SUPERPAGE_NR_PFNS - 1);
    mfn =  pfn;

    if ( xc_domain_memory_populate_physmap(xc_handle, dom, 1,
                SUPERPAGE_PFN_SHIFT, 0, &mfn) == 0)
    {
        for ( i = pfn; i < pfn + SUPERPAGE_NR_PFNS; i++, mfn++ )
        {
            p2m[i] = mfn;
        }
        return 0;
    }
    DPRINTF("No 2M page available for pfn 0x%lx, fall back to 4K page.\n",
            pfn);
    no_superpage_mem = 1;

normal_page:
    if ( !batch_buf )
        return 0;

    /* End the tracking, if want a 2M page but end by 4K pages, */
    *next_pfn = INVALID_SUPER_PAGE;

    for ( i = 0; i < nr_extents; i++ )
    {
        unsigned long pagetype = batch_buf[i] &  XEN_DOMCTL_PFINFO_LTAB_MASK;
        if ( pagetype == XEN_DOMCTL_PFINFO_XTAB )
            continue;

        pfn = mfn = batch_buf[i] & ~XEN_DOMCTL_PFINFO_LTAB_MASK;
        if ( p2m[pfn] == INVALID_P2M_ENTRY )
        {
            if (xc_domain_memory_populate_physmap(xc_handle, dom, 1, 0,
                        0, &mfn) != 0)
            {
                ERROR("Failed to allocate physical memory.! pfn=0x%lx, mfn=0x%lx.\n",
                        pfn, mfn);
                errno = ENOMEM;
                return 1;
            }
            p2m[pfn] = mfn;
        }
    }

    return 0;
}

static int allocate_physmem(int xc_handle, uint32_t dom,
                            unsigned long *region_pfn_type, int region_size,
                            unsigned int hvm, xen_pfn_t *region_mfn, int superpages)
{
    int i;
    unsigned long pfn;
    unsigned long pagetype;

    /* Next expected pfn in order to track a possible 2M page */
    static unsigned long required_pfn = INVALID_SUPER_PAGE;

    /* Buffer of pfn list for 2M page, or series of 4K pages */
    xen_pfn_t   *batch_buf;
    unsigned int batch_buf_len;

    if ( !superpages )
    {
        batch_buf     = &region_pfn_type[0];
        batch_buf_len = region_size;
        goto alloc_page;
    }

    batch_buf = NULL;
    batch_buf_len = 0;
    /* This loop tracks the possible 2M page */
    for (i = 0; i < region_size; i++)
    {
        pfn      = region_pfn_type[i] & ~XEN_DOMCTL_PFINFO_LTAB_MASK;
        pagetype = region_pfn_type[i] &  XEN_DOMCTL_PFINFO_LTAB_MASK;

        if (pagetype == XEN_DOMCTL_PFINFO_XTAB)
        {
            /* Do not start collecting pfns until get a valid pfn */
            if ( batch_buf_len != 0 )
                batch_buf_len++;
            continue;
        }

        if ( SUPER_PAGE_START(pfn) )
        {
            /* Start of a 2M extent, populate previsous buf */
            if ( allocate_mfn_list(xc_handle, dom,
                                   batch_buf_len, batch_buf,
                                   &required_pfn, superpages) != 0 )
            {
                errno = ENOMEM;
                return 1;
            }

            /* start new tracking for 2M page */
            batch_buf     = &region_pfn_type[i];
            batch_buf_len = 1;
            required_pfn  = pfn + 1;
        }
        else if ( pfn == required_pfn )
        {
            /* this page fit the 2M extent in order */
            batch_buf_len++;
            required_pfn++;
        }
        else if ( SUPER_PAGE_TRACKING(required_pfn) )
        {
            /* break of a 2M extent, populate previous buf */
            if ( allocate_mfn_list(xc_handle, dom,
                                   batch_buf_len, batch_buf,
                                   &required_pfn, superpages) != 0 )
            {
                errno = ENOMEM;
                return 1;
            }
            /* start new tracking for a series of 4K pages */
            batch_buf     = &region_pfn_type[i];
            batch_buf_len = 1;
            required_pfn  = INVALID_SUPER_PAGE;
        }
        else
        {
            /* this page is 4K */
            if ( !batch_buf )
                batch_buf = &region_pfn_type[i];
            batch_buf_len++;
        }
    }

    /*
     * populate rest batch_buf in the end.
     * In a speculative way, we allocate a 2M page even when not see all the
     * pages in order(set bit 31). If not require super page support,
     * we can skip the tracking loop and come here directly.
     * Speculative allocation can't be used for PV guest, as we have no mfn to
     * map previous 2M mem range if need break it.
     */
    if ( SUPER_PAGE_TRACKING(required_pfn) &&
         !SUPER_PAGE_DONE(required_pfn) )
    {
        if (hvm)
            required_pfn |= FORCE_SP_MASK;
        else
            required_pfn = INVALID_SUPER_PAGE;
    }

alloc_page:
    if ( batch_buf )
    {
        if ( allocate_mfn_list(xc_handle, dom,
                    batch_buf_len, batch_buf,
                    &required_pfn,
                    superpages) != 0 )
        {
            errno = ENOMEM;
            return 1;
        }
    }

    for (i = 0; i < region_size; i++)
    {
        pfn      = region_pfn_type[i] & ~XEN_DOMCTL_PFINFO_LTAB_MASK;
        pagetype = region_pfn_type[i] &  XEN_DOMCTL_PFINFO_LTAB_MASK;

        if ( pfn > p2m_size )
        {
            ERROR("pfn out of range");
            return 1;
        }
        if (pagetype == XEN_DOMCTL_PFINFO_XTAB)
        {
            region_mfn[i] = ~0UL;
        }
        else 
        {
            if (p2m[pfn] == INVALID_P2M_ENTRY)
            {
                DPRINTF("Warning: pfn 0x%lx are not allocated!\n", pfn);
                /*XXX:allocate this page?*/
            }

            /* setup region_mfn[] for batch map.
             * For HVM guests, this interface takes PFNs, not MFNs */
            region_mfn[i] = hvm ? pfn : p2m[pfn]; 
        }
    }
    return 0;
}


/* set when a consistent image is available */
static int completed = 0;

#define HEARTBEAT_MS 500

#ifndef __MINIOS__
static ssize_t read_exact_timed(int fd, void* buf, size_t size)
{
    size_t offset = 0;
    ssize_t len;
    struct timeval tv;
    fd_set rfds;

    while ( offset < size )
    {
        if ( completed ) {
            /* expect a heartbeat every HEARBEAT_MS ms maximum */
            tv.tv_sec = 0;
            tv.tv_usec = HEARTBEAT_MS * 1000;

            FD_ZERO(&rfds);
            FD_SET(fd, &rfds);
            len = select(fd + 1, &rfds, NULL, NULL, &tv);
            if ( !FD_ISSET(fd, &rfds) ) {
                fprintf(stderr, "read_exact_timed failed (select returned %zd)\n", len);
                return -1;
            }
        }

        len = read(fd, buf + offset, size - offset);
        if ( (len == -1) && ((errno == EINTR) || (errno == EAGAIN)) )
            continue;
        if ( len <= 0 )
            return -1;
        offset += len;
    }

    return 0;
}

#define read_exact read_exact_timed

#else
#define read_exact_timed read_exact
#endif
/*
** In the state file (or during transfer), all page-table pages are
** converted into a 'canonical' form where references to actual mfns
** are replaced with references to the corresponding pfns.
** This function inverts that operation, replacing the pfn values with
** the (now known) appropriate mfn values.
*/
static int uncanonicalize_pagetable(int xc_handle, uint32_t dom, 
                                    unsigned long type, void *page, int superpages)
{
    int i, pte_last;
    unsigned long pfn;
    uint64_t pte;

    pte_last = PAGE_SIZE / ((pt_levels == 2)? 4 : 8);

    for ( i = 0; i < pte_last; i++ )
    {
        if ( pt_levels == 2 )
            pte = ((uint32_t *)page)[i];
        else
            pte = ((uint64_t *)page)[i];
        
        /* XXX SMH: below needs fixing for PROT_NONE etc */
        if ( !(pte & _PAGE_PRESENT) )
            continue;
        
        pfn = (pte >> PAGE_SHIFT) & MFN_MASK_X86;

        /* Allocate mfn if necessary */
        if ( p2m[pfn] == INVALID_P2M_ENTRY )
        {
            unsigned long force_pfn = superpages ? FORCE_SP_MASK : pfn;
            if (allocate_mfn_list(xc_handle, dom,
                        1, &pfn, &force_pfn, superpages) != 0)
                return 0;
        }
        pte &= ~MADDR_MASK_X86;
        pte |= (uint64_t)p2m[pfn] << PAGE_SHIFT;

        if ( pt_levels == 2 )
            ((uint32_t *)page)[i] = (uint32_t)pte;
        else
            ((uint64_t *)page)[i] = (uint64_t)pte;
    }

    return 1;
}


/* Load the p2m frame list, plus potential extended info chunk */
static xen_pfn_t *load_p2m_frame_list(
    int io_fd, int *pae_extended_cr3, int *ext_vcpucontext)
{
    xen_pfn_t *p2m_frame_list;
    vcpu_guest_context_any_t ctxt;
    xen_pfn_t p2m_fl_zero;

    /* Read first entry of P2M list, or extended-info signature (~0UL). */
    if ( read_exact(io_fd, &p2m_fl_zero, sizeof(long)) )
    {
        ERROR("read extended-info signature failed");
        return NULL;
    }
    
    if ( p2m_fl_zero == ~0UL )
    {
        uint32_t tot_bytes;
        
        /* Next 4 bytes: total size of following extended info. */
        if ( read_exact(io_fd, &tot_bytes, sizeof(tot_bytes)) )
        {
            ERROR("read extended-info size failed");
            return NULL;
        }
        
        while ( tot_bytes )
        {
            uint32_t chunk_bytes;
            char     chunk_sig[4];
            
            /* 4-character chunk signature + 4-byte remaining chunk size. */
            if ( read_exact(io_fd, chunk_sig, sizeof(chunk_sig)) ||
                 read_exact(io_fd, &chunk_bytes, sizeof(chunk_bytes)) ||
                 (tot_bytes < (chunk_bytes + 8)) )
            {
                ERROR("read extended-info chunk signature failed");
                return NULL;
            }
            tot_bytes -= 8;

            /* VCPU context structure? */
            if ( !strncmp(chunk_sig, "vcpu", 4) )
            {
                /* Pick a guest word-size and PT depth from the ctxt size */
                if ( chunk_bytes == sizeof (ctxt.x32) )
                {
                    guest_width = 4;
                    if ( pt_levels > 2 ) 
                        pt_levels = 3; 
                }
                else if ( chunk_bytes == sizeof (ctxt.x64) )
                {
                    guest_width = 8;
                    pt_levels = 4;
                }
                else 
                {
                    ERROR("bad extended-info context size %d", chunk_bytes);
                    return NULL;
                }

                if ( read_exact(io_fd, &ctxt, chunk_bytes) )
                {
                    ERROR("read extended-info vcpu context failed");
                    return NULL;
                }
                tot_bytes -= chunk_bytes;
                chunk_bytes = 0;

                if ( GET_FIELD(&ctxt, vm_assist) 
                     & (1UL << VMASST_TYPE_pae_extended_cr3) )
                    *pae_extended_cr3 = 1;
            }
            else if ( !strncmp(chunk_sig, "extv", 4) )
            {
                *ext_vcpucontext = 1;
            }
            
            /* Any remaining bytes of this chunk: read and discard. */
            while ( chunk_bytes )
            {
                unsigned long sz = MIN(chunk_bytes, sizeof(xen_pfn_t));
                if ( read_exact(io_fd, &p2m_fl_zero, sz) )
                {
                    ERROR("read-and-discard extended-info chunk bytes failed");
                    return NULL;
                }
                chunk_bytes -= sz;
                tot_bytes   -= sz;
            }
        }

        /* Now read the real first entry of P2M list. */
        if ( read_exact(io_fd, &p2m_fl_zero, sizeof(xen_pfn_t)) )
        {
            ERROR("read first entry of p2m_frame_list failed");
            return NULL;
        }
    }

    /* Now that we know the guest's word-size, can safely allocate 
     * the p2m frame list */
    if ( (p2m_frame_list = malloc(P2M_TOOLS_FL_SIZE)) == NULL )
    {
        ERROR("Couldn't allocate p2m_frame_list array");
        return NULL;
    }

    /* First entry has already been read. */
    p2m_frame_list[0] = p2m_fl_zero;
    if ( read_exact(io_fd, &p2m_frame_list[1], 
                    (P2M_FL_ENTRIES - 1) * sizeof(xen_pfn_t)) )
    {
        ERROR("read p2m_frame_list failed");
        return NULL;
    }
    
    return p2m_frame_list;
}

typedef struct {
    int ishvm;
    union {
        struct tailbuf_pv {
            unsigned int pfncount;
            unsigned long* pfntab;
            unsigned int vcpucount;
            unsigned char* vcpubuf;
            unsigned char shared_info_page[PAGE_SIZE];
        } pv;
        struct tailbuf_hvm {
            uint64_t magicpfns[3];
            uint32_t hvmbufsize, reclen;
            uint8_t* hvmbuf;
            struct {
                uint32_t magic;
                uint32_t version;
                uint64_t len;
            } qemuhdr;
            uint32_t qemubufsize;
            uint8_t* qemubuf;
        } hvm;
    } u;
} tailbuf_t;

/* read stream until EOF, growing buffer as necssary */
static int compat_buffer_qemu(int fd, struct tailbuf_hvm *buf)
{
    uint8_t *qbuf, *tmp;
    int blen = 0, dlen = 0;
    int rc;

    /* currently save records tend to be about 7K */
    blen = 8192;
    if ( !(qbuf = malloc(blen)) ) {
        ERROR("Error allocating QEMU buffer");
        return -1;
    }

    while( (rc = read(fd, qbuf+dlen, blen-dlen)) > 0 ) {
        DPRINTF("Read %d bytes of QEMU data\n", rc);
        dlen += rc;

        if (dlen == blen) {
            DPRINTF("%d-byte QEMU buffer full, reallocating...\n", dlen);
            blen += 4096;
            tmp = realloc(qbuf, blen);
            if ( !tmp ) {
                ERROR("Error growing QEMU buffer to %d bytes", blen);
                free(qbuf);
                return -1;
            }
            qbuf = tmp;
        }
    }

    if ( rc < 0 ) {
        ERROR("Error reading QEMU data");
        free(qbuf);
        return -1;
    }

    if ( memcmp(qbuf, "QEVM", 4) ) {
        ERROR("Invalid QEMU magic: 0x%08x", *(unsigned long*)qbuf);
        free(qbuf);
        return -1;
    }

    buf->qemubuf = qbuf;
    buf->qemubufsize = dlen;

    return 0;
}

static int buffer_qemu(int fd, struct tailbuf_hvm *buf)
{
    uint32_t qlen;
    uint8_t *tmp;

    if ( read_exact(fd, &qlen, sizeof(qlen)) ) {
        ERROR("Error reading QEMU header length");
        return -1;
    }

    if ( qlen > buf->qemubufsize ) {
        if ( buf->qemubuf) {
            tmp = realloc(buf->qemubuf, qlen);
            if ( tmp )
                buf->qemubuf = tmp;
            else {
                ERROR("Error reallocating QEMU state buffer");
                return -1;
            }
        } else {
            buf->qemubuf = malloc(qlen);
            if ( !buf->qemubuf ) {
                ERROR("Error allocating QEMU state buffer");
                return -1;
            }
        }
    }
    buf->qemubufsize = qlen;

    if ( read_exact(fd, buf->qemubuf, buf->qemubufsize) ) {
        ERROR("Error reading QEMU state");
        return -1;
    }

    return 0;
}

static int dump_qemu(uint32_t dom, struct tailbuf_hvm *buf)
{
    int saved_errno;
    char path[256];
    FILE *fp;

    sprintf(path, "/var/lib/xen/qemu-save.%u", dom);
    fp = fopen(path, "wb");
    if ( !fp )
        return -1;

    DPRINTF("Writing %d bytes of QEMU data\n", buf->qemubufsize);
    if ( fwrite(buf->qemubuf, 1, buf->qemubufsize, fp) != buf->qemubufsize) {
        saved_errno = errno;
        fclose(fp);
        errno = saved_errno;
        return -1;
    }

    fclose(fp);

    return 0;
}

static int buffer_tail_hvm(struct tailbuf_hvm *buf, int fd,
                           unsigned int max_vcpu_id, uint64_t vcpumap,
                           int ext_vcpucontext)
{
    uint8_t *tmp;
    unsigned char qemusig[21];

    if ( read_exact(fd, buf->magicpfns, sizeof(buf->magicpfns)) ) {
        ERROR("Error reading magic PFNs");
        return -1;
    }

    if ( read_exact(fd, &buf->reclen, sizeof(buf->reclen)) ) {
        ERROR("Error reading HVM params size");
        return -1;
    }

    if ( buf->reclen > buf->hvmbufsize ) {
        if ( buf->hvmbuf) {
            tmp = realloc(buf->hvmbuf, buf->reclen);
            if ( tmp ) {
                buf->hvmbuf = tmp;
                buf->hvmbufsize = buf->reclen;
            } else {
                ERROR("Error reallocating HVM param buffer");
                return -1;
            }
        } else {
            buf->hvmbuf = malloc(buf->reclen);
            if ( !buf->hvmbuf ) {
                ERROR("Error allocating HVM param buffer");
                return -1;
            }
            buf->hvmbufsize = buf->reclen;
        }
    }

    if ( read_exact(fd, buf->hvmbuf, buf->reclen) ) {
        ERROR("Error reading HVM params");
        return -1;
    }

    if ( read_exact(fd, qemusig, sizeof(qemusig)) ) {
        ERROR("Error reading QEMU signature");
        return -1;
    }

    /* The normal live-migration QEMU record has no length information.
     * Short of reimplementing the QEMU parser, we're forced to just read
     * until EOF. Remus gets around this by sending a different signature
     * which includes a length prefix */
    if ( !memcmp(qemusig, "QemuDeviceModelRecord", sizeof(qemusig)) )
        return compat_buffer_qemu(fd, buf);
    else if ( !memcmp(qemusig, "RemusDeviceModelState", sizeof(qemusig)) )
        return buffer_qemu(fd, buf);

    qemusig[20] = '\0';
    ERROR("Invalid QEMU signature: %s", qemusig);
    return -1;
}

static int buffer_tail_pv(struct tailbuf_pv *buf, int fd,
                          unsigned int max_vcpu_id, uint64_t vcpumap,
                          int ext_vcpucontext)
{
    unsigned int i;
    size_t pfnlen, vcpulen;

    /* TODO: handle changing pfntab and vcpu counts */
    /* PFN tab */
    if ( read_exact(fd, &buf->pfncount, sizeof(buf->pfncount)) ||
         (buf->pfncount > (1U << 28)) ) /* up to 1TB of address space */
    {
        ERROR("Error when reading pfn count");
        return -1;
    }
    pfnlen = sizeof(unsigned long) * buf->pfncount;
    if ( !(buf->pfntab) ) {
        if ( !(buf->pfntab = malloc(pfnlen)) ) {
            ERROR("Error allocating PFN tail buffer");
            return -1;
        }
    }
    // DPRINTF("Reading PFN tab: %d bytes\n", pfnlen);
    if ( read_exact(fd, buf->pfntab, pfnlen) ) {
        ERROR("Error when reading pfntab");
        goto free_pfntab;
    }

    /* VCPU contexts */
    buf->vcpucount = 0;
    for (i = 0; i <= max_vcpu_id; i++) {
        // DPRINTF("vcpumap: %llx, cpu: %d, bit: %llu\n", vcpumap, i, (vcpumap % (1ULL << i)));
        if ( (!(vcpumap & (1ULL << i))) )
            continue;
        buf->vcpucount++;
    }
    // DPRINTF("VCPU count: %d\n", buf->vcpucount);
    vcpulen = ((guest_width == 8) ? sizeof(vcpu_guest_context_x86_64_t)
               : sizeof(vcpu_guest_context_x86_32_t)) * buf->vcpucount;
    if ( ext_vcpucontext )
        vcpulen += 128 * buf->vcpucount;

    if ( !(buf->vcpubuf) ) {
        if ( !(buf->vcpubuf = malloc(vcpulen)) ) {
            ERROR("Error allocating VCPU ctxt tail buffer");
            goto free_pfntab;
        }
    }
    // DPRINTF("Reading VCPUS: %d bytes\n", vcpulen);
    if ( read_exact(fd, buf->vcpubuf, vcpulen) ) {
        ERROR("Error when reading ctxt");
        goto free_vcpus;
    }

    /* load shared_info_page */
    // DPRINTF("Reading shared info: %lu bytes\n", PAGE_SIZE);
    if ( read_exact(fd, buf->shared_info_page, PAGE_SIZE) ) {
        ERROR("Error when reading shared info page");
        goto free_vcpus;
    }

    return 0;

  free_vcpus:
    if (buf->vcpubuf) {
        free (buf->vcpubuf);
        buf->vcpubuf = NULL;
    }
  free_pfntab:
    if (buf->pfntab) {
        free (buf->pfntab);
        buf->pfntab = NULL;
    }

    return -1;
}

static int buffer_tail(tailbuf_t *buf, int fd, unsigned int max_vcpu_id,
                       uint64_t vcpumap, int ext_vcpucontext)
{
    if ( buf->ishvm )
        return buffer_tail_hvm(&buf->u.hvm, fd, max_vcpu_id, vcpumap,
                               ext_vcpucontext);
    else
        return buffer_tail_pv(&buf->u.pv, fd, max_vcpu_id, vcpumap,
                              ext_vcpucontext);
}

static void tailbuf_free_hvm(struct tailbuf_hvm *buf)
{
    if ( buf->hvmbuf ) {
        free(buf->hvmbuf);
        buf->hvmbuf = NULL;
    }
    if ( buf->qemubuf ) {
        free(buf->qemubuf);
        buf->qemubuf = NULL;
    }
}

static void tailbuf_free_pv(struct tailbuf_pv *buf)
{
    if ( buf->vcpubuf ) {
        free(buf->vcpubuf);
        buf->vcpubuf = NULL;
    }
    if ( buf->pfntab ) {
        free(buf->pfntab);
        buf->pfntab = NULL;
    }
}

static void tailbuf_free(tailbuf_t *buf)
{
    if ( buf->ishvm )
        tailbuf_free_hvm(&buf->u.hvm);
    else
        tailbuf_free_pv(&buf->u.pv);
}

typedef struct {
    void* pages;
    /* pages is of length nr_physpages, pfn_types is of length nr_pages */
    unsigned int nr_physpages, nr_pages;

    /* Types of the pfns in the current region */
    unsigned long* pfn_types;

    int verify;

    int new_ctxt_format;
    int max_vcpu_id;
    uint64_t vcpumap;
    uint64_t identpt;
    uint64_t vm86_tss;
} pagebuf_t;

static int pagebuf_init(pagebuf_t* buf)
{
    memset(buf, 0, sizeof(*buf));
    return 0;
}

static void pagebuf_free(pagebuf_t* buf)
{
    if (buf->pages) {
        free(buf->pages);
        buf->pages = NULL;
    }
    if(buf->pfn_types) {
        free(buf->pfn_types);
        buf->pfn_types = NULL;
    }
}

static int pagebuf_get_one(pagebuf_t* buf, int fd, int xch, uint32_t dom)
{
    int count, countpages, oldcount, i;
    void* ptmp;

    if ( read_exact(fd, &count, sizeof(count)) )
    {
        ERROR("Error when reading batch size");
        return -1;
    }

    // DPRINTF("reading batch of %d pages\n", count);

    if (!count) {
        // DPRINTF("Last batch read\n");
        return 0;
    } else if (count == -1) {
        DPRINTF("Entering page verify mode\n");
        buf->verify = 1;
        return pagebuf_get_one(buf, fd, xch, dom);
    } else if (count == -2) {
        buf->new_ctxt_format = 1;
        if ( read_exact(fd, &buf->max_vcpu_id, sizeof(buf->max_vcpu_id)) ||
             buf->max_vcpu_id >= 64 || read_exact(fd, &buf->vcpumap,
                                                  sizeof(uint64_t)) ) {
            ERROR("Error when reading max_vcpu_id");
            return -1;
        }
        // DPRINTF("Max VCPU ID: %d, vcpumap: %llx\n", buf->max_vcpu_id, buf->vcpumap);
        return pagebuf_get_one(buf, fd, xch, dom);
    } else if (count == -3) {
        /* Skip padding 4 bytes then read the EPT identity PT location. */
        if ( read_exact(fd, &buf->identpt, sizeof(uint32_t)) ||
             read_exact(fd, &buf->identpt, sizeof(uint64_t)) )
        {
            ERROR("error read the address of the EPT identity map");
            return -1;
        }
        // DPRINTF("EPT identity map address: %llx\n", buf->identpt);
        return pagebuf_get_one(buf, fd, xch, dom);
    } else if ( count == -4 )  {
        /* Skip padding 4 bytes then read the vm86 TSS location. */
        if ( read_exact(fd, &buf->vm86_tss, sizeof(uint32_t)) ||
             read_exact(fd, &buf->vm86_tss, sizeof(uint64_t)) )
        {
            ERROR("error read the address of the vm86 TSS");
            return -1;
        }
        // DPRINTF("VM86 TSS location: %llx\n", buf->vm86_tss);
        return pagebuf_get_one(buf, fd, xch, dom);
    } else if ( count == -5 ) {
        DPRINTF("xc_domain_restore start tmem\n");
        if ( xc_tmem_restore(xch, dom, fd) ) {
            ERROR("error reading/restoring tmem");
            return -1;
        }
        return pagebuf_get_one(buf, fd, xch, dom);
    }
    else if ( count == -6 ) {
        if ( xc_tmem_restore_extra(xch, dom, fd) ) {
            ERROR("error reading/restoring tmem extra");
            return -1;
        }
        return pagebuf_get_one(buf, fd, xch, dom);
    } else if ( (count > MAX_BATCH_SIZE) || (count < 0) ) {
        ERROR("Max batch size exceeded (%d). Giving up.", count);
        return -1;
    }

    oldcount = buf->nr_pages;
    buf->nr_pages += count;
    if (!buf->pfn_types) {
        if (!(buf->pfn_types = malloc(buf->nr_pages * sizeof(*(buf->pfn_types))))) {
            ERROR("Could not allocate PFN type buffer");
            return -1;
        }
    } else {
        if (!(ptmp = realloc(buf->pfn_types, buf->nr_pages * sizeof(*(buf->pfn_types))))) {
            ERROR("Could not reallocate PFN type buffer");
            return -1;
        }
        buf->pfn_types = ptmp;
    }
    if ( read_exact(fd, buf->pfn_types + oldcount, count * sizeof(*(buf->pfn_types)))) {
        ERROR("Error when reading region pfn types");
        return -1;
    }

    countpages = count;
    for (i = oldcount; i < buf->nr_pages; ++i)
        if ((buf->pfn_types[i] & XEN_DOMCTL_PFINFO_LTAB_MASK) == XEN_DOMCTL_PFINFO_XTAB)
            --countpages;

    if (!countpages)
        return count;

    oldcount = buf->nr_physpages;
    buf->nr_physpages += countpages;
    if (!buf->pages) {
        if (!(buf->pages = malloc(buf->nr_physpages * PAGE_SIZE))) {
            ERROR("Could not allocate page buffer");
            return -1;
        }
    } else {
        if (!(ptmp = realloc(buf->pages, buf->nr_physpages * PAGE_SIZE))) {
            ERROR("Could not reallocate page buffer");
            return -1;
        }
        buf->pages = ptmp;
    }
    if ( read_exact(fd, buf->pages + oldcount * PAGE_SIZE, countpages * PAGE_SIZE) ) {
        ERROR("Error when reading pages");
        return -1;
    }

    return count;
}

static int pagebuf_get(pagebuf_t* buf, int fd, int xch, uint32_t dom)
{
    int rc;

    buf->nr_physpages = buf->nr_pages = 0;

    do {
        rc = pagebuf_get_one(buf, fd, xch, dom);
    } while (rc > 0);

    if (rc < 0)
        pagebuf_free(buf);

    return rc;
}

static int apply_batch(int xc_handle, uint32_t dom, xen_pfn_t* region_mfn,
                       unsigned long* pfn_type, int pae_extended_cr3,
                       unsigned int hvm, struct xc_mmu* mmu,
                       pagebuf_t* pagebuf, int curbatch, int superpages)
{
    int i, j, curpage;
    /* used by debug verify code */
    unsigned long buf[PAGE_SIZE/sizeof(unsigned long)];
    /* Our mapping of the current region (batch) */
    char *region_base;
    /* A temporary mapping, and a copy, of one frame of guest memory. */
    unsigned long *page = NULL;
    int nraces = 0;

    unsigned long mfn, pfn, pagetype;

    j = pagebuf->nr_pages - curbatch;
    if (j > MAX_BATCH_SIZE)
        j = MAX_BATCH_SIZE;

    if (allocate_physmem(xc_handle, dom, &pagebuf->pfn_types[curbatch],
                         j, hvm, region_mfn, superpages) != 0)
    {
        ERROR("allocate_physmem() failed\n");
        return -1;
    }

    /* Map relevant mfns */
    region_base = xc_map_foreign_batch(
        xc_handle, dom, PROT_WRITE, region_mfn, j);

    if ( region_base == NULL )
    {
        ERROR("map batch failed");
        return -1;
    }

    for ( i = 0, curpage = -1; i < j; i++ )
    {
        pfn      = pagebuf->pfn_types[i + curbatch] & ~XEN_DOMCTL_PFINFO_LTAB_MASK;
        pagetype = pagebuf->pfn_types[i + curbatch] &  XEN_DOMCTL_PFINFO_LTAB_MASK;

        if ( pagetype == XEN_DOMCTL_PFINFO_XTAB )
            /* a bogus/unmapped page: skip it */
            continue;

        ++curpage;

        if ( pfn > p2m_size )
        {
            ERROR("pfn out of range");
            return -1;
        }

        pfn_type[pfn] = pagetype;

        mfn = p2m[pfn];

        /* In verify mode, we use a copy; otherwise we work in place */
        page = pagebuf->verify ? (void *)buf : (region_base + i*PAGE_SIZE);

        memcpy(page, pagebuf->pages + (curpage + curbatch) * PAGE_SIZE, PAGE_SIZE);

        pagetype &= XEN_DOMCTL_PFINFO_LTABTYPE_MASK;

        if ( (pagetype >= XEN_DOMCTL_PFINFO_L1TAB) &&
             (pagetype <= XEN_DOMCTL_PFINFO_L4TAB) )
        {
            /*
            ** A page table page - need to 'uncanonicalize' it, i.e.
            ** replace all the references to pfns with the corresponding
            ** mfns for the new domain.
            **
            ** On PAE we need to ensure that PGDs are in MFNs < 4G, and
            ** so we may need to update the p2m after the main loop.
            ** Hence we defer canonicalization of L1s until then.
            */
            if ((pt_levels != 3) ||
                pae_extended_cr3 ||
                (pagetype != XEN_DOMCTL_PFINFO_L1TAB)) {

                if (!uncanonicalize_pagetable(xc_handle, dom,
                                              pagetype, page, superpages)) {
                    /*
                    ** Failing to uncanonicalize a page table can be ok
                    ** under live migration since the pages type may have
                    ** changed by now (and we'll get an update later).
                    */
                    DPRINTF("PT L%ld race on pfn=%08lx mfn=%08lx\n",
                            pagetype >> 28, pfn, mfn);
                    nraces++;
                    continue;
                }
            }
        }
        else if ( pagetype != XEN_DOMCTL_PFINFO_NOTAB )
        {
            ERROR("Bogus page type %lx page table is out of range: "
                  "i=%d p2m_size=%lu", pagetype, i, p2m_size);
            return -1;
        }

        if ( pagebuf->verify )
        {
            int res = memcmp(buf, (region_base + i*PAGE_SIZE), PAGE_SIZE);
            if ( res )
            {
                int v;

                DPRINTF("************** pfn=%lx type=%lx gotcs=%08lx "
                        "actualcs=%08lx\n", pfn, pagebuf->pfn_types[pfn],
                        csum_page(region_base + (i + curbatch)*PAGE_SIZE),
                        csum_page(buf));

                for ( v = 0; v < 4; v++ )
                {
                    unsigned long *p = (unsigned long *)
                        (region_base + i*PAGE_SIZE);
                    if ( buf[v] != p[v] )
                        DPRINTF("    %d: %08lx %08lx\n", v, buf[v], p[v]);
                }
            }
        }

        if ( !hvm &&
             xc_add_mmu_update(xc_handle, mmu,
                               (((unsigned long long)mfn) << PAGE_SHIFT)
                               | MMU_MACHPHYS_UPDATE, pfn) )
        {
            ERROR("failed machpys update mfn=%lx pfn=%lx", mfn, pfn);
            return -1;
        }
    } /* end of 'batch' for loop */

    munmap(region_base, j*PAGE_SIZE);

    return nraces;
}

int xc_domain_restore(int xc_handle, int io_fd, uint32_t dom,
                      unsigned int store_evtchn, unsigned long *store_mfn,
                      unsigned int console_evtchn, unsigned long *console_mfn,
                      unsigned int hvm, unsigned int pae, int superpages)
{
    DECLARE_DOMCTL;
    int rc = 1, frc, i, j, n, m, pae_extended_cr3 = 0, ext_vcpucontext = 0;
    unsigned long mfn, pfn;
    unsigned int prev_pc, this_pc;
    int nraces = 0;

    /* The new domain's shared-info frame number. */
    unsigned long shared_info_frame;
    unsigned char shared_info_page[PAGE_SIZE]; /* saved contents from file */
    shared_info_any_t *old_shared_info = 
        (shared_info_any_t *)shared_info_page;
    shared_info_any_t *new_shared_info;

    /* A copy of the CPU context of the guest. */
    vcpu_guest_context_any_t ctxt;

    /* A table containing the type of each PFN (/not/ MFN!). */
    unsigned long *pfn_type = NULL;

    /* A table of MFNs to map in the current region */
    xen_pfn_t *region_mfn = NULL;

    /* A copy of the pfn-to-mfn table frame list. */
    xen_pfn_t *p2m_frame_list = NULL;
    
    /* A temporary mapping of the guest's start_info page. */
    start_info_any_t *start_info;

    /* Our mapping of the current region (batch) */
    char *region_base;

    struct xc_mmu *mmu = NULL;

    struct mmuext_op pin[MAX_PIN_BATCH];
    unsigned int nr_pins;

    uint64_t vcpumap = 1ULL;
    unsigned int max_vcpu_id = 0;
    int new_ctxt_format = 0;

    pagebuf_t pagebuf;
    tailbuf_t tailbuf, tmptail;
    void* vcpup;

    pagebuf_init(&pagebuf);
    memset(&tailbuf, 0, sizeof(tailbuf));
    tailbuf.ishvm = hvm;

    /* For info only */
    nr_pfns = 0;

    /* Always try to allocate 2M pages for HVM */
    if ( hvm )
        superpages = 1;

    if ( read_exact(io_fd, &p2m_size, sizeof(unsigned long)) )
    {
        ERROR("read: p2m_size");
        goto out;
    }
    DPRINTF("xc_domain_restore start: p2m_size = %lx\n", p2m_size);

    if ( !get_platform_info(xc_handle, dom,
                            &max_mfn, &hvirt_start, &pt_levels, &guest_width) )
    {
        ERROR("Unable to get platform info.");
        return 1;
    }
    
    /* The *current* word size of the guest isn't very interesting; for now
     * assume the guest will be the same as we are.  We'll fix that later
     * if we discover otherwise. */
    guest_width = sizeof(unsigned long);
    pt_levels = (guest_width == 8) ? 4 : (pt_levels == 2) ? 2 : 3; 
    
    if ( !hvm ) 
    {
        /* Load the p2m frame list, plus potential extended info chunk */
        p2m_frame_list = load_p2m_frame_list(
            io_fd, &pae_extended_cr3, &ext_vcpucontext);
        if ( !p2m_frame_list )
            goto out;

        /* Now that we know the word size, tell Xen about it */
        memset(&domctl, 0, sizeof(domctl));
        domctl.domain = dom;
        domctl.cmd    = XEN_DOMCTL_set_address_size;
        domctl.u.address_size.size = guest_width * 8;
        frc = do_domctl(xc_handle, &domctl);
        if ( frc != 0 )
        {
            ERROR("Unable to set guest address size.");
            goto out;
        }
    }

    /* We want zeroed memory so use calloc rather than malloc. */
    p2m        = calloc(p2m_size, sizeof(xen_pfn_t));
    pfn_type   = calloc(p2m_size, sizeof(unsigned long));

    region_mfn = xg_memalign(PAGE_SIZE, ROUNDUP(
                              MAX_BATCH_SIZE * sizeof(xen_pfn_t), PAGE_SHIFT));

    if ( (p2m == NULL) || (pfn_type == NULL) ||
         (region_mfn == NULL) )
    {
        ERROR("memory alloc failed");
        errno = ENOMEM;
        goto out;
    }

    memset(region_mfn, 0,
           ROUNDUP(MAX_BATCH_SIZE * sizeof(xen_pfn_t), PAGE_SHIFT)); 

    if ( lock_pages(region_mfn, sizeof(xen_pfn_t) * MAX_BATCH_SIZE) )
    {
        ERROR("Could not lock region_mfn");
        goto out;
    }

    /* Get the domain's shared-info frame. */
    domctl.cmd = XEN_DOMCTL_getdomaininfo;
    domctl.domain = (domid_t)dom;
    if ( xc_domctl(xc_handle, &domctl) < 0 )
    {
        ERROR("Could not get information on new domain");
        goto out;
    }
    shared_info_frame = domctl.u.getdomaininfo.shared_info_frame;

    /* Mark all PFNs as invalid; we allocate on demand */
    for ( pfn = 0; pfn < p2m_size; pfn++ )
        p2m[pfn] = INVALID_P2M_ENTRY;

    mmu = xc_alloc_mmu_updates(xc_handle, dom);
    if ( mmu == NULL )
    {
        ERROR("Could not initialise for MMU updates");
        goto out;
    }

    DPRINTF("Reloading memory pages:   0%%\n");

    /*
     * Now simply read each saved frame into its new machine frame.
     * We uncanonicalise page tables as we go.
     */
    prev_pc = 0;

    n = m = 0;
 loadpages:
    for ( ; ; )
    {
        int j, curbatch;

        this_pc = (n * 100) / p2m_size;
        if ( (this_pc - prev_pc) >= 5 )
        {
            PPRINTF("\b\b\b\b%3d%%", this_pc);
            prev_pc = this_pc;
        }

        if ( !completed ) {
            pagebuf.nr_physpages = pagebuf.nr_pages = 0;
            if ( pagebuf_get_one(&pagebuf, io_fd, xc_handle, dom) < 0 ) {
                ERROR("Error when reading batch\n");
                goto out;
            }
        }
        j = pagebuf.nr_pages;

        PPRINTF("batch %d\n",j);

        if ( j == 0 ) {
            /* catch vcpu updates */
            if (pagebuf.new_ctxt_format) {
                vcpumap = pagebuf.vcpumap;
                max_vcpu_id = pagebuf.max_vcpu_id;
            }
            /* should this be deferred? does it change? */
            if ( pagebuf.identpt )
                xc_set_hvm_param(xc_handle, dom, HVM_PARAM_IDENT_PT, pagebuf.identpt);
            if ( pagebuf.vm86_tss )
                xc_set_hvm_param(xc_handle, dom, HVM_PARAM_VM86_TSS, pagebuf.vm86_tss);
            break;  /* our work here is done */
        }

        /* break pagebuf into batches */
        curbatch = 0;
        while ( curbatch < j ) {
            int brc;

            brc = apply_batch(xc_handle, dom, region_mfn, pfn_type,
                              pae_extended_cr3, hvm, mmu, &pagebuf, curbatch, superpages);
            if ( brc < 0 )
                goto out;

            nraces += brc;

            curbatch += MAX_BATCH_SIZE;
        }

        pagebuf.nr_physpages = pagebuf.nr_pages = 0;

        n += j; /* crude stats */

        /* 
         * Discard cache for portion of file read so far up to last
         *  page boundary every 16MB or so.
         */
        m += j;
        if ( m > MAX_PAGECACHE_USAGE )
        {
            discard_file_cache(io_fd, 0 /* no flush */);
            m = 0;
        }
    }

    /*
     * Ensure we flush all machphys updates before potential PAE-specific
     * reallocations below.
     */
    if ( !hvm && xc_flush_mmu_updates(xc_handle, mmu) )
    {
        ERROR("Error doing flush_mmu_updates()");
        goto out;
    }

    // DPRINTF("Received all pages (%d races)\n", nraces);

    if ( !completed ) {
        int flags = 0;

        if ( buffer_tail(&tailbuf, io_fd, max_vcpu_id, vcpumap,
                         ext_vcpucontext) < 0 ) {
            ERROR ("error buffering image tail");
            goto out;
        }
        completed = 1;
        /* shift into nonblocking mode for the remainder */
        if ( (flags = fcntl(io_fd, F_GETFL,0)) < 0 )
            flags = 0;
        fcntl(io_fd, F_SETFL, flags | O_NONBLOCK);
    }

    // DPRINTF("Buffered checkpoint\n");

    if ( pagebuf_get(&pagebuf, io_fd, xc_handle, dom) ) {
        ERROR("error when buffering batch, finishing\n");
        goto finish;
    }
    memset(&tmptail, 0, sizeof(tmptail));
    tmptail.ishvm = hvm;
    if ( buffer_tail(&tmptail, io_fd, max_vcpu_id, vcpumap,
                     ext_vcpucontext) < 0 ) {
        ERROR ("error buffering image tail, finishing");
        goto finish;
    }
    tailbuf_free(&tailbuf);
    memcpy(&tailbuf, &tmptail, sizeof(tailbuf));

    goto loadpages;

  finish:
    if ( hvm )
        goto finish_hvm;

    if ( (pt_levels == 3) && !pae_extended_cr3 )
    {
        /*
        ** XXX SMH on PAE we need to ensure PGDs are in MFNs < 4G. This
        ** is a little awkward and involves (a) finding all such PGDs and
        ** replacing them with 'lowmem' versions; (b) upating the p2m[]
        ** with the new info; and (c) canonicalizing all the L1s using the
        ** (potentially updated) p2m[].
        **
        ** This is relatively slow (and currently involves two passes through
        ** the pfn_type[] array), but at least seems to be correct. May wish
        ** to consider more complex approaches to optimize this later.
        */

        int j, k;
        
        /* First pass: find all L3TABs current in > 4G mfns and get new mfns */
        for ( i = 0; i < p2m_size; i++ )
        {
            if ( ((pfn_type[i] & XEN_DOMCTL_PFINFO_LTABTYPE_MASK) ==
                  XEN_DOMCTL_PFINFO_L3TAB) &&
                 (p2m[i] > 0xfffffUL) )
            {
                unsigned long new_mfn;
                uint64_t l3ptes[4];
                uint64_t *l3tab;

                l3tab = (uint64_t *)
                    xc_map_foreign_range(xc_handle, dom, PAGE_SIZE,
                                         PROT_READ, p2m[i]);

                for ( j = 0; j < 4; j++ )
                    l3ptes[j] = l3tab[j];

                munmap(l3tab, PAGE_SIZE);

                new_mfn = xc_make_page_below_4G(xc_handle, dom, p2m[i]);
                if ( !new_mfn )
                {
                    ERROR("Couldn't get a page below 4GB :-(");
                    goto out;
                }

                p2m[i] = new_mfn;
                if ( xc_add_mmu_update(xc_handle, mmu,
                                       (((unsigned long long)new_mfn)
                                        << PAGE_SHIFT) |
                                       MMU_MACHPHYS_UPDATE, i) )
                {
                    ERROR("Couldn't m2p on PAE root pgdir");
                    goto out;
                }

                l3tab = (uint64_t *)
                    xc_map_foreign_range(xc_handle, dom, PAGE_SIZE,
                                         PROT_READ | PROT_WRITE, p2m[i]);

                for ( j = 0; j < 4; j++ )
                    l3tab[j] = l3ptes[j];

                munmap(l3tab, PAGE_SIZE);
            }
        }

        /* Second pass: find all L1TABs and uncanonicalize them */
        j = 0;

        for ( i = 0; i < p2m_size; i++ )
        {
            if ( ((pfn_type[i] & XEN_DOMCTL_PFINFO_LTABTYPE_MASK) ==
                  XEN_DOMCTL_PFINFO_L1TAB) )
            {
                region_mfn[j] = p2m[i];
                j++;
            }

            if ( (i == (p2m_size-1)) || (j == MAX_BATCH_SIZE) )
            {
                region_base = xc_map_foreign_batch(
                    xc_handle, dom, PROT_READ | PROT_WRITE, region_mfn, j);
                if ( region_base == NULL )
                {
                    ERROR("map batch failed");
                    goto out;
                }

                for ( k = 0; k < j; k++ )
                {
                    if ( !uncanonicalize_pagetable(
                        xc_handle, dom, XEN_DOMCTL_PFINFO_L1TAB,
                        region_base + k*PAGE_SIZE, superpages) )
                    {
                        ERROR("failed uncanonicalize pt!");
                        goto out;
                    }
                }

                munmap(region_base, j*PAGE_SIZE);
                j = 0;
            }
        }

        if ( xc_flush_mmu_updates(xc_handle, mmu) )
        {
            ERROR("Error doing xc_flush_mmu_updates()");
            goto out;
        }
    }

    /*
     * Pin page tables. Do this after writing to them as otherwise Xen
     * will barf when doing the type-checking.
     */
    nr_pins = 0;
    for ( i = 0; i < p2m_size; i++ )
    {
        if ( (pfn_type[i] & XEN_DOMCTL_PFINFO_LPINTAB) == 0 )
            continue;

        switch ( pfn_type[i] & XEN_DOMCTL_PFINFO_LTABTYPE_MASK )
        {
        case XEN_DOMCTL_PFINFO_L1TAB:
            pin[nr_pins].cmd = MMUEXT_PIN_L1_TABLE;
            break;

        case XEN_DOMCTL_PFINFO_L2TAB:
            pin[nr_pins].cmd = MMUEXT_PIN_L2_TABLE;
            break;

        case XEN_DOMCTL_PFINFO_L3TAB:
            pin[nr_pins].cmd = MMUEXT_PIN_L3_TABLE;
            break;

        case XEN_DOMCTL_PFINFO_L4TAB:
            pin[nr_pins].cmd = MMUEXT_PIN_L4_TABLE;
            break;

        default:
            continue;
        }

        pin[nr_pins].arg1.mfn = p2m[i];
        nr_pins++;

        /* Batch full? Then flush. */
        if ( nr_pins == MAX_PIN_BATCH )
        {
            if ( xc_mmuext_op(xc_handle, pin, nr_pins, dom) < 0 )
            {
                ERROR("Failed to pin batch of %d page tables", nr_pins);
                goto out;
            }
            nr_pins = 0;
        }
    }

    /* Flush final partial batch. */
    if ( (nr_pins != 0) && (xc_mmuext_op(xc_handle, pin, nr_pins, dom) < 0) )
    {
        ERROR("Failed to pin batch of %d page tables", nr_pins);
        goto out;
    }

    DPRINTF("\b\b\b\b100%%\n");
    DPRINTF("Memory reloaded (%ld pages)\n", nr_pfns);

    /* Get the list of PFNs that are not in the psuedo-phys map */
    {
        int nr_frees = 0;

        for ( i = 0; i < tailbuf.u.pv.pfncount; i++ )
        {
            unsigned long pfn = tailbuf.u.pv.pfntab[i];

            if ( p2m[pfn] != INVALID_P2M_ENTRY )
            {
                /* pfn is not in physmap now, but was at some point during
                   the save/migration process - need to free it */
                tailbuf.u.pv.pfntab[nr_frees++] = p2m[pfn];
                p2m[pfn]  = INVALID_P2M_ENTRY; /* not in pseudo-physical map */
            }
        }

        if ( nr_frees > 0 )
        {
            struct xen_memory_reservation reservation = {
                .nr_extents   = nr_frees,
                .extent_order = 0,
                .domid        = dom
            };
            set_xen_guest_handle(reservation.extent_start, tailbuf.u.pv.pfntab);

            if ( (frc = xc_memory_op(xc_handle, XENMEM_decrease_reservation,
                                     &reservation)) != nr_frees )
            {
                ERROR("Could not decrease reservation : %d", frc);
                goto out;
            }
            else
                DPRINTF("Decreased reservation by %d pages\n", tailbuf.u.pv.pfncount);
        }
    }

    if ( lock_pages(&ctxt, sizeof(ctxt)) )
    {
        ERROR("Unable to lock ctxt");
        return 1;
    }

    vcpup = tailbuf.u.pv.vcpubuf;
    for ( i = 0; i <= max_vcpu_id; i++ )
    {
        if ( !(vcpumap & (1ULL << i)) )
            continue;

        memcpy(&ctxt, vcpup, ((guest_width == 8) ? sizeof(ctxt.x64)
                              : sizeof(ctxt.x32)));
        vcpup += (guest_width == 8) ? sizeof(ctxt.x64) : sizeof(ctxt.x32);

        DPRINTF("read VCPU %d\n", i);

        if ( !new_ctxt_format )
            SET_FIELD(&ctxt, flags, GET_FIELD(&ctxt, flags) | VGCF_online);

        if ( i == 0 )
        {
            /*
             * Uncanonicalise the suspend-record frame number and poke
             * resume record.
             */
            pfn = GET_FIELD(&ctxt, user_regs.edx);
            if ( (pfn >= p2m_size) ||
                 (pfn_type[pfn] != XEN_DOMCTL_PFINFO_NOTAB) )
            {
                ERROR("Suspend record frame number is bad");
                goto out;
            }
            mfn = p2m[pfn];
            SET_FIELD(&ctxt, user_regs.edx, mfn);
            start_info = xc_map_foreign_range(
                xc_handle, dom, PAGE_SIZE, PROT_READ | PROT_WRITE, mfn);
            SET_FIELD(start_info, nr_pages, p2m_size);
            SET_FIELD(start_info, shared_info, shared_info_frame<<PAGE_SHIFT);
            SET_FIELD(start_info, flags, 0);
            *store_mfn = p2m[GET_FIELD(start_info, store_mfn)];
            SET_FIELD(start_info, store_mfn, *store_mfn);
            SET_FIELD(start_info, store_evtchn, store_evtchn);
            *console_mfn = p2m[GET_FIELD(start_info, console.domU.mfn)];
            SET_FIELD(start_info, console.domU.mfn, *console_mfn);
            SET_FIELD(start_info, console.domU.evtchn, console_evtchn);
            munmap(start_info, PAGE_SIZE);
        }
        /* Uncanonicalise each GDT frame number. */
        if ( GET_FIELD(&ctxt, gdt_ents) > 8192 )
        {
            ERROR("GDT entry count out of range");
            goto out;
        }

        for ( j = 0; (512*j) < GET_FIELD(&ctxt, gdt_ents); j++ )
        {
            pfn = GET_FIELD(&ctxt, gdt_frames[j]);
            if ( (pfn >= p2m_size) ||
                 (pfn_type[pfn] != XEN_DOMCTL_PFINFO_NOTAB) )
            {
                ERROR("GDT frame number %i (0x%lx) is bad", 
                      j, (unsigned long)pfn);
                goto out;
            }
            SET_FIELD(&ctxt, gdt_frames[j], p2m[pfn]);
        }
        /* Uncanonicalise the page table base pointer. */
        pfn = UNFOLD_CR3(GET_FIELD(&ctxt, ctrlreg[3]));

        if ( pfn >= p2m_size )
        {
            ERROR("PT base is bad: pfn=%lu p2m_size=%lu type=%08lx",
                  pfn, p2m_size, pfn_type[pfn]);
            goto out;
        }

        if ( (pfn_type[pfn] & XEN_DOMCTL_PFINFO_LTABTYPE_MASK) !=
             ((unsigned long)pt_levels<<XEN_DOMCTL_PFINFO_LTAB_SHIFT) )
        {
            ERROR("PT base is bad. pfn=%lu nr=%lu type=%08lx %08lx",
                  pfn, p2m_size, pfn_type[pfn],
                  (unsigned long)pt_levels<<XEN_DOMCTL_PFINFO_LTAB_SHIFT);
            goto out;
        }
        SET_FIELD(&ctxt, ctrlreg[3], FOLD_CR3(p2m[pfn]));

        /* Guest pagetable (x86/64) stored in otherwise-unused CR1. */
        if ( (pt_levels == 4) && (ctxt.x64.ctrlreg[1] & 1) )
        {
            pfn = UNFOLD_CR3(ctxt.x64.ctrlreg[1] & ~1);
            if ( pfn >= p2m_size )
            {
                ERROR("User PT base is bad: pfn=%lu p2m_size=%lu",
                      pfn, p2m_size);
                goto out;
            }
            if ( (pfn_type[pfn] & XEN_DOMCTL_PFINFO_LTABTYPE_MASK) !=
                 ((unsigned long)pt_levels<<XEN_DOMCTL_PFINFO_LTAB_SHIFT) )
            {
                ERROR("User PT base is bad. pfn=%lu nr=%lu type=%08lx %08lx",
                      pfn, p2m_size, pfn_type[pfn],
                      (unsigned long)pt_levels<<XEN_DOMCTL_PFINFO_LTAB_SHIFT);
                goto out;
            }
            ctxt.x64.ctrlreg[1] = FOLD_CR3(p2m[pfn]);
        }
        domctl.cmd = XEN_DOMCTL_setvcpucontext;
        domctl.domain = (domid_t)dom;
        domctl.u.vcpucontext.vcpu = i;
        set_xen_guest_handle(domctl.u.vcpucontext.ctxt, &ctxt.c);
        frc = xc_domctl(xc_handle, &domctl);
        if ( frc != 0 )
        {
            ERROR("Couldn't build vcpu%d", i);
            goto out;
        }

        if ( !ext_vcpucontext )
            continue;
        memcpy(&domctl.u.ext_vcpucontext, vcpup, 128);
        vcpup += 128;
        domctl.cmd = XEN_DOMCTL_set_ext_vcpucontext;
        domctl.domain = dom;
        frc = xc_domctl(xc_handle, &domctl);
        if ( frc != 0 )
        {
            ERROR("Couldn't set extended vcpu%d info\n", i);
            goto out;
        }
    }

    memcpy(shared_info_page, tailbuf.u.pv.shared_info_page, PAGE_SIZE);

    DPRINTF("Completed checkpoint load\n");

    /* Restore contents of shared-info page. No checking needed. */
    new_shared_info = xc_map_foreign_range(
        xc_handle, dom, PAGE_SIZE, PROT_WRITE, shared_info_frame);

    /* restore saved vcpu_info and arch specific info */
    MEMCPY_FIELD(new_shared_info, old_shared_info, vcpu_info);
    MEMCPY_FIELD(new_shared_info, old_shared_info, arch);

    /* clear any pending events and the selector */
    MEMSET_ARRAY_FIELD(new_shared_info, evtchn_pending, 0);
    for ( i = 0; i < XEN_LEGACY_MAX_VCPUS; i++ )
	    SET_FIELD(new_shared_info, vcpu_info[i].evtchn_pending_sel, 0);

    /* mask event channels */
    MEMSET_ARRAY_FIELD(new_shared_info, evtchn_mask, 0xff);

    /* leave wallclock time. set by hypervisor */
    munmap(new_shared_info, PAGE_SIZE);

    /* Uncanonicalise the pfn-to-mfn table frame-number list. */
    for ( i = 0; i < P2M_FL_ENTRIES; i++ )
    {
        pfn = p2m_frame_list[i];
        if ( (pfn >= p2m_size) || (pfn_type[pfn] != XEN_DOMCTL_PFINFO_NOTAB) )
        {
            ERROR("PFN-to-MFN frame number %i (%#lx) is bad", i, pfn);
            goto out;
        }
        p2m_frame_list[i] = p2m[pfn];
    }

    /* Copy the P2M we've constructed to the 'live' P2M */
    if ( !(live_p2m = xc_map_foreign_batch(xc_handle, dom, PROT_WRITE,
                                           p2m_frame_list, P2M_FL_ENTRIES)) )
    {
        ERROR("Couldn't map p2m table");
        goto out;
    }

    /* If the domain we're restoring has a different word size to ours,
     * we need to adjust the live_p2m assignment appropriately */
    if ( guest_width > sizeof (xen_pfn_t) )
        for ( i = p2m_size - 1; i >= 0; i-- )
            ((int64_t *)live_p2m)[i] = (long)p2m[i];
    else if ( guest_width < sizeof (xen_pfn_t) )
        for ( i = 0; i < p2m_size; i++ )   
            ((uint32_t *)live_p2m)[i] = p2m[i];
    else
        memcpy(live_p2m, p2m, p2m_size * sizeof(xen_pfn_t));
    munmap(live_p2m, P2M_FL_ENTRIES * PAGE_SIZE);

    DPRINTF("Domain ready to be built.\n");
    rc = 0;
    goto out;

  finish_hvm:
    /* Dump the QEMU state to a state file for QEMU to load */
    if ( dump_qemu(dom, &tailbuf.u.hvm) ) {
        ERROR("Error dumping QEMU state to file");
        goto out;
    }

    /* These comms pages need to be zeroed at the start of day */
    if ( xc_clear_domain_page(xc_handle, dom, tailbuf.u.hvm.magicpfns[0]) ||
         xc_clear_domain_page(xc_handle, dom, tailbuf.u.hvm.magicpfns[1]) ||
         xc_clear_domain_page(xc_handle, dom, tailbuf.u.hvm.magicpfns[2]) )
    {
        ERROR("error zeroing magic pages");
        goto out;
    }

    if ( (frc = xc_set_hvm_param(xc_handle, dom,
                                 HVM_PARAM_IOREQ_PFN, tailbuf.u.hvm.magicpfns[0]))
         || (frc = xc_set_hvm_param(xc_handle, dom,
                                    HVM_PARAM_BUFIOREQ_PFN, tailbuf.u.hvm.magicpfns[1]))
         || (frc = xc_set_hvm_param(xc_handle, dom,
                                    HVM_PARAM_STORE_PFN, tailbuf.u.hvm.magicpfns[2]))
         || (frc = xc_set_hvm_param(xc_handle, dom,
                                    HVM_PARAM_PAE_ENABLED, pae))
         || (frc = xc_set_hvm_param(xc_handle, dom,
                                    HVM_PARAM_STORE_EVTCHN,
                                    store_evtchn)) )
    {
        ERROR("error setting HVM params: %i", frc);
        goto out;
    }
    *store_mfn = tailbuf.u.hvm.magicpfns[2];

    frc = xc_domain_hvm_setcontext(xc_handle, dom, tailbuf.u.hvm.hvmbuf,
                                   tailbuf.u.hvm.reclen);
    if ( frc )
    {
        ERROR("error setting the HVM context");
        goto out;
    }

    /* HVM success! */
    rc = 0;

 out:
    if ( (rc != 0) && (dom != 0) )
        xc_domain_destroy(xc_handle, dom);
    free(mmu);
    free(p2m);
    free(pfn_type);
    tailbuf_free(&tailbuf);

    /* discard cache for save file  */
    discard_file_cache(io_fd, 1 /*flush*/);

    DPRINTF("Restore exit with rc=%d\n", rc);
    
    return rc;
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

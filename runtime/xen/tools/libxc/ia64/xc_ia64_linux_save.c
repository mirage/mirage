/******************************************************************************
 * xc_ia64_linux_save.c
 *
 * Save the state of a running Linux session.
 *
 * Copyright (c) 2003, K A Fraser.
 *  Rewritten for ia64 by Tristan Gingold <tristan.gingold@bull.net>
 *
 * Copyright (c) 2007 Isaku Yamahata <yamahata@valinux.co.jp>
 *   Use foreign p2m exposure.
 *   VTi domain support.
 */

#include <inttypes.h>
#include <time.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>

#include "xg_private.h"
#include "xc_ia64.h"
#include "xc_ia64_save_restore.h"
#include "xc_efi.h"
#include "xen/hvm/params.h"

/*
** Default values for important tuning parameters. Can override by passing
** non-zero replacement values to xc_linux_save().
**
** XXX SMH: should consider if want to be able to override MAX_MBIT_RATE too.
**
*/
#define DEF_MAX_ITERS    (4 - 1)        /* limit us to 4 times round loop  */
#define DEF_MAX_FACTOR   3              /* never send more than 3x nr_pfns */

/*
** During (live) save/migrate, we maintain a number of bitmaps to track
** which pages we have to send, and to skip.
*/
static inline int test_bit(int nr, volatile void * addr)
{
    return (BITMAP_ENTRY(nr, addr) >> BITMAP_SHIFT(nr)) & 1;
}

static inline void clear_bit(int nr, volatile void * addr)
{
    BITMAP_ENTRY(nr, addr) &= ~(1UL << BITMAP_SHIFT(nr));
}

static inline void set_bit(int nr, volatile void * addr)
{
    BITMAP_ENTRY(nr, addr) |= (1UL << BITMAP_SHIFT(nr));
}

static int
suspend_and_state(int (*suspend)(void), int xc_handle, int io_fd,
                  int dom, xc_dominfo_t *info)
{
    if (!(*suspend)()) {
        ERROR("Suspend request failed");
        return -1;
    }

    if ( (xc_domain_getinfo(xc_handle, dom, 1, info) != 1) ||
         !info->shutdown || (info->shutdown_reason != SHUTDOWN_suspend) ) {
        ERROR("Could not get domain info");
        return -1;
    }

    return 0;
}

static inline int
md_is_not_ram(const efi_memory_desc_t *md)
{
    return ((md->type != EFI_CONVENTIONAL_MEMORY) ||
            (md->attribute != EFI_MEMORY_WB) ||
            (md->num_pages == 0));
}

/*
 * Send through a list of all the PFNs that were not in map at the close.
 * We send pages which was allocated. However balloon driver may 
 * decreased after sending page. So we have to check the freed
 * page after pausing the domain.
 */
static int
xc_ia64_send_unallocated_list(int xc_handle, int io_fd, 
                              struct xen_ia64_p2m_table *p2m_table,
                              xen_ia64_memmap_info_t *memmap_info, 
                              void *memmap_desc_start, void *memmap_desc_end)
{
    void *p;
    efi_memory_desc_t *md;

    unsigned long N;
    unsigned long pfntab[1024];
    unsigned int j;

    j = 0;
    for (p = memmap_desc_start;
         p < memmap_desc_end;
         p += memmap_info->efi_memdesc_size) {
        md = p;

        if (md_is_not_ram(md))
            continue;

        for (N = md->phys_addr >> PAGE_SHIFT;
             N < (md->phys_addr + (md->num_pages << EFI_PAGE_SHIFT)) >>
                 PAGE_SHIFT;
             N++) {
            if (!xc_ia64_p2m_allocated(p2m_table, N))
                j++;
        }
    }
    if (write_exact(io_fd, &j, sizeof(unsigned int))) {
        ERROR("Error when writing to state file (6a)");
        return -1;
    }
        
    j = 0;
    for (p = memmap_desc_start;
         p < memmap_desc_end;
         p += memmap_info->efi_memdesc_size) {
        md = p;

        if (md_is_not_ram(md))
            continue;

        for (N = md->phys_addr >> PAGE_SHIFT;
             N < (md->phys_addr + (md->num_pages << EFI_PAGE_SHIFT)) >>
                 PAGE_SHIFT;
             N++) {
            if (!xc_ia64_p2m_allocated(p2m_table, N))
                pfntab[j++] = N;
            if (j == sizeof(pfntab)/sizeof(pfntab[0])) {
                if (write_exact(io_fd, &pfntab, sizeof(pfntab[0]) * j)) {
                    ERROR("Error when writing to state file (6b)");
                    return -1;
                }
                j = 0;
            }
        }
    }
    if (j > 0) {
        if (write_exact(io_fd, &pfntab, sizeof(pfntab[0]) * j)) {
            ERROR("Error when writing to state file (6c)");
            return -1;
        }
    }

    return 0;
}

static int
xc_ia64_send_vcpu_context(int xc_handle, int io_fd, uint32_t dom,
                          uint32_t vcpu, vcpu_guest_context_any_t *ctxt_any)
{
    vcpu_guest_context_t *ctxt = &ctxt_any->c;
    if (xc_vcpu_getcontext(xc_handle, dom, vcpu, ctxt_any)) {
        ERROR("Could not get vcpu context");
        return -1;
    }

    if (write_exact(io_fd, ctxt, sizeof(*ctxt))) {
        ERROR("Error when writing to state file (1)");
        return -1;
    }

    fprintf(stderr, "ip=%016lx, b0=%016lx\n", ctxt->regs.ip, ctxt->regs.b[0]);
    return 0;
}

static int
xc_ia64_send_shared_info(int xc_handle, int io_fd, shared_info_t *live_shinfo)
{
    if (write_exact(io_fd, live_shinfo, PAGE_SIZE)) {
        ERROR("Error when writing to state file (1)");
        return -1;
    }
    return 0;
}

static int
xc_ia64_send_vcpumap(int xc_handle, int io_fd, uint32_t dom,
                     const xc_dominfo_t *info, uint64_t max_virt_cpus,
                     uint64_t **vcpumapp)
{
    int rc = -1;
    unsigned int i;
    unsigned long vcpumap_size;
    uint64_t *vcpumap = NULL;

    vcpumap_size = (max_virt_cpus + 1 + sizeof(vcpumap[0]) - 1) /
        sizeof(vcpumap[0]);
    vcpumap = malloc(vcpumap_size);
    if (vcpumap == NULL) {
        ERROR("memory alloc for vcpumap");
        goto out;
    }
    memset(vcpumap, 0, vcpumap_size);

    for (i = 0; i <= info->max_vcpu_id; i++) {
        xc_vcpuinfo_t vinfo;
        if ((xc_vcpu_getinfo(xc_handle, dom, i, &vinfo) == 0) && vinfo.online)
            __set_bit(i, vcpumap);
    }

    if (write_exact(io_fd, &max_virt_cpus, sizeof(max_virt_cpus))) {
        ERROR("write max_virt_cpus");
        goto out;
    }

    if (write_exact(io_fd, vcpumap, vcpumap_size)) {
        ERROR("write vcpumap");
        goto out;
    }

    rc = 0;

 out:
    if (rc != 0 && vcpumap != NULL) {
        free(vcpumap);
        vcpumap = NULL;
    }
    *vcpumapp = vcpumap;
    return rc;
}


static int
xc_ia64_pv_send_context(int xc_handle, int io_fd, uint32_t dom,
                        const xc_dominfo_t *info, shared_info_t *live_shinfo)
{
    int rc = -1;
    unsigned int i;

    /* vcpu map */
    uint64_t *vcpumap = NULL;
    if (xc_ia64_send_vcpumap(xc_handle, io_fd, dom, info, XEN_LEGACY_MAX_VCPUS,
                             &vcpumap))
        goto out;

    /* vcpu context */
    for (i = 0; i <= info->max_vcpu_id; i++) {
        /* A copy of the CPU context of the guest. */
        vcpu_guest_context_any_t ctxt_any;
        vcpu_guest_context_t *ctxt = &ctxt_any.c;

        char *mem;

        if (!__test_bit(i, vcpumap))
            continue;

        if (xc_ia64_send_vcpu_context(xc_handle, io_fd, dom, i, &ctxt_any))
            goto out;

        mem = xc_map_foreign_range(xc_handle, dom, PAGE_SIZE,
                                   PROT_READ|PROT_WRITE, ctxt->privregs_pfn);
        if (mem == NULL) {
            ERROR("cannot map privreg page");
            goto out;
        }
        if (write_exact(io_fd, mem, PAGE_SIZE)) {
            ERROR("Error when writing privreg to state file (5)");
            munmap(mem, PAGE_SIZE);
            goto out;
        }
        munmap(mem, PAGE_SIZE);
    }    

    rc = xc_ia64_send_shared_info(xc_handle, io_fd, live_shinfo);

 out:
    if (vcpumap != NULL)
        free(vcpumap);
    return rc;
}

static int
xc_ia64_hvm_send_context(int xc_handle, int io_fd, uint32_t dom,
                         const xc_dominfo_t *info, shared_info_t *live_shinfo)
{
    int rc = -1;
    unsigned int i;

    /* vcpu map */
    uint64_t *vcpumap = NULL;

    /* HVM: magic frames for ioreqs and xenstore comms */
    const int hvm_params[] = {
        HVM_PARAM_STORE_PFN,
        HVM_PARAM_IOREQ_PFN,
        HVM_PARAM_BUFIOREQ_PFN,
        HVM_PARAM_BUFPIOREQ_PFN,
    };
    const int NR_PARAMS = sizeof(hvm_params) / sizeof(hvm_params[0]);
    /* ioreq_pfn, bufioreq_pfn, store_pfn */
    uint64_t magic_pfns[NR_PARAMS];

    /* HVM: a buffer for holding HVM contxt */
    uint64_t rec_size;
    uint64_t hvm_buf_size = 0;
    uint8_t *hvm_buf = NULL;

    if (xc_ia64_send_shared_info(xc_handle, io_fd, live_shinfo))
        return -1;

    /* vcpu map */
    if (xc_ia64_send_vcpumap(xc_handle, io_fd, dom, info, XEN_LEGACY_MAX_VCPUS,
                             &vcpumap))
        goto out;

    /* vcpu context */
    for (i = 0; i <= info->max_vcpu_id; i++) {
        /* A copy of the CPU context of the guest. */
        vcpu_guest_context_any_t ctxt_any;

        if (!__test_bit(i, vcpumap))
            continue;

        if (xc_ia64_send_vcpu_context(xc_handle, io_fd, dom, i, &ctxt_any))
            goto out;

        /* system context of vcpu is sent as hvm context. */
    }    

    /* Save magic-page locations. */
    memset(magic_pfns, 0, sizeof(magic_pfns));
    for (i = 0; i < NR_PARAMS; i++) {
        if (xc_get_hvm_param(xc_handle, dom, hvm_params[i], &magic_pfns[i])) {
            PERROR("Error when xc_get_hvm_param");
            goto out;
        }
    }

    if (write_exact(io_fd, magic_pfns, sizeof(magic_pfns))) {
        ERROR("Error when writing to state file (7)");
        goto out;
    }

    /* Need another buffer for HVM context */
    hvm_buf_size = xc_domain_hvm_getcontext(xc_handle, dom, 0, 0);
    if (hvm_buf_size == -1) {
        ERROR("Couldn't get HVM context size from Xen");
        goto out;
    }

    hvm_buf = malloc(hvm_buf_size);
    if (!hvm_buf) {
        ERROR("Couldn't allocate memory");
        goto out;
    }

    /* Get HVM context from Xen and save it too */
    rec_size = xc_domain_hvm_getcontext(xc_handle, dom, hvm_buf, hvm_buf_size);
    if (rec_size == -1) {
        ERROR("HVM:Could not get hvm buffer");
        goto out;
    }
        
    if (write_exact(io_fd, &rec_size, sizeof(rec_size))) {
        ERROR("error write hvm buffer size");
        goto out;
    }
        
    if (write_exact(io_fd, hvm_buf, rec_size)) {
        ERROR("write HVM info failed!\n");
        goto out;
    }

    rc = 0;
out:
    if (hvm_buf != NULL)
        free(hvm_buf);
    if (vcpumap != NULL)
        free(vcpumap);
    return rc;
}

int
xc_domain_save(int xc_handle, int io_fd, uint32_t dom, uint32_t max_iters,
               uint32_t max_factor, uint32_t flags, int (*suspend)(void),
               int hvm, void (*switch_qemu_logdirty)(int, unsigned))
{
    DECLARE_DOMCTL;
    xc_dominfo_t info;

    int rc = 1;

    int debug = (flags & XCFLAGS_DEBUG);
    int live  = (flags & XCFLAGS_LIVE);

    /* The new domain's shared-info frame number. */
    unsigned long shared_info_frame;

    /* Live mapping of shared info structure */
    shared_info_t *live_shinfo = NULL;

    /* Iteration number.  */
    int iter;

    /* Number of pages sent in the last iteration (live only).  */
    unsigned int sent_last_iter;

    /* Number of pages sent (live only).  */
    unsigned int total_sent;

    /* total number of pages used by the current guest */
    unsigned long p2m_size;

    /* Size of the shadow bitmap (live only).  */
    unsigned int bitmap_size = 0;

    /* True if last iteration.  */
    int last_iter;

    /* Bitmap of pages to be sent.  */
    unsigned long *to_send = NULL;
    /* Bitmap of pages not to be sent (because dirtied).  */
    unsigned long *to_skip = NULL;

    char *mem;

    /* for foreign p2m exposure */
    unsigned long memmap_info_num_pages;
    /* Unsigned int was used before. To keep file format compatibility. */
    unsigned int memmap_info_num_pages_to_send;
    unsigned long memmap_size = 0;
    xen_ia64_memmap_info_t *memmap_info = NULL;
    void *memmap_desc_start;
    void *memmap_desc_end;
    void *p;
    efi_memory_desc_t *md;
    struct xen_ia64_p2m_table p2m_table;
    xc_ia64_p2m_init(&p2m_table);

    if (debug)
        fprintf(stderr, "xc_linux_save (ia64): started dom=%d\n", dom);

    /* If no explicit control parameters given, use defaults */
    if (!max_iters)
        max_iters = DEF_MAX_ITERS;
    if (!max_factor)
        max_factor = DEF_MAX_FACTOR;

    //initialize_mbit_rate();

    if (xc_domain_getinfo(xc_handle, dom, 1, &info) != 1) {
        ERROR("Could not get domain info");
        return 1;
    }

    shared_info_frame = info.shared_info_frame;

#if 0
    /* cheesy sanity check */
    if ((info.max_memkb >> (PAGE_SHIFT - 10)) > max_mfn) {
        ERROR("Invalid state record -- pfn count out of range: %lu",
            (info.max_memkb >> (PAGE_SHIFT - 10)));
        goto out;
     }
#endif

    /* Map the shared info frame */
    live_shinfo = xc_map_foreign_range(xc_handle, dom, PAGE_SIZE,
                                       PROT_READ, shared_info_frame);
    if (!live_shinfo) {
        ERROR("Couldn't map live_shinfo");
        goto out;
    }

    p2m_size = xc_memory_op(xc_handle, XENMEM_maximum_gpfn, &dom) + 1;

    /* This is expected by xm restore.  */
    if (write_exact(io_fd, &p2m_size, sizeof(unsigned long))) {
        ERROR("write: p2m_size");
        goto out;
    }

    /* xc_linux_restore starts to read here.  */
    /* Write a version number.  This can avoid searching for a stupid bug
       if the format change.
       The version is hard-coded, don't forget to change the restore code
       too!  */
    {
        unsigned long version = XC_IA64_SR_FORMAT_VER_CURRENT;

        if (write_exact(io_fd, &version, sizeof(unsigned long))) {
            ERROR("write: version");
            goto out;
        }
    }

    domctl.cmd = XEN_DOMCTL_arch_setup;
    domctl.domain = (domid_t)dom;
    domctl.u.arch_setup.flags = XEN_DOMAINSETUP_query;
    if (xc_domctl(xc_handle, &domctl) < 0) {
        ERROR("Could not get domain setup");
        goto out;
    }
    if (write_exact(io_fd, &domctl.u.arch_setup,
                     sizeof(domctl.u.arch_setup))) {
        ERROR("write: domain setup");
        goto out;
    }

    /* Domain is still running at this point */
    if (live) {

        if (xc_shadow_control(xc_handle, dom,
                              XEN_DOMCTL_SHADOW_OP_ENABLE_LOGDIRTY,
                              NULL, 0, NULL, 0, NULL ) < 0) {
            ERROR("Couldn't enable shadow mode");
            goto out;
        }

        last_iter = 0;

        bitmap_size = ((p2m_size + BITS_PER_LONG-1) & ~(BITS_PER_LONG-1)) / 8;
        to_send = malloc(bitmap_size);
        to_skip = malloc(bitmap_size);

        if (!to_send || !to_skip) {
            ERROR("Couldn't allocate bitmap array");
            goto out;
        }

        /* Initially all the pages must be sent.  */
        memset(to_send, 0xff, bitmap_size);

        if (lock_pages(to_send, bitmap_size)) {
            ERROR("Unable to lock_pages to_send");
            goto out;
        }
        if (lock_pages(to_skip, bitmap_size)) {
            ERROR("Unable to lock_pages to_skip");
            goto out;
        }

        /* Enable qemu-dm logging dirty pages to xen */
        if (hvm)
            switch_qemu_logdirty(dom, 1);
    } else {

        /* This is a non-live suspend. Issue the call back to get the
           domain suspended */

        last_iter = 1;

        if (suspend_and_state(suspend, xc_handle, io_fd, dom, &info)) {
            ERROR("Domain appears not to have suspended");
            goto out;
        }

    }

    /* copy before use in case someone updating them */
    if (xc_ia64_copy_memmap(xc_handle, info.domid, live_shinfo,
                            &memmap_info, &memmap_info_num_pages) != 0) {
        PERROR("Could not copy memmap");
        goto out;
    }
    memmap_size = memmap_info_num_pages << PAGE_SHIFT;

    if (xc_ia64_p2m_map(&p2m_table, xc_handle, dom, memmap_info, 0) < 0) {
        PERROR("xc_ia64_p2m_map");
        goto out;
    }
    memmap_info_num_pages_to_send = memmap_info_num_pages;
    if (write_exact(io_fd, &memmap_info_num_pages_to_send,
                    sizeof(memmap_info_num_pages_to_send))) {
        PERROR("write: arch.memmap_info_num_pages");
        goto out;
    }
    if (write_exact(io_fd, memmap_info, memmap_size)) {
        PERROR("write: memmap_info");
        goto out;
    }

    sent_last_iter = p2m_size;
    total_sent = 0;

    for (iter = 1; ; iter++) {
        unsigned int sent_this_iter, skip_this_iter;
        unsigned long N;

        sent_this_iter = 0;
        skip_this_iter = 0;

        /* Dirtied pages won't be saved.
           slightly wasteful to peek the whole array evey time,
           but this is fast enough for the moment. */
        if (!last_iter) {
            if (xc_shadow_control(xc_handle, dom,
                                  XEN_DOMCTL_SHADOW_OP_PEEK,
                                  to_skip, p2m_size,
                                  NULL, 0, NULL) != p2m_size) {
                ERROR("Error peeking shadow bitmap");
                goto out;
            }
        }

        /* Start writing out the saved-domain record. */
        memmap_desc_start = &memmap_info->memdesc;
        memmap_desc_end = memmap_desc_start + memmap_info->efi_memmap_size;
        for (p = memmap_desc_start;
             p < memmap_desc_end;
             p += memmap_info->efi_memdesc_size) {
            md = p;
            if (md_is_not_ram(md))
                continue;
            
            for (N = md->phys_addr >> PAGE_SHIFT;
                 N < (md->phys_addr + (md->num_pages << EFI_PAGE_SHIFT)) >>
                     PAGE_SHIFT;
                 N++) {

                if (!xc_ia64_p2m_allocated(&p2m_table, N))
                    continue;

                if (!last_iter) {
                    if (test_bit(N, to_skip) && test_bit(N, to_send))
                        skip_this_iter++;
                    if (test_bit(N, to_skip) || !test_bit(N, to_send))
                        continue;
                } else if (live) {
                    if (!test_bit(N, to_send))
                        continue;
                }

                if (debug)
                    fprintf(stderr, "xc_linux_save: page %lx (%lu/%lu)\n",
                            xc_ia64_p2m_mfn(&p2m_table, N),
                            N, p2m_size);

                mem = xc_map_foreign_range(xc_handle, dom, PAGE_SIZE,
                                           PROT_READ|PROT_WRITE, N);
                if (mem == NULL) {
                    /* The page may have move.
                       It will be remarked dirty.
                       FIXME: to be tracked.  */
                    fprintf(stderr, "cannot map mfn page %lx gpfn %lx: %s\n",
                            xc_ia64_p2m_mfn(&p2m_table, N),
                            N, safe_strerror(errno));
                    continue;
                }

                if (write_exact(io_fd, &N, sizeof(N))) {
                    ERROR("write: p2m_size");
                    munmap(mem, PAGE_SIZE);
                    goto out;
                }

                if (write(io_fd, mem, PAGE_SIZE) != PAGE_SIZE) {
                    ERROR("Error when writing to state file (5)");
                    munmap(mem, PAGE_SIZE);
                    goto out;
                }
                munmap(mem, PAGE_SIZE);
                sent_this_iter++;
                total_sent++;
            }
        }

        if (last_iter)
            break;

        DPRINTF(" %d: sent %d, skipped %d\n",
                iter, sent_this_iter, skip_this_iter );

        if (live) {
            if ( /* ((sent_this_iter > sent_last_iter) && RATE_IS_MAX()) || */
                (iter >= max_iters) || (sent_this_iter+skip_this_iter < 50) ||
                (total_sent > p2m_size*max_factor)) {
                DPRINTF("Start last iteration\n");
                last_iter = 1;

                if (suspend_and_state(suspend, xc_handle, io_fd, dom, &info)) {
                    ERROR("Domain appears not to have suspended");
                    goto out;
                }
            }

            /* Pages to be sent are pages which were dirty.  */
            if (xc_shadow_control(xc_handle, dom,
                                  XEN_DOMCTL_SHADOW_OP_CLEAN,
                                  to_send, p2m_size,
                                  NULL, 0, NULL ) != p2m_size) {
                ERROR("Error flushing shadow PT");
                goto out;
            }

            sent_last_iter = sent_this_iter;

            //print_stats(xc_handle, dom, sent_this_iter, &stats, 1);
        }
    }

    fprintf(stderr, "All memory is saved\n");

    /* terminate */
    {
        unsigned long pfn = INVALID_MFN;
        if (write_exact(io_fd, &pfn, sizeof(pfn))) {
            ERROR("Error when writing to state file (6)");
            goto out;
        }
    }

    if (xc_ia64_send_unallocated_list(xc_handle, io_fd, &p2m_table,
                                      memmap_info,
                                      memmap_desc_start, memmap_desc_end))
        goto out;

    if (!hvm)
        rc = xc_ia64_pv_send_context(xc_handle, io_fd,
                                     dom, &info, live_shinfo);
    else
        rc = xc_ia64_hvm_send_context(xc_handle, io_fd,
                                      dom, &info, live_shinfo);
    if (rc)
        goto out;

    /* Success! */
    rc = 0;

 out:

    if (live) {
        if (xc_shadow_control(xc_handle, dom,
                              XEN_DOMCTL_SHADOW_OP_OFF,
                              NULL, 0, NULL, 0, NULL ) < 0) {
            DPRINTF("Warning - couldn't disable shadow mode");
        }
        if ( hvm )
            switch_qemu_logdirty(dom, 0);
    }

    unlock_pages(to_send, bitmap_size);
    free(to_send);
    unlock_pages(to_skip, bitmap_size);
    free(to_skip);
    if (live_shinfo)
        munmap(live_shinfo, PAGE_SIZE);
    if (memmap_info)
        free(memmap_info);
    xc_ia64_p2m_unmap(&p2m_table);

    fprintf(stderr,"Save exit rc=%d\n",rc);

    return !!rc;
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

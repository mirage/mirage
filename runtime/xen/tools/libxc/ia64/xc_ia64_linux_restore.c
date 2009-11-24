/******************************************************************************
 * xc_ia64_linux_restore.c
 *
 * Restore the state of a Linux session.
 *
 * Copyright (c) 2003, K A Fraser.
 *  Rewritten for ia64 by Tristan Gingold <tristan.gingold@bull.net>
 *
 * Copyright (c) 2007 Isaku Yamahata <yamahata@valinux.co.jp>
 *   Use foreign p2m exposure.
 *   VTi domain support
 */

#include <stdlib.h>
#include <unistd.h>

#include "xg_private.h"
#include "xc_ia64_save_restore.h"
#include "xc_ia64.h"
#include "xc_efi.h"
#include "xen/hvm/params.h"

#define PFN_TO_KB(_pfn) ((_pfn) << (PAGE_SHIFT - 10))

/* number of pfns this guest has (i.e. number of entries in the P2M) */
static unsigned long p2m_size;

/* number of 'in use' pfns in the guest (i.e. #P2M entries with a valid mfn) */
static unsigned long nr_pfns;

static int
populate_page_if_necessary(int xc_handle, uint32_t dom, unsigned long gmfn,
                           struct xen_ia64_p2m_table *p2m_table)
{
    if (xc_ia64_p2m_present(p2m_table, gmfn))
        return 0;

    return xc_domain_memory_populate_physmap(xc_handle, dom, 1, 0, 0, &gmfn);
}

static int
read_page(int xc_handle, int io_fd, uint32_t dom, unsigned long pfn)
{
    void *mem;

    mem = xc_map_foreign_range(xc_handle, dom, PAGE_SIZE,
                               PROT_READ|PROT_WRITE, pfn);
    if (mem == NULL) {
        ERROR("cannot map page");
        return -1;
    }
    if (read_exact(io_fd, mem, PAGE_SIZE)) {
        ERROR("Error when reading from state file (5)");
        munmap(mem, PAGE_SIZE);
        return -1;
    }
    munmap(mem, PAGE_SIZE);
    return 0;
}

/*
 * Get the list of PFNs that are not in the psuedo-phys map.
 * Although we allocate pages on demand, balloon driver may 
 * decreased simaltenously. So we have to free the freed
 * pages here.
 */
static int
xc_ia64_recv_unallocated_list(int xc_handle, int io_fd, uint32_t dom,
                              struct xen_ia64_p2m_table *p2m_table)
{
    int rc = -1;
    unsigned int i;
    unsigned int count;
    unsigned long *pfntab = NULL;
    unsigned int nr_frees;

    if (read_exact(io_fd, &count, sizeof(count))) {
        ERROR("Error when reading pfn count");
        goto out;
    }

    pfntab = malloc(sizeof(unsigned long) * count);
    if (pfntab == NULL) {
        ERROR("Out of memory");
        goto out;
    }

    if (read_exact(io_fd, pfntab, sizeof(unsigned long)*count)) {
        ERROR("Error when reading pfntab");
        goto out;
    }

    nr_frees = 0;
    for (i = 0; i < count; i++) {
        if (xc_ia64_p2m_allocated(p2m_table, pfntab[i])) {
            pfntab[nr_frees] = pfntab[i];
            nr_frees++;
        }
    }
    if (nr_frees > 0) {
        if (xc_domain_memory_decrease_reservation(xc_handle, dom, nr_frees,
                                                  0, pfntab) < 0) {
            PERROR("Could not decrease reservation");
            goto out;
        } else
            DPRINTF("Decreased reservation by %d / %d pages\n",
                    nr_frees, count);
    }

    rc = 0;
    
 out:
    if (pfntab != NULL)
        free(pfntab);
    return rc;
}

static int
xc_ia64_recv_vcpu_context(int xc_handle, int io_fd, uint32_t dom,
                          uint32_t vcpu, vcpu_guest_context_any_t *ctxt_any)
{
    vcpu_guest_context_t *ctxt = &ctxt_any->c;
    if (read_exact(io_fd, ctxt, sizeof(*ctxt))) {
        ERROR("Error when reading ctxt");
        return -1;
    }

    fprintf(stderr, "ip=%016lx, b0=%016lx\n", ctxt->regs.ip, ctxt->regs.b[0]);

    /* Initialize and set registers.  */
    ctxt->flags = VGCF_EXTRA_REGS | VGCF_SET_CR_IRR | VGCF_online |
        VGCF_SET_AR_ITC;
    if (xc_vcpu_setcontext(xc_handle, dom, vcpu, ctxt_any) != 0) {
        ERROR("Couldn't set vcpu context");
        return -1;
    }

    /* Just a check.  */
    ctxt->flags = 0;
    if (xc_vcpu_getcontext(xc_handle, dom, vcpu, ctxt_any)) {
        ERROR("Could not get vcpu context");
        return -1;
    }

    return 0;
}

/* Read shared info.  */
static int
xc_ia64_recv_shared_info(int xc_handle, int io_fd, uint32_t dom,
                         unsigned long shared_info_frame,
                         unsigned long *start_info_pfn)
{
    unsigned int i;

    /* The new domain's shared-info frame. */
    shared_info_t *shared_info;
    
    /* Read shared info.  */
    shared_info = xc_map_foreign_range(xc_handle, dom, PAGE_SIZE,
                                       PROT_READ|PROT_WRITE,
                                       shared_info_frame);
    if (shared_info == NULL) {
        ERROR("cannot map page");
        return -1;
    }

    if (read_exact(io_fd, shared_info, PAGE_SIZE)) {
        ERROR("Error when reading shared_info page");
        munmap(shared_info, PAGE_SIZE);
        return -1;
    }

    /* clear any pending events and the selector */
    memset(&(shared_info->evtchn_pending[0]), 0,
           sizeof (shared_info->evtchn_pending));
    for (i = 0; i < XEN_LEGACY_MAX_VCPUS; i++)
        shared_info->vcpu_info[i].evtchn_pending_sel = 0;

    if (start_info_pfn != NULL)
        *start_info_pfn = shared_info->arch.start_info_pfn;

    munmap (shared_info, PAGE_SIZE);

    return 0;
}

static int
xc_ia64_recv_vcpumap(const xc_dominfo_t *info, int io_fd, uint64_t **vcpumapp)
{
    uint64_t max_virt_cpus;
    unsigned long vcpumap_size;
    uint64_t *vcpumap = NULL;

    *vcpumapp = NULL;
    
    if (read_exact(io_fd, &max_virt_cpus, sizeof(max_virt_cpus))) {
        ERROR("error reading max_virt_cpus");
        return -1;
    }
    if (max_virt_cpus < info->max_vcpu_id) {
        ERROR("too large max_virt_cpus %i < %i\n",
              max_virt_cpus, info->max_vcpu_id);
        return -1;
    }
    vcpumap_size = (max_virt_cpus + 1 + sizeof(vcpumap[0]) - 1) /
        sizeof(vcpumap[0]);
    vcpumap = malloc(vcpumap_size);
    if (vcpumap == NULL) {
        ERROR("memory alloc for vcpumap");
        return -1;
    }
    memset(vcpumap, 0, vcpumap_size);
    if (read_exact(io_fd, vcpumap, vcpumap_size)) {
        ERROR("read vcpumap");
        free(vcpumap);
        return -1;
    }

    *vcpumapp = vcpumap;
    return 0;
}

static int
xc_ia64_pv_recv_vcpu_context(int xc_handle, int io_fd, int32_t dom,
                             uint32_t vcpu)
{
    int rc = -1;

    /* A copy of the CPU context of the guest. */
    vcpu_guest_context_any_t ctxt_any;
    vcpu_guest_context_t *ctxt = &ctxt_any.c;

    if (lock_pages(&ctxt_any, sizeof(ctxt_any))) {
        /* needed for build domctl, but might as well do early */
        ERROR("Unable to lock_pages ctxt");
        return -1;
    }

    if (xc_ia64_recv_vcpu_context(xc_handle, io_fd, dom, vcpu, &ctxt_any))
        goto out;

    /* Then get privreg page.  */
    if (read_page(xc_handle, io_fd, dom, ctxt->privregs_pfn) < 0) {
        ERROR("Could not read vcpu privregs");
        goto out;
    }

    rc = 0;

 out:
    unlock_pages(&ctxt, sizeof(ctxt));
    return rc;
}

static int
xc_ia64_pv_recv_shared_info(int xc_handle, int io_fd, int32_t dom, 
                            unsigned long shared_info_frame,
                            struct xen_ia64_p2m_table *p2m_table,
                            unsigned int store_evtchn,
                            unsigned long *store_mfn,
                            unsigned int console_evtchn,
                            unsigned long *console_mfn)
{
    unsigned long gmfn;

    /* A temporary mapping of the guest's start_info page. */
    start_info_t *start_info;
    
    /* Read shared info.  */
    if (xc_ia64_recv_shared_info(xc_handle, io_fd, dom,
                                 shared_info_frame, &gmfn))
        return -1;

    /* Uncanonicalise the suspend-record frame number and poke resume rec. */
    if (populate_page_if_necessary(xc_handle, dom, gmfn, p2m_table)) {
        ERROR("cannot populate page 0x%lx", gmfn);
        return -1;
    }
    start_info = xc_map_foreign_range(xc_handle, dom, PAGE_SIZE,
                                      PROT_READ | PROT_WRITE, gmfn);
    if (start_info == NULL) {
        ERROR("cannot map start_info page");
        return -1;
    }
    start_info->nr_pages = p2m_size;
    start_info->shared_info = shared_info_frame << PAGE_SHIFT;
    start_info->flags = 0;
    *store_mfn = start_info->store_mfn;
    start_info->store_evtchn = store_evtchn;
    *console_mfn = start_info->console.domU.mfn;
    start_info->console.domU.evtchn = console_evtchn;
    munmap(start_info, PAGE_SIZE);

    return 0;
}

static int
xc_ia64_pv_recv_context_ver_one_or_two(int xc_handle, int io_fd, uint32_t dom,
                                       unsigned long shared_info_frame,
                                       struct xen_ia64_p2m_table *p2m_table,
                                       unsigned int store_evtchn,
                                       unsigned long *store_mfn,
                                       unsigned int console_evtchn,
                                       unsigned long *console_mfn)
{
    int rc;

    /* vcpu 0 context */
    rc = xc_ia64_pv_recv_vcpu_context(xc_handle, io_fd, dom, 0);
    if (rc)
        return rc;


    /* shared_info */
    rc = xc_ia64_pv_recv_shared_info(xc_handle, io_fd, dom, shared_info_frame,
                                     p2m_table, store_evtchn, store_mfn,
                                     console_evtchn, console_mfn);
    return rc;
}

static int
xc_ia64_pv_recv_context_ver_three(int xc_handle, int io_fd, uint32_t dom,
                                  unsigned long shared_info_frame,
                                  struct xen_ia64_p2m_table *p2m_table,
                                  unsigned int store_evtchn,
                                  unsigned long *store_mfn,
                                  unsigned int console_evtchn,
                                  unsigned long *console_mfn)
{
    int rc = -1;
    xc_dominfo_t info;
    unsigned int i;
    
    /* vcpu map */
    uint64_t *vcpumap = NULL;
    
    if (xc_domain_getinfo(xc_handle, dom, 1, &info) != 1) {
        ERROR("Could not get domain info");
        return -1;
    }
    rc = xc_ia64_recv_vcpumap(&info, io_fd, &vcpumap);
    if (rc != 0)
        goto out;

    /* vcpu context */
    for (i = 0; i <= info.max_vcpu_id; i++) {
        if (!__test_bit(i, vcpumap))
            continue;

        rc = xc_ia64_pv_recv_vcpu_context(xc_handle, io_fd, dom, i);
        if (rc != 0)
            goto out;
    }    

    /* shared_info */
    rc = xc_ia64_pv_recv_shared_info(xc_handle, io_fd, dom, shared_info_frame,
                                     p2m_table, store_evtchn, store_mfn,
                                     console_evtchn, console_mfn);
 out:
    if (vcpumap != NULL)
        free(vcpumap);
    return rc;
}

static int
xc_ia64_pv_recv_context(unsigned long format_version,
                        int xc_handle, int io_fd, uint32_t dom,
                        unsigned long shared_info_frame,
                        struct xen_ia64_p2m_table *p2m_table,
                        unsigned int store_evtchn,
                        unsigned long *store_mfn,
                        unsigned int console_evtchn,
                        unsigned long *console_mfn)
{
    int rc;
    switch (format_version) {
    case XC_IA64_SR_FORMAT_VER_ONE:
    case XC_IA64_SR_FORMAT_VER_TWO:
        rc = xc_ia64_pv_recv_context_ver_one_or_two(xc_handle, io_fd, dom,
                                                    shared_info_frame,
                                                    p2m_table, store_evtchn,
                                                    store_mfn, console_evtchn,
                                                    console_mfn);
        break;
    case XC_IA64_SR_FORMAT_VER_THREE:
        rc = xc_ia64_pv_recv_context_ver_three(xc_handle, io_fd, dom,
                                               shared_info_frame,
                                               p2m_table, store_evtchn,
                                               store_mfn, console_evtchn,
                                               console_mfn);
        break;
    default:
        ERROR("Unsupported format version");
        rc = -1;
        break;
    }
    return rc;
}

static int
xc_ia64_hvm_recv_context(int xc_handle, int io_fd, uint32_t dom,
                         unsigned long shared_info_frame,
                         struct xen_ia64_p2m_table *p2m_table,
                         unsigned int store_evtchn, unsigned long *store_mfn,
                         unsigned int console_evtchn,
                         unsigned long *console_mfn)
{
    int rc = -1;
    xc_dominfo_t info;
    unsigned int i;
    
    /* cpumap */
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
    uint64_t rec_size = 0;
    uint8_t *hvm_buf = NULL;

    /* Read shared info.  */
    if (xc_ia64_recv_shared_info(xc_handle, io_fd, dom, shared_info_frame,
                                 NULL))
        goto out;

    /* vcpu map */
    if (xc_domain_getinfo(xc_handle, dom, 1, &info) != 1) {
        ERROR("Could not get domain info");
        goto out;
    }
    if (xc_ia64_recv_vcpumap(&info, io_fd, &vcpumap))
        goto out;
    
    /* vcpu context */
    for (i = 0; i <= info.max_vcpu_id; i++) {
        /* A copy of the CPU context of the guest. */
        vcpu_guest_context_any_t ctxt_any;

        if (!__test_bit(i, vcpumap))
            continue;

        if (xc_ia64_recv_vcpu_context(xc_handle, io_fd, dom, i, &ctxt_any))
            goto out;

        /* system context of vcpu is recieved as hvm context. */
    }    

    /* Set HVM-specific parameters */
    if (read_exact(io_fd, magic_pfns, sizeof(magic_pfns))) {
        ERROR("error reading magic page addresses");
        goto out;
    }

    /* These comms pages need to be zeroed at the start of day */
    for (i = 0; i < NR_PARAMS; i++) {
        rc = xc_clear_domain_page(xc_handle, dom, magic_pfns[i]);
        if (rc != 0) {
            ERROR("error zeroing magic pages: %i", rc);
            goto out;
        }
        rc = xc_set_hvm_param(xc_handle, dom, hvm_params[i], magic_pfns[i]);
        if (rc != 0) {
            ERROR("error setting HVM params: %i", rc);
            goto out;
        }
    }
    rc = xc_set_hvm_param(xc_handle, dom,
                          HVM_PARAM_STORE_EVTCHN, store_evtchn);
    if (rc != 0) {
        ERROR("error setting HVM params: %i", rc);
        goto out;
    }
    rc = -1;
    *store_mfn = magic_pfns[0];

    /* Read HVM context */
    if (read_exact(io_fd, &rec_size, sizeof(rec_size))) {
        ERROR("error read hvm context size!\n");
        goto out;
    }

    hvm_buf = malloc(rec_size);
    if (hvm_buf == NULL) {
        ERROR("memory alloc for hvm context buffer failed");
        errno = ENOMEM;
        goto out;
    }

    if (read_exact(io_fd, hvm_buf, rec_size)) {
        ERROR("error loading the HVM context");
        goto out;
    }

    rc = xc_domain_hvm_setcontext(xc_handle, dom, hvm_buf, rec_size);
    if (rc != 0) {
        ERROR("error setting the HVM context");
        goto out;
    }
       
    rc = 0;

out:
    if (vcpumap != NULL)
        free(vcpumap);
    if (hvm_buf != NULL)
        free(hvm_buf);
    return rc;
}

/*
 * hvm domain requires IO pages allocated when XEN_DOMCTL_arch_setup
 */
static int
xc_ia64_hvm_domain_setup(int xc_handle, uint32_t dom)
{
    int rc;
    xen_pfn_t pfn_list[] = {
        IO_PAGE_START >> PAGE_SHIFT,
        BUFFER_IO_PAGE_START >> PAGE_SHIFT,
        BUFFER_PIO_PAGE_START >> PAGE_SHIFT,
    };
    unsigned long nr_pages = sizeof(pfn_list) / sizeof(pfn_list[0]);

    rc = xc_domain_memory_populate_physmap(xc_handle, dom, nr_pages,
                                           0, 0, &pfn_list[0]);
    if (rc != 0)
        PERROR("Could not allocate IO page or buffer io page.\n");
    return rc;
}

int
xc_domain_restore(int xc_handle, int io_fd, uint32_t dom,
                  unsigned int store_evtchn, unsigned long *store_mfn,
                  unsigned int console_evtchn, unsigned long *console_mfn,
                  unsigned int hvm, unsigned int pae, int superpages)
{
    DECLARE_DOMCTL;
    int rc = 1;
    unsigned long ver;

    /* The new domain's shared-info frame number. */
    unsigned long shared_info_frame;

    struct xen_ia64_p2m_table p2m_table;
    xc_ia64_p2m_init(&p2m_table);

    /* For info only */
    nr_pfns = 0;

    if ( read_exact(io_fd, &p2m_size, sizeof(unsigned long)) )
    {
        ERROR("read: p2m_size");
        goto out;
    }
    DPRINTF("xc_linux_restore start: p2m_size = %lx\n", p2m_size);

    if (read_exact(io_fd, &ver, sizeof(unsigned long))) {
        ERROR("Error when reading version");
        goto out;
    }
    if (ver != XC_IA64_SR_FORMAT_VER_ONE &&
        ver != XC_IA64_SR_FORMAT_VER_TWO &&
        ver != XC_IA64_SR_FORMAT_VER_THREE) {
        ERROR("version of save doesn't match");
        goto out;
    }

    if (read_exact(io_fd, &domctl.u.arch_setup, sizeof(domctl.u.arch_setup))) {
        ERROR("read: domain setup");
        goto out;
    }

    if (hvm && xc_ia64_hvm_domain_setup(xc_handle, dom) != 0)
        goto out;
    
    /* Build firmware (will be overwritten).  */
    domctl.domain = (domid_t)dom;
    domctl.u.arch_setup.flags &= ~XEN_DOMAINSETUP_query;
    domctl.u.arch_setup.bp = 0; /* indicate domain restore */
    
    domctl.cmd = XEN_DOMCTL_arch_setup;
    if (xc_domctl(xc_handle, &domctl))
        goto out;

    /* Get the domain's shared-info frame. */
    domctl.cmd = XEN_DOMCTL_getdomaininfo;
    domctl.domain = (domid_t)dom;
    if (xc_domctl(xc_handle, &domctl) < 0) {
        ERROR("Could not get information on new domain");
        goto out;
    }
    shared_info_frame = domctl.u.getdomaininfo.shared_info_frame;

    if (ver == XC_IA64_SR_FORMAT_VER_THREE ||
        ver == XC_IA64_SR_FORMAT_VER_TWO) {
        unsigned int memmap_info_num_pages;
        unsigned long memmap_size;
        xen_ia64_memmap_info_t *memmap_info;

        if (read_exact(io_fd, &memmap_info_num_pages,
                        sizeof(memmap_info_num_pages))) {
            ERROR("read: memmap_info_num_pages");
            goto out;
        }
        memmap_size = memmap_info_num_pages * PAGE_SIZE;
        memmap_info = malloc(memmap_size);
        if (memmap_info == NULL) {
            ERROR("Could not allocate memory for memmap_info");
            goto out;
        }
        if (read_exact(io_fd, memmap_info, memmap_size)) {
            ERROR("read: memmap_info");
            goto out;
        }
        if (xc_ia64_p2m_map(&p2m_table, xc_handle,
                            dom, memmap_info, IA64_DOM0VP_EFP_ALLOC_PTE)) {
            ERROR("p2m mapping");
            goto out;
        }
        free(memmap_info);
    } else if (ver == XC_IA64_SR_FORMAT_VER_ONE) {
        xen_ia64_memmap_info_t *memmap_info;
        efi_memory_desc_t *memdesc;
        uint64_t buffer[(sizeof(*memmap_info) + sizeof(*memdesc) +
                         sizeof(uint64_t) - 1) / sizeof(uint64_t)];

        memset(buffer, 0, sizeof(buffer));
        memmap_info = (xen_ia64_memmap_info_t *)buffer;
        memdesc = (efi_memory_desc_t*)&memmap_info->memdesc[0];
        memmap_info->efi_memmap_size = sizeof(*memdesc);
        memmap_info->efi_memdesc_size = sizeof(*memdesc);
        memmap_info->efi_memdesc_version = EFI_MEMORY_DESCRIPTOR_VERSION;

        memdesc->type = EFI_MEMORY_DESCRIPTOR_VERSION;
        memdesc->phys_addr = 0;
        memdesc->virt_addr = 0;
        memdesc->num_pages = nr_pfns << (PAGE_SHIFT - EFI_PAGE_SHIFT);
        memdesc->attribute = EFI_MEMORY_WB;

        if (xc_ia64_p2m_map(&p2m_table, xc_handle,
                            dom, memmap_info, IA64_DOM0VP_EFP_ALLOC_PTE)) {
            ERROR("p2m mapping");
            goto out;
        }
    } else {
        ERROR("unknown version");
        goto out;
    }

    DPRINTF("Reloading memory pages:   0%%\n");

    while (1) {
        unsigned long gmfn;
        if (read_exact(io_fd, &gmfn, sizeof(unsigned long))) {
            ERROR("Error when reading batch size");
            goto out;
        }
        if (gmfn == INVALID_MFN)
            break;

        if (populate_page_if_necessary(xc_handle, dom, gmfn, &p2m_table) < 0) {
            ERROR("can not populate page 0x%lx", gmfn);
            goto out;
        }
        if (read_page(xc_handle, io_fd, dom, gmfn) < 0)
            goto out;
    }

    DPRINTF("Received all pages\n");

    if (xc_ia64_recv_unallocated_list(xc_handle, io_fd, dom, &p2m_table))
        goto out;

    if (!hvm)
        rc = xc_ia64_pv_recv_context(ver, 
                                     xc_handle, io_fd, dom, shared_info_frame,
                                     &p2m_table, store_evtchn, store_mfn,
                                     console_evtchn, console_mfn);
    else
        rc = xc_ia64_hvm_recv_context(xc_handle, io_fd, dom, shared_info_frame,
                                      &p2m_table, store_evtchn, store_mfn,
                                      console_evtchn, console_mfn);
    if (rc)
        goto out;

    /*
     * Safety checking of saved context:
     *  1. user_regs is fine, as Xen checks that on context switch.
     *  2. fpu_ctxt is fine, as it can't hurt Xen.
     *  3. trap_ctxt needs the code selectors checked.
     *  4. ldt base must be page-aligned, no more than 8192 ents, ...
     *  5. gdt already done, and further checking is done by Xen.
     *  6. check that kernel_ss is safe.
     *  7. pt_base is already done.
     *  8. debugregs are checked by Xen.
     *  9. callback code selectors need checking.
     */
    DPRINTF("Domain ready to be built.\n");

    rc = 0;

 out:
    xc_ia64_p2m_unmap(&p2m_table);

    if ((rc != 0) && (dom != 0))
        xc_domain_destroy(xc_handle, dom);

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

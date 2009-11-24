/*
 * Xen domain builder -- ia64 bits.
 *
 * Most architecture-specific code for ia64 goes here.
 *   - fill architecture-specific structs.
 *
 * This code is licenced under the GPL.
 * written 2006 by Gerd Hoffmann <kraxel@suse.de>.
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <assert.h>
#include <asm/kregs.h>

#include <xen/xen.h>
#include <xen/foreign/ia64.h>
#include <xen/io/protocols.h>

#include "xg_private.h"
#include "xc_dom.h"
#include "xenctrl.h"

#include <asm/dom_fw_common.h>
#include "ia64/xc_dom_ia64_util.h"

/* ------------------------------------------------------------------------ */

static int alloc_magic_pages(struct xc_dom_image *dom)
{
    /* allocate special pages */
    dom->console_pfn = dom->total_pages -1;
    dom->xenstore_pfn = dom->total_pages -2;
    dom->start_info_pfn = dom->total_pages -3;
    return 0;
}

int start_info_ia64(struct xc_dom_image *dom)
{
    start_info_ia64_t *start_info =
        xc_dom_pfn_to_ptr(dom, dom->start_info_pfn, 1);
    struct xen_ia64_boot_param_ia64 *bp =
        (struct xen_ia64_boot_param_ia64 *)(start_info + 1);

    xc_dom_printf("%s\n", __FUNCTION__);

    memset(start_info, 0, sizeof(*start_info));
    sprintf(start_info->magic, dom->guest_type);
    start_info->flags = dom->flags;
    start_info->nr_pages = dom->total_pages;
    start_info->store_mfn = dom->xenstore_pfn;
    start_info->store_evtchn = dom->xenstore_evtchn;
    start_info->console.domU.mfn = dom->console_pfn;
    start_info->console.domU.evtchn = dom->console_evtchn;

    /*
     * domain_start and domain_size are abused for arch_setup hypercall
     * so that we need to clear them here.
     */
    XEN_IA64_MEMMAP_INFO_NUM_PAGES(bp) = 0;
    XEN_IA64_MEMMAP_INFO_PFN(bp) = 0;

    if ( dom->ramdisk_blob )
    {
        start_info->mod_start = dom->ramdisk_seg.vstart;
        start_info->mod_len = dom->ramdisk_seg.vend - dom->ramdisk_seg.vstart;
        bp->initrd_start = start_info->mod_start;
        bp->initrd_size = start_info->mod_len;
    }
    bp->command_line = (dom->start_info_pfn << PAGE_SHIFT_IA64)
        + offsetof(start_info_t, cmd_line);
    if ( dom->cmdline )
    {
        strncpy((char *)start_info->cmd_line, dom->cmdline, MAX_GUEST_CMDLINE);
        start_info->cmd_line[MAX_GUEST_CMDLINE - 1] = '\0';
    }
    return 0;
}

int shared_info_ia64(struct xc_dom_image *dom, void *ptr)
{
    shared_info_ia64_t *shared_info = ptr;
    int i;

    xc_dom_printf("%s: called\n", __FUNCTION__);

    memset(shared_info, 0, sizeof(*shared_info));
    for (i = 0; i < XEN_LEGACY_MAX_VCPUS; i++)
        shared_info->vcpu_info[i].evtchn_upcall_mask = 1;
    shared_info->arch.start_info_pfn = dom->start_info_pfn;
    shared_info->arch.memmap_info_num_pages = 1; //XXX
    shared_info->arch.memmap_info_pfn = dom->start_info_pfn - 1;
    return 0;
}

extern unsigned long xc_ia64_fpsr_default(void);

static int vcpu_ia64(struct xc_dom_image *dom, void *ptr)
{
    vcpu_guest_context_ia64_t *ctxt = ptr;

    xc_dom_printf("%s: called\n", __FUNCTION__);

    /* clear everything */
    memset(ctxt, 0, sizeof(*ctxt));

    ctxt->flags = 0;
    /* PSR is set according to SAL 3.2.4: AC, IC and BN are set. */
    ctxt->regs.psr = IA64_PSR_AC | IA64_PSR_IC | IA64_PSR_BN;
    ctxt->regs.ip = dom->parms.virt_entry;
    ctxt->regs.cfm = 1UL << 63;
#ifdef __ia64__			/* FIXME */
    ctxt->regs.ar.fpsr = xc_ia64_fpsr_default();
#endif
    ctxt->regs.r[28] = (dom->start_info_pfn << PAGE_SHIFT_IA64)
        + sizeof(start_info_ia64_t);
    return 0;
}

/* ------------------------------------------------------------------------ */

static struct xc_dom_arch xc_dom_arch = {
    .guest_type = "xen-3.0-ia64",
    .native_protocol = XEN_IO_PROTO_ABI_IA64,
    .page_shift = PAGE_SHIFT_IA64,
    .alloc_magic_pages = alloc_magic_pages,
    .start_info = start_info_ia64,
    .shared_info = shared_info_ia64,
    .vcpu = vcpu_ia64,
};

static struct xc_dom_arch xc_dom_arch_ia64be = {
    .guest_type = "xen-3.0-ia64be",
    .native_protocol = XEN_IO_PROTO_ABI_IA64,
    .page_shift = PAGE_SHIFT_IA64,
    .alloc_magic_pages = alloc_magic_pages,
    .start_info = start_info_ia64,
    .shared_info = shared_info_ia64,
    .vcpu = vcpu_ia64,
};

static void __init register_arch_hooks(void)
{
    xc_dom_register_arch_hooks(&xc_dom_arch);
    xc_dom_register_arch_hooks(&xc_dom_arch_ia64be);
}

#include "xc_efi.h"

int arch_setup_meminit(struct xc_dom_image *dom)
{
    xen_pfn_t pfn;
    int rc;
    unsigned long start;
    unsigned long nbr;

    /* setup initial p2m */
    if (dom->guest_type && strcmp(dom->guest_type,
                                  "hvm-3.0-ia64-sioemu") == 0) {
        start = FW_MEM_BASE >> PAGE_SHIFT_IA64;
        nbr = FW_MEM_SIZE >> PAGE_SHIFT_IA64;
    } else {
        start = 0;
        nbr = dom->total_pages;
    }

    /* setup initial p2m */
    dom->p2m_host = xc_dom_malloc(dom, sizeof(xen_pfn_t) * nbr);
    for ( pfn = 0; pfn < nbr; pfn++ )
        dom->p2m_host[pfn] = start + pfn;

    /* allocate guest memory */
    rc = xc_domain_memory_populate_physmap(dom->guest_xc, dom->guest_domid,
                                           nbr, 0, 0,
                                           dom->p2m_host);
    return rc;
}

static int ia64_setup_memmap(struct xc_dom_image *dom)
{
    unsigned int page_size = XC_DOM_PAGE_SIZE(dom);
    unsigned long memmap_info_num_pages;
    unsigned long memmap_info_pfn;
    xen_ia64_memmap_info_t* memmap_info;
    unsigned int num_mds;
    efi_memory_desc_t *md;

    char* start_info;
    struct xen_ia64_boot_param* bp;

    /* setup memmap page */
    memmap_info_num_pages = 1;
    memmap_info_pfn = dom->start_info_pfn - 1;
    xc_dom_printf("%s: memmap: mfn 0x%" PRIpfn " pages 0x%lx\n",
                  __FUNCTION__, memmap_info_pfn, memmap_info_num_pages);
    memmap_info = xc_map_foreign_range(dom->guest_xc, dom->guest_domid,
                                       page_size * memmap_info_num_pages,
                                       PROT_READ | PROT_WRITE,
                                       memmap_info_pfn);
    if (NULL == memmap_info)
        return -1;
    /* [0, total_pages) */
    memmap_info->efi_memdesc_size = sizeof(md[0]);
    memmap_info->efi_memdesc_version = EFI_MEMORY_DESCRIPTOR_VERSION;
    num_mds = 0;
    md = (efi_memory_desc_t*)&memmap_info->memdesc;
    md[num_mds].type = EFI_CONVENTIONAL_MEMORY;
    md[num_mds].pad = 0;
    md[num_mds].phys_addr = 0;
    md[num_mds].virt_addr = 0;
    md[num_mds].num_pages = dom->total_pages << (PAGE_SHIFT - EFI_PAGE_SHIFT);
    md[num_mds].attribute = EFI_MEMORY_WB;
    num_mds++;
    memmap_info->efi_memmap_size = num_mds * sizeof(md[0]);
    munmap(memmap_info, page_size * memmap_info_num_pages);
    assert(num_mds <=
           (page_size * memmap_info_num_pages -
            offsetof(typeof(*memmap_info), memdesc))/sizeof(*md));

    /*
     * kludge: we need to pass memmap_info page's pfn and other magic pages
     * somehow.
     * we use xen_ia64_boot_param::efi_memmap::{efi_memmap, efi_memmap_size}
     * for this purpose
     */
    start_info = xc_map_foreign_range(dom->guest_xc, dom->guest_domid,
				      page_size,
				      PROT_READ | PROT_WRITE,
				      dom->start_info_pfn);
    if (NULL == start_info)
        return -1;
    bp = (struct xen_ia64_boot_param*)(start_info + sizeof(start_info_t));
    memset(bp, 0, sizeof(*bp));
    XEN_IA64_MEMMAP_INFO_NUM_PAGES(bp) = memmap_info_num_pages;
    XEN_IA64_MEMMAP_INFO_PFN(bp) = memmap_info_pfn;
    munmap(start_info, page_size);
    return 0;
}

int arch_setup_bootearly(struct xc_dom_image *dom)
{
    DECLARE_DOMCTL;
    int rc;

    xc_dom_printf("%s: setup firmware for %s\n", __FUNCTION__, dom->guest_type);

    if (dom->guest_type && strcmp(dom->guest_type,
                                  "hvm-3.0-ia64-sioemu") == 0) {
        memset(&domctl, 0, sizeof(domctl));
        domctl.u.arch_setup.flags = XEN_DOMAINSETUP_sioemu_guest;
        domctl.u.arch_setup.bp = 0;
        domctl.u.arch_setup.maxmem = 0;
        domctl.cmd = XEN_DOMCTL_arch_setup;
        domctl.domain = dom->guest_domid;
        rc = xc_domctl(dom->guest_xc, &domctl);
        xc_dom_printf("%s: hvm-3.0-ia64-sioemu: %d\n", __FUNCTION__, rc);
        return rc;
    }

    rc = ia64_setup_memmap(dom);
    if (rc)
        return rc;

    memset(&domctl, 0, sizeof(domctl));
    domctl.cmd = XEN_DOMCTL_arch_setup;
    domctl.domain = dom->guest_domid;
    domctl.u.arch_setup.flags = XEN_DOMAINSETUP_query;
    rc = do_domctl(dom->guest_xc, &domctl);
    if (rc)
        return rc;
    rc = xen_ia64_dom_fw_setup(dom, domctl.u.arch_setup.hypercall_imm,
                               (dom->start_info_pfn << PAGE_SHIFT) +
                               sizeof(start_info_t),
                               dom->total_pages << PAGE_SHIFT);
    if (rc)
        return rc;

    memset(&domctl, 0, sizeof(domctl));
    domctl.cmd = XEN_DOMCTL_arch_setup;
    domctl.domain = dom->guest_domid;
    domctl.u.arch_setup.flags = 0;

    domctl.u.arch_setup.bp = (dom->start_info_pfn << PAGE_SHIFT)
        + sizeof(start_info_t);
    domctl.u.arch_setup.maxmem = dom->total_pages << PAGE_SHIFT;
    domctl.u.arch_setup.vhpt_size_log2 = dom->vhpt_size_log2;
    rc = do_domctl(dom->guest_xc, &domctl);
    return rc;
}

int arch_setup_bootlate(struct xc_dom_image *dom)
{
    unsigned int page_size = XC_DOM_PAGE_SIZE(dom);
    shared_info_t *shared_info;

    /* setup shared_info page */
    xc_dom_printf("%s: shared_info: mfn 0x%" PRIpfn "\n",
                  __FUNCTION__, dom->shared_info_mfn);
    shared_info = xc_map_foreign_range(dom->guest_xc, dom->guest_domid,
                                       page_size,
                                       PROT_READ | PROT_WRITE,
                                       dom->shared_info_mfn);
    if ( shared_info == NULL )
        return -1;
    dom->arch_hooks->shared_info(dom, shared_info);
    munmap(shared_info, page_size);
    return 0;
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

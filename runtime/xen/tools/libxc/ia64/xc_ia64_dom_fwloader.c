#include <stdlib.h>
#include <inttypes.h>
#include <asm/kregs.h>

#include <xen/xen.h>
#include <xen/foreign/ia64.h>
#include <xen/io/protocols.h>

#include "xg_private.h"
#include "xc_dom.h"

#include "ia64/xc_dom_ia64_util.h"

static const char fw_magic[16] = {'X', 'e', 'n', '-',
                                  'i', 'a', '6', '4',
                                  '-', 'f', 'w', 0,
                                  0, 0, 0, 0};
#define FW_LOAD 0xff800000UL
#define FW_SIZE (8 * 1024 * 1024)

static int xc_dom_probe_fw_kernel(struct xc_dom_image *dom)
{
    if (dom->kernel_size != FW_SIZE)
        return -EINVAL;
    if (memcmp (dom->kernel_blob, fw_magic, sizeof (fw_magic)))
        return -EINVAL;
    return 0;
}

static int xc_dom_parse_fw_kernel(struct xc_dom_image *dom)
{
    dom->kernel_seg.vstart = FW_LOAD;
    dom->kernel_seg.vend = FW_LOAD + FW_SIZE;
    dom->parms.virt_base = FW_MEM_BASE;
    dom->parms.virt_entry = FW_LOAD + sizeof (fw_magic);
    dom->ramdisk_blob = NULL; /* No ramdisk yet.  */
    dom->guest_type = "hvm-3.0-ia64-sioemu";
    return 0;
}

static int xc_dom_load_fw_kernel(struct xc_dom_image *dom)
{
    char *dest;
    unsigned long i;

    dest = xc_dom_vaddr_to_ptr(dom, dom->kernel_seg.vstart);
    memcpy(dest, dom->kernel_blob, FW_SIZE);

    /* Synchronize cache.  */
    for (i = 0; i < FW_SIZE; i += 32)
        asm volatile ("fc.i %0" :: "r"(dest + i) : "memory");

    return 0;
}

/* ------------------------------------------------------------------------ */

static int alloc_magic_pages(struct xc_dom_image *dom)
{
    /* allocate special pages */
    /* Note: do not use 0 for console or xenstore otherwise clear_page won't
       clear the page.  */
    dom->start_info_pfn = 0;
    dom->console_pfn = 1;
    dom->xenstore_pfn = 2;
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
    ctxt->regs.ip = dom->parms.virt_entry;
#ifdef __ia64__			/* FIXME */
    ctxt->regs.ar.fpsr = xc_ia64_fpsr_default();
#endif
    ctxt->regs.cr.isr = 1UL << 63;
    ctxt->regs.psr = IA64_PSR_AC | IA64_PSR_BN;
    ctxt->regs.cr.dcr = 0;
    ctxt->regs.cr.pta = 15 << 2;

    return 0;
}

static struct xc_dom_arch xc_dom_arch_ia64_fw = {
    .guest_type = "hvm-3.0-ia64-sioemu",
    .native_protocol = XEN_IO_PROTO_ABI_IA64,
    .page_shift = PAGE_SHIFT_IA64,
    .alloc_magic_pages = alloc_magic_pages,
    .start_info = start_info_ia64,
    .shared_info = shared_info_ia64,
    .vcpu = vcpu_ia64,
};

/* ------------------------------------------------------------------------ */

static struct xc_dom_loader fw_loader = {
    .name = "xen-ia64-fw",
    .probe = xc_dom_probe_fw_kernel,
    .parser = xc_dom_parse_fw_kernel,
    .loader = xc_dom_load_fw_kernel,
};

static void __init register_fwloader(void)
{
    xc_dom_register_arch_hooks(&xc_dom_arch_ia64_fw);
    xc_dom_register_loader(&fw_loader);
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

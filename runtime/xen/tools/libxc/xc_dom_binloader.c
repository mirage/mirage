/******************************************************************************
 *
 * Loads simple binary images. It's like a .COM file in MS-DOS. No headers are
 * present. The only requirement is that it must have a xen_bin_image table
 * somewhere in the first 8192 bytes, starting on a 32-bit aligned address.
 * Those familiar with the multiboot specification should recognize this, it's
 * (almost) the same as the multiboot header.
 * The layout of the xen_bin_image table is:
 *
 * Offset Type Name          Note
 * 0      uint32_t  magic         required
 * 4      uint32_t  flags         required
 * 8      uint32_t  checksum      required
 * 12     uint32_t  header_addr   required
 * 16     uint32_t  load_addr     required
 * 20     uint32_t  load_end_addr required
 * 24     uint32_t  bss_end_addr  required
 * 28     uint32_t  entry_addr    required
 *
 * - magic
 *   Magic number identifying the table. For images to be loaded by Xen 3, the
 *   magic value is 0x336ec578 ("xEn3" with the 0x80 bit of the "E" set).
 * - flags
 *   bit 0: indicates whether the image needs to be loaded on a page boundary
 *   bit 1: reserved, must be 0 (the multiboot spec uses this bit to indicate
 *          that memory info should be passed to the image)
 *   bit 2: reserved, must be 0 (the multiboot spec uses this bit to indicate
 *          that the bootloader should pass video mode info to the image)
 *   bit 16: reserved, must be 1 (the multiboot spec uses this bit to indicate
 *           that the values in the fields header_addr - entry_addr are
 *           valid)
 *   All other bits should be set to 0.
 * - checksum
 *   When added to "magic" and "flags", the resulting value should be 0.
 * - header_addr
 *   Contains the virtual address corresponding to the beginning of the
 *   table - the memory location at which the magic value is supposed to be
 *   loaded. This field serves to synchronize the mapping between OS image
 *   offsets and virtual memory addresses.
 * - load_addr
 *   Contains the virtual address of the beginning of the text segment. The
 *   offset in the OS image file at which to start loading is defined by the
 *   offset at which the table was found, minus (header addr - load addr).
 *   load addr must be less than or equal to header addr.
 * - load_end_addr
 *   Contains the virtual address of the end of the data segment.
 *   (load_end_addr - load_addr) specifies how much data to load. This implies
 *   that the text and data segments must be consecutive in the OS image. If
 *   this field is zero, the domain builder assumes that the text and data
 *   segments occupy the whole OS image file.
 * - bss_end_addr
 *   Contains the virtual address of the end of the bss segment. The domain
 *   builder initializes this area to zero, and reserves the memory it occupies
 *   to avoid placing boot modules and other data relevant to the loaded image
 *   in that area. If this field is zero, the domain builder assumes that no bss
 *   segment is present.
 * - entry_addr
 *   The virtual address at which to start execution of the loaded image.
 *
 * Some of the field descriptions were copied from "The Multiboot
 * Specification", Copyright 1995, 96 Bryan Ford <baford@cs.utah.edu>,
 * Erich Stefan Boleyn <erich@uruk.org> Copyright 1999, 2000, 2001, 2002
 * Free Software Foundation, Inc.
 */

#include <stdlib.h>
#include <inttypes.h>

#include "xg_private.h"
#include "xc_dom.h"

#define round_pgup(_p)    (((_p)+(PAGE_SIZE_X86-1))&PAGE_MASK_X86)
#define round_pgdown(_p)  ((_p)&PAGE_MASK_X86)

struct xen_bin_image_table
{
    uint32_t magic;
    uint32_t flags;
    uint32_t checksum;
    uint32_t header_addr;
    uint32_t load_addr;
    uint32_t load_end_addr;
    uint32_t bss_end_addr;
    uint32_t entry_addr;
};

#define XEN_MULTIBOOT_MAGIC3 0x336ec578

#define XEN_MULTIBOOT_FLAG_ALIGN4K     0x00000001
#define XEN_MULTIBOOT_FLAG_NEEDMEMINFO 0x00000002
#define XEN_MULTIBOOT_FLAG_NEEDVIDINFO 0x00000004
#define XEN_MULTIBOOT_FLAG_ADDRSVALID  0x00010000
#define XEN_MULTIBOOT_FLAG_PAE_SHIFT   14
#define XEN_MULTIBOOT_FLAG_PAE_MASK    (3 << XEN_MULTIBOOT_FLAG_PAE_SHIFT)

/* Flags we test for */
#define FLAGS_MASK     ((~ 0) & (~ XEN_MULTIBOOT_FLAG_ALIGN4K) & \
    (~ XEN_MULTIBOOT_FLAG_PAE_MASK))
#define FLAGS_REQUIRED XEN_MULTIBOOT_FLAG_ADDRSVALID

/* --------------------------------------------------------------------- */

static struct xen_bin_image_table *find_table(struct xc_dom_image *dom)
{
    struct xen_bin_image_table *table;
    uint32_t *probe_ptr;
    uint32_t *probe_end;

    probe_ptr = dom->kernel_blob;
    probe_end = dom->kernel_blob + dom->kernel_size - sizeof(*table);
    if ( (void*)probe_end > (dom->kernel_blob + 8192) )
        probe_end = dom->kernel_blob + 8192;

    for ( table = NULL; probe_ptr < probe_end; probe_ptr++ )
    {
        if ( *probe_ptr == XEN_MULTIBOOT_MAGIC3 )
        {
            table = (struct xen_bin_image_table *) probe_ptr;
            /* Checksum correct? */
            if ( (table->magic + table->flags + table->checksum) == 0 )
                return table;
        }
    }
    return NULL;
}

static int xc_dom_probe_bin_kernel(struct xc_dom_image *dom)
{
    return find_table(dom) ? 0 : -EINVAL;
}

static int xc_dom_parse_bin_kernel(struct xc_dom_image *dom)
{
    struct xen_bin_image_table *image_info;
    char *image = dom->kernel_blob;
    size_t image_size = dom->kernel_size;
    uint32_t start_addr;
    uint32_t load_end_addr;
    uint32_t bss_end_addr;
    uint32_t pae_flags;

    image_info = find_table(dom);
    if ( !image_info )
        return -EINVAL;

    xc_dom_printf("%s: multiboot header fields\n", __FUNCTION__);
    xc_dom_printf("  flags:         0x%" PRIx32 "\n", image_info->flags);
    xc_dom_printf("  header_addr:   0x%" PRIx32 "\n", image_info->header_addr);
    xc_dom_printf("  load_addr:     0x%" PRIx32 "\n", image_info->load_addr);
    xc_dom_printf("  load_end_addr: 0x%" PRIx32 "\n", image_info->load_end_addr);
    xc_dom_printf("  bss_end_addr:  0x%" PRIx32 "\n", image_info->bss_end_addr);
    xc_dom_printf("  entry_addr:    0x%" PRIx32 "\n", image_info->entry_addr);

    /* Check the flags */
    if ( (image_info->flags & FLAGS_MASK) != FLAGS_REQUIRED )
    {
        xc_dom_panic(XC_INVALID_KERNEL,
                     "%s: xen_bin_image_table flags required "
                     "0x%08" PRIx32 " found 0x%08" PRIx32 "\n",
                     __FUNCTION__, FLAGS_REQUIRED, image_info->flags & FLAGS_MASK);
        return -EINVAL;
    }

    /* Sanity check on the addresses */
    if ( (image_info->header_addr < image_info->load_addr) ||
         ((char *) image_info - image) <
         (image_info->header_addr - image_info->load_addr) )
    {
        xc_dom_panic(XC_INVALID_KERNEL, "%s: Invalid header_addr.",
                     __FUNCTION__);
        return -EINVAL;
    }

    start_addr = image_info->header_addr - ((char *)image_info - image);
    load_end_addr = image_info->load_end_addr ?: start_addr + image_size;
    bss_end_addr = image_info->bss_end_addr ?: load_end_addr;

    xc_dom_printf("%s: calculated addresses\n", __FUNCTION__);
    xc_dom_printf("  start_addr:    0x%" PRIx32 "\n", start_addr);
    xc_dom_printf("  load_end_addr: 0x%" PRIx32 "\n", load_end_addr);
    xc_dom_printf("  bss_end_addr:  0x%" PRIx32 "\n", bss_end_addr);

    if ( (start_addr + image_size) < load_end_addr )
    {
        xc_dom_panic(XC_INVALID_KERNEL, "%s: Invalid load_end_addr.\n",
                     __FUNCTION__);
        return -EINVAL;
    }

    if ( bss_end_addr < load_end_addr)
    {
        xc_dom_panic(XC_INVALID_KERNEL, "%s: Invalid bss_end_addr.\n",
                     __FUNCTION__);
        return -EINVAL;
    }

    dom->kernel_seg.vstart = image_info->load_addr;
    dom->kernel_seg.vend   = bss_end_addr;
    dom->parms.virt_base   = start_addr;
    dom->parms.virt_entry  = image_info->entry_addr;

    pae_flags = image_info->flags & XEN_MULTIBOOT_FLAG_PAE_MASK;
    switch (pae_flags >> XEN_MULTIBOOT_FLAG_PAE_SHIFT) {
    case 0:
        dom->guest_type = "xen-3.0-x86_32";
        break;
    case 1:
        dom->guest_type = "xen-3.0-x86_32p";
        break;
    case 2:
        dom->guest_type = "xen-3.0-x86_64";
        break;
    case 3:
        /* Kernel detects PAE at runtime.  So try to figure whenever
         * xen supports PAE and advertise a PAE-capable kernel in case
         * it does. */
        dom->guest_type = "xen-3.0-x86_32";
        if ( strstr(dom->xen_caps, "xen-3.0-x86_32p") )
        {
            xc_dom_printf("%s: PAE fixup\n", __FUNCTION__);
            dom->guest_type = "xen-3.0-x86_32p";
            dom->parms.pae  = 2;
        }
        break;
    }
    return 0;
}

static int xc_dom_load_bin_kernel(struct xc_dom_image *dom)
{
    struct xen_bin_image_table *image_info;
    char *image = dom->kernel_blob;
    char *dest;
    size_t image_size = dom->kernel_size;
    uint32_t start_addr;
    uint32_t load_end_addr;
    uint32_t bss_end_addr;
    uint32_t skip, text_size, bss_size;

    image_info = find_table(dom);
    if ( !image_info )
        return -EINVAL;

    start_addr = image_info->header_addr - ((char *)image_info - image);
    load_end_addr = image_info->load_end_addr ?: start_addr + image_size;
    bss_end_addr = image_info->bss_end_addr ?: load_end_addr;

    /* It's possible that we need to skip the first part of the image */
    skip = image_info->load_addr - start_addr;
    text_size = load_end_addr - image_info->load_addr;
    bss_size = bss_end_addr - load_end_addr;

    xc_dom_printf("%s: calculated sizes\n", __FUNCTION__);
    xc_dom_printf("  skip:      0x%" PRIx32 "\n", skip);
    xc_dom_printf("  text_size: 0x%" PRIx32 "\n", text_size);
    xc_dom_printf("  bss_size:  0x%" PRIx32 "\n", bss_size);

    dest = xc_dom_vaddr_to_ptr(dom, dom->kernel_seg.vstart);
    memcpy(dest, image + skip, text_size);
    memset(dest + text_size, 0, bss_size);

    return 0;
}

/* ------------------------------------------------------------------------ */

static struct xc_dom_loader bin_loader = {
    .name = "multiboot-binary",
    .probe = xc_dom_probe_bin_kernel,
    .parser = xc_dom_parse_bin_kernel,
    .loader = xc_dom_load_bin_kernel,
};

static void __init register_loader(void)
{
    xc_dom_register_loader(&bin_loader);
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

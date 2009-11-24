/*
 * Xen domain builder -- ELF bits.
 *
 * Parse and load ELF kernel images.
 *
 * This code is licenced under the GPL.
 * written 2006 by Gerd Hoffmann <kraxel@suse.de>.
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

#include "xg_private.h"
#include "xc_dom.h"

#define XEN_VER "xen-3.0"

/* ------------------------------------------------------------------------ */

static char *xc_dom_guest_type(struct xc_dom_image *dom,
                               struct elf_binary *elf)
{
    uint64_t machine = elf_uval(elf, elf->ehdr, e_machine);

    switch ( machine )
    {
    case EM_386:
        switch ( dom->parms.pae )
        {
        case 3 /* PAEKERN_bimodal */:
            if ( strstr(dom->xen_caps, "xen-3.0-x86_32p") )
                return "xen-3.0-x86_32p";
            return "xen-3.0-x86_32";
        case PAEKERN_extended_cr3:
        case PAEKERN_yes:
            return "xen-3.0-x86_32p";
        case PAEKERN_no:
        default:
            return "xen-3.0-x86_32";
        }
    case EM_X86_64:
        return "xen-3.0-x86_64";
    case EM_IA_64:
        return elf_msb(elf) ? "xen-3.0-ia64be" : "xen-3.0-ia64";
    default:
        return "xen-3.0-unknown";
    }
}

/* ------------------------------------------------------------------------ */
/* parse elf binary                                                         */

static int check_elf_kernel(struct xc_dom_image *dom, int verbose)
{
    if ( dom->kernel_blob == NULL )
    {
        if ( verbose )
            xc_dom_panic(XC_INTERNAL_ERROR, "%s: no kernel image loaded\n",
                         __FUNCTION__);
        return -EINVAL;
    }

    if ( !elf_is_elfbinary(dom->kernel_blob) )
    {
        if ( verbose )
            xc_dom_panic(XC_INVALID_KERNEL, "%s: kernel is not an ELF image\n",
                         __FUNCTION__);
        return -EINVAL;
    }
    return 0;
}

static int xc_dom_probe_elf_kernel(struct xc_dom_image *dom)
{
    return check_elf_kernel(dom, 0);
}

static int xc_dom_load_elf_symtab(struct xc_dom_image *dom,
                                  struct elf_binary *elf, int load)
{
    struct elf_binary syms;
    const elf_shdr *shdr, *shdr2;
    xen_vaddr_t symtab, maxaddr;
    char *hdr;
    size_t size;
    int h, count, type, i, tables = 0;

    if ( elf_swap(elf) )
    {
        xc_dom_printf("%s: non-native byte order, bsd symtab not supported\n",
                      __FUNCTION__);
        return 0;
    }

    if ( load )
    {
        if ( !dom->bsd_symtab_start )
            return 0;
        size = dom->kernel_seg.vend - dom->bsd_symtab_start;
        hdr  = xc_dom_vaddr_to_ptr(dom, dom->bsd_symtab_start);
        *(int *)hdr = size - sizeof(int);
    }
    else
    {
        size = sizeof(int) + elf_size(elf, elf->ehdr) +
            elf_shdr_count(elf) * elf_size(elf, shdr);
        hdr = xc_dom_malloc(dom, size);
        if ( hdr == NULL )
            return 0;
        dom->bsd_symtab_start = elf_round_up(&syms, dom->kernel_seg.vend);
    }

    memcpy(hdr + sizeof(int),
           elf->image,
           elf_size(elf, elf->ehdr));
    memcpy(hdr + sizeof(int) + elf_size(elf, elf->ehdr),
           elf->image + elf_uval(elf, elf->ehdr, e_shoff),
           elf_shdr_count(elf) * elf_size(elf, shdr));
    if ( elf_64bit(elf) )
    {
        Elf64_Ehdr *ehdr = (Elf64_Ehdr *)(hdr + sizeof(int));
        ehdr->e_phoff = 0;
        ehdr->e_phentsize = 0;
        ehdr->e_phnum = 0;
        ehdr->e_shoff = elf_size(elf, elf->ehdr);
        ehdr->e_shstrndx = SHN_UNDEF;
    }
    else
    {
        Elf32_Ehdr *ehdr = (Elf32_Ehdr *)(hdr + sizeof(int));
        ehdr->e_phoff = 0;
        ehdr->e_phentsize = 0;
        ehdr->e_phnum = 0;
        ehdr->e_shoff = elf_size(elf, elf->ehdr);
        ehdr->e_shstrndx = SHN_UNDEF;
    }
    if ( elf_init(&syms, hdr + sizeof(int), size - sizeof(int)) )
        return -1;
    if ( xc_dom_logfile )
        elf_set_logfile(&syms, xc_dom_logfile, 1);

    symtab = dom->bsd_symtab_start + sizeof(int);
    maxaddr = elf_round_up(&syms, symtab + elf_size(&syms, syms.ehdr) +
                           elf_shdr_count(&syms) * elf_size(&syms, shdr));

    xc_dom_printf("%s/%s: bsd_symtab_start=%" PRIx64 ", kernel.end=0x%" PRIx64
                  " -- symtab=0x%" PRIx64 ", maxaddr=0x%" PRIx64 "\n",
                  __FUNCTION__, load ? "load" : "parse",
                  dom->bsd_symtab_start, dom->kernel_seg.vend,
                  symtab, maxaddr);

    count = elf_shdr_count(&syms);
    for ( h = 0; h < count; h++ )
    {
        shdr = elf_shdr_by_index(&syms, h);
        type = elf_uval(&syms, shdr, sh_type);
        if ( type == SHT_STRTAB )
        {
            /* Look for a strtab @i linked to symtab @h. */
            for ( i = 0; i < count; i++ )
            {
                shdr2 = elf_shdr_by_index(&syms, i);
                if ( (elf_uval(&syms, shdr2, sh_type) == SHT_SYMTAB) &&
                     (elf_uval(&syms, shdr2, sh_link) == h) )
                    break;
            }
            /* Skip symtab @h if we found no corresponding strtab @i. */
            if ( i == count )
            {
                if ( elf_64bit(&syms) )
                    *(Elf64_Off*)(&shdr->e64.sh_offset) = 0;
                else
                    *(Elf32_Off*)(&shdr->e32.sh_offset) = 0;
                continue;
            }
        }

        if ( (type == SHT_STRTAB) || (type == SHT_SYMTAB) )
        {
            /* Mangled to be based on ELF header location. */
            if ( elf_64bit(&syms) )
                *(Elf64_Off*)(&shdr->e64.sh_offset) = maxaddr - symtab;
            else
                *(Elf32_Off*)(&shdr->e32.sh_offset) = maxaddr - symtab;
            size = elf_uval(&syms, shdr, sh_size);
            maxaddr = elf_round_up(&syms, maxaddr + size);
            tables++;
            xc_dom_printf("%s: h=%d %s, size=0x%zx, maxaddr=0x%" PRIx64 "\n",
                          __FUNCTION__, h,
                          type == SHT_SYMTAB ? "symtab" : "strtab",
                          size, maxaddr);

            if ( load )
            {
                shdr2 = elf_shdr_by_index(elf, h);
                memcpy((void*)elf_section_start(&syms, shdr),
                       elf_section_start(elf, shdr2),
                       size);
            }
        }

        /* Name is NULL. */
        if ( elf_64bit(&syms) )
            *(Elf64_Half*)(&shdr->e64.sh_name) = 0;
        else
            *(Elf32_Word*)(&shdr->e32.sh_name) = 0;
    }

    if ( tables == 0 )
    {
        xc_dom_printf("%s: no symbol table present\n", __FUNCTION__);
        dom->bsd_symtab_start = 0;
        return 0;
    }
    if ( !load )
        dom->kernel_seg.vend = maxaddr;
    return 0;
}

static int xc_dom_parse_elf_kernel(struct xc_dom_image *dom)
{
    struct elf_binary *elf;
    int rc;

    rc = check_elf_kernel(dom, 1);
    if ( rc != 0 )
        return rc;

    elf = xc_dom_malloc(dom, sizeof(*elf));
    dom->private_loader = elf;
    rc = elf_init(elf, dom->kernel_blob, dom->kernel_size);
    if ( xc_dom_logfile )
        elf_set_logfile(elf, xc_dom_logfile, 1);
    if ( rc != 0 )
    {
        xc_dom_panic(XC_INVALID_KERNEL, "%s: corrupted ELF image\n",
                     __FUNCTION__);
        return rc;
    }

    /* Find the section-header strings table. */
    if ( elf->sec_strtab == NULL )
    {
        xc_dom_panic(XC_INVALID_KERNEL, "%s: ELF image has no shstrtab\n",
                     __FUNCTION__);
        return -EINVAL;
    }

    /* parse binary and get xen meta info */
    elf_parse_binary(elf);
    if ( (rc = elf_xen_parse(elf, &dom->parms)) != 0 )
        return rc;

    /* find kernel segment */
    dom->kernel_seg.vstart = dom->parms.virt_kstart;
    dom->kernel_seg.vend   = dom->parms.virt_kend;

    if ( dom->parms.bsd_symtab )
        xc_dom_load_elf_symtab(dom, elf, 0);

    dom->guest_type = xc_dom_guest_type(dom, elf);
    xc_dom_printf("%s: %s: 0x%" PRIx64 " -> 0x%" PRIx64 "\n",
                  __FUNCTION__, dom->guest_type,
                  dom->kernel_seg.vstart, dom->kernel_seg.vend);
    return 0;
}

static int xc_dom_load_elf_kernel(struct xc_dom_image *dom)
{
    struct elf_binary *elf = dom->private_loader;

    elf->dest = xc_dom_seg_to_ptr(dom, &dom->kernel_seg);
    elf_load_binary(elf);
    if ( dom->parms.bsd_symtab )
        xc_dom_load_elf_symtab(dom, elf, 1);
    return 0;
}

/* ------------------------------------------------------------------------ */

struct xc_dom_loader elf_loader = {
    .name = "ELF-generic",
    .probe = xc_dom_probe_elf_kernel,
    .parser = xc_dom_parse_elf_kernel,
    .loader = xc_dom_load_elf_kernel,
};

static void __init register_loader(void)
{
    xc_dom_register_loader(&elf_loader);
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

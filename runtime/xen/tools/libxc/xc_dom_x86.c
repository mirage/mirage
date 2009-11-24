/*
 * Xen domain builder -- i386 and x86_64 bits.
 *
 * Most architecture-specific code for x86 goes here.
 *   - prepare page tables.
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

#include <xen/xen.h>
#include <xen/foreign/x86_32.h>
#include <xen/foreign/x86_64.h>
#include <xen/hvm/hvm_info_table.h>
#include <xen/io/protocols.h>

#include "xg_private.h"
#include "xc_dom.h"
#include "xenctrl.h"

/* ------------------------------------------------------------------------ */

#define SUPERPAGE_PFN_SHIFT  9
#define SUPERPAGE_NR_PFNS    (1UL << SUPERPAGE_PFN_SHIFT)

#define bits_to_mask(bits)       (((xen_vaddr_t)1 << (bits))-1)
#define round_down(addr, mask)   ((addr) & ~(mask))
#define round_up(addr, mask)     ((addr) | (mask))

static unsigned long
nr_page_tables(xen_vaddr_t start, xen_vaddr_t end, unsigned long bits)
{
    xen_vaddr_t mask = bits_to_mask(bits);
    int tables;

    if ( bits == 0 )
        return 0;  /* unused */

    if ( bits == (8 * sizeof(unsigned long)) )
    {
        /* must be pgd, need one */
        start = 0;
        end = -1;
        tables = 1;
    }
    else
    {
        start = round_down(start, mask);
        end = round_up(end, mask);
        tables = ((end - start) >> bits) + 1;
    }

    xc_dom_printf("%s: 0x%016" PRIx64 "/%ld: 0x%016" PRIx64
                  " -> 0x%016" PRIx64 ", %d table(s)\n",
                  __FUNCTION__, mask, bits, start, end, tables);
    return tables;
}

static int count_pgtables(struct xc_dom_image *dom, int pae,
                          int l4_bits, int l3_bits, int l2_bits, int l1_bits)
{
    int pages, extra_pages;
    xen_vaddr_t try_virt_end;

    extra_pages = dom->alloc_bootstack ? 1 : 0;
    extra_pages += dom->extra_pages;
    extra_pages += 128; /* 512kB padding */
    pages = extra_pages;
    for ( ; ; )
    {
        try_virt_end = round_up(dom->virt_alloc_end + pages * PAGE_SIZE_X86,
                                bits_to_mask(22)); /* 4MB alignment */
        dom->pg_l4 =
            nr_page_tables(dom->parms.virt_base, try_virt_end, l4_bits);
        dom->pg_l3 =
            nr_page_tables(dom->parms.virt_base, try_virt_end, l3_bits);
        dom->pg_l2 =
            nr_page_tables(dom->parms.virt_base, try_virt_end, l2_bits);
        dom->pg_l1 =
            nr_page_tables(dom->parms.virt_base, try_virt_end, l1_bits);
        if (pae && try_virt_end < 0xc0000000)
        {
            xc_dom_printf("%s: PAE: extra l2 page table for l3#3\n",
                          __FUNCTION__);
            dom->pg_l2++;
        }
        dom->pgtables = dom->pg_l4 + dom->pg_l3 + dom->pg_l2 + dom->pg_l1;
        pages = dom->pgtables + extra_pages;
        if ( dom->virt_alloc_end + pages * PAGE_SIZE_X86 <= try_virt_end + 1 )
            break;
    }
    dom->virt_pgtab_end = try_virt_end + 1;
    return 0;
}

/* ------------------------------------------------------------------------ */
/* i386 pagetables                                                          */

#define L1_PROT (_PAGE_PRESENT|_PAGE_RW|_PAGE_ACCESSED)
#define L2_PROT (_PAGE_PRESENT|_PAGE_RW|_PAGE_ACCESSED|_PAGE_DIRTY|_PAGE_USER)
#define L3_PROT (_PAGE_PRESENT)

static int count_pgtables_x86_32(struct xc_dom_image *dom)
{
    return count_pgtables(dom, 0, 0, 0, 32, L2_PAGETABLE_SHIFT_I386);
}

static int count_pgtables_x86_32_pae(struct xc_dom_image *dom)
{
    return count_pgtables(dom, 1, 0, 32,
                          L3_PAGETABLE_SHIFT_PAE, L2_PAGETABLE_SHIFT_PAE);
}

#define pfn_to_paddr(pfn) ((xen_paddr_t)(pfn) << PAGE_SHIFT_X86)

static int setup_pgtables_x86_32(struct xc_dom_image *dom)
{
    xen_pfn_t l2pfn = dom->pgtables_seg.pfn;
    xen_pfn_t l1pfn = dom->pgtables_seg.pfn + dom->pg_l2;
    l2_pgentry_32_t *l2tab = xc_dom_pfn_to_ptr(dom, l2pfn, 1);
    l1_pgentry_32_t *l1tab = NULL;
    unsigned long l2off, l1off;
    xen_vaddr_t addr;
    xen_pfn_t pgpfn;

    for ( addr = dom->parms.virt_base; addr < dom->virt_pgtab_end;
          addr += PAGE_SIZE_X86 )
    {
        if ( l1tab == NULL )
        {
            /* get L1 tab, make L2 entry */
            l1tab = xc_dom_pfn_to_ptr(dom, l1pfn, 1);
            l2off = l2_table_offset_i386(addr);
            l2tab[l2off] =
                pfn_to_paddr(xc_dom_p2m_guest(dom, l1pfn)) | L2_PROT;
            l1pfn++;
        }

        /* make L1 entry */
        l1off = l1_table_offset_i386(addr);
        pgpfn = (addr - dom->parms.virt_base) >> PAGE_SHIFT_X86;
        l1tab[l1off] =
            pfn_to_paddr(xc_dom_p2m_guest(dom, pgpfn)) | L1_PROT;
        if ( (addr >= dom->pgtables_seg.vstart) && 
             (addr < dom->pgtables_seg.vend) )
            l1tab[l1off] &= ~_PAGE_RW; /* page tables are r/o */
        if ( l1off == (L1_PAGETABLE_ENTRIES_I386 - 1) )
            l1tab = NULL;
    }
    return 0;
}

/*
 * Move the l3 page table page below 4G for guests which do not
 * support the extended-cr3 format.  The l3 is currently empty so we
 * do not need to preserve the current contents.
 */
static xen_pfn_t move_l3_below_4G(struct xc_dom_image *dom,
                                  xen_pfn_t l3pfn,
                                  xen_pfn_t l3mfn)
{
    xen_pfn_t new_l3mfn;
    struct xc_mmu *mmu;
    void *l3tab;
    int xc = dom->guest_xc;

    mmu = xc_alloc_mmu_updates(xc, dom->guest_domid);
    if ( mmu == NULL )
    {
        xc_dom_printf("%s: failed at %d\n", __FUNCTION__, __LINE__);
        return l3mfn;
    }

    xc_dom_unmap_one(dom, l3pfn);

    new_l3mfn = xc_make_page_below_4G(dom->guest_xc, dom->guest_domid, l3mfn);
    if ( !new_l3mfn )
        goto out;

    dom->p2m_host[l3pfn] = new_l3mfn;
    if ( xc_dom_update_guest_p2m(dom) != 0 )
        goto out;

    if ( xc_add_mmu_update(xc, mmu,
                           (((unsigned long long)new_l3mfn)
                            << XC_DOM_PAGE_SHIFT(dom)) |
                           MMU_MACHPHYS_UPDATE, l3pfn) )
        goto out;

    if ( xc_flush_mmu_updates(xc, mmu) )
        goto out;

    /*
     * This ensures that the entire pgtables_seg is mapped by a single
     * mmap region. arch_setup_bootlate() relies on this to be able to
     * unmap and pin the pagetables.
     */
    if ( xc_dom_seg_to_ptr(dom, &dom->pgtables_seg) == NULL )
        goto out;

    l3tab = xc_dom_pfn_to_ptr(dom, l3pfn, 1);
    memset(l3tab, 0, XC_DOM_PAGE_SIZE(dom));

    xc_dom_printf("%s: successfully relocated L3 below 4G. "
                  "(L3 PFN %#"PRIpfn" MFN %#"PRIpfn"=>%#"PRIpfn")\n",
                  __FUNCTION__, l3pfn, l3mfn, new_l3mfn);

    l3mfn = new_l3mfn;

 out:
    free(mmu);

    return l3mfn;
}

static int setup_pgtables_x86_32_pae(struct xc_dom_image *dom)
{
    xen_pfn_t l3pfn = dom->pgtables_seg.pfn;
    xen_pfn_t l2pfn = dom->pgtables_seg.pfn + dom->pg_l3;
    xen_pfn_t l1pfn = dom->pgtables_seg.pfn + dom->pg_l3 + dom->pg_l2;
    l3_pgentry_64_t *l3tab;
    l2_pgentry_64_t *l2tab = NULL;
    l1_pgentry_64_t *l1tab = NULL;
    unsigned long l3off, l2off, l1off;
    xen_vaddr_t addr;
    xen_pfn_t pgpfn;
    xen_pfn_t l3mfn = xc_dom_p2m_guest(dom, l3pfn);

    if ( dom->parms.pae == 1 )
    {
        if ( l3mfn >= 0x100000 )
            l3mfn = move_l3_below_4G(dom, l3pfn, l3mfn);

        if ( l3mfn >= 0x100000 )
        {
            xc_dom_panic(XC_INTERNAL_ERROR,"%s: cannot move L3 below 4G. "
                         "extended-cr3 not supported by guest. "
                         "(L3 PFN %#"PRIpfn" MFN %#"PRIpfn")\n",
                         __FUNCTION__, l3pfn, l3mfn);
            return -EINVAL;
        }
    }

    l3tab = xc_dom_pfn_to_ptr(dom, l3pfn, 1);

    for ( addr = dom->parms.virt_base; addr < dom->virt_pgtab_end;
          addr += PAGE_SIZE_X86 )
    {
        if ( l2tab == NULL )
        {
            /* get L2 tab, make L3 entry */
            l2tab = xc_dom_pfn_to_ptr(dom, l2pfn, 1);
            l3off = l3_table_offset_pae(addr);
            l3tab[l3off] =
                pfn_to_paddr(xc_dom_p2m_guest(dom, l2pfn)) | L3_PROT;
            l2pfn++;
        }

        if ( l1tab == NULL )
        {
            /* get L1 tab, make L2 entry */
            l1tab = xc_dom_pfn_to_ptr(dom, l1pfn, 1);
            l2off = l2_table_offset_pae(addr);
            l2tab[l2off] =
                pfn_to_paddr(xc_dom_p2m_guest(dom, l1pfn)) | L2_PROT;
            if ( l2off == (L2_PAGETABLE_ENTRIES_PAE - 1) )
                l2tab = NULL;
            l1pfn++;
        }

        /* make L1 entry */
        l1off = l1_table_offset_pae(addr);
        pgpfn = (addr - dom->parms.virt_base) >> PAGE_SHIFT_X86;
        l1tab[l1off] =
            pfn_to_paddr(xc_dom_p2m_guest(dom, pgpfn)) | L1_PROT;
        if ( (addr >= dom->pgtables_seg.vstart) &&
             (addr < dom->pgtables_seg.vend) )
            l1tab[l1off] &= ~_PAGE_RW; /* page tables are r/o */
        if ( l1off == (L1_PAGETABLE_ENTRIES_PAE - 1) )
            l1tab = NULL;
    }

    if ( dom->virt_pgtab_end <= 0xc0000000 )
    {
        xc_dom_printf("%s: PAE: extra l2 page table for l3#3\n", __FUNCTION__);
        l3tab[3] = pfn_to_paddr(xc_dom_p2m_guest(dom, l2pfn)) | L3_PROT;
    }
    return 0;
}

#undef L1_PROT
#undef L2_PROT
#undef L3_PROT

/* ------------------------------------------------------------------------ */
/* x86_64 pagetables                                                        */

static int count_pgtables_x86_64(struct xc_dom_image *dom)
{
    return count_pgtables(dom, 0,
                          L4_PAGETABLE_SHIFT_X86_64 + 9,
                          L4_PAGETABLE_SHIFT_X86_64,
                          L3_PAGETABLE_SHIFT_X86_64,
                          L2_PAGETABLE_SHIFT_X86_64);
}

#define L1_PROT (_PAGE_PRESENT|_PAGE_RW|_PAGE_ACCESSED)
#define L2_PROT (_PAGE_PRESENT|_PAGE_RW|_PAGE_ACCESSED|_PAGE_DIRTY|_PAGE_USER)
#define L3_PROT (_PAGE_PRESENT|_PAGE_RW|_PAGE_ACCESSED|_PAGE_DIRTY|_PAGE_USER)
#define L4_PROT (_PAGE_PRESENT|_PAGE_RW|_PAGE_ACCESSED|_PAGE_DIRTY|_PAGE_USER)

static int setup_pgtables_x86_64(struct xc_dom_image *dom)
{
    xen_pfn_t l4pfn = dom->pgtables_seg.pfn;
    xen_pfn_t l3pfn = dom->pgtables_seg.pfn + dom->pg_l4;
    xen_pfn_t l2pfn = dom->pgtables_seg.pfn + dom->pg_l4 + dom->pg_l3;
    xen_pfn_t l1pfn =
        dom->pgtables_seg.pfn + dom->pg_l4 + dom->pg_l3 + dom->pg_l2;
    l4_pgentry_64_t *l4tab = xc_dom_pfn_to_ptr(dom, l4pfn, 1);
    l3_pgentry_64_t *l3tab = NULL;
    l2_pgentry_64_t *l2tab = NULL;
    l1_pgentry_64_t *l1tab = NULL;
    uint64_t l4off, l3off, l2off, l1off;
    uint64_t addr;
    xen_pfn_t pgpfn;

    for ( addr = dom->parms.virt_base; addr < dom->virt_pgtab_end;
          addr += PAGE_SIZE_X86 )
    {
        if ( l3tab == NULL )
        {
            /* get L3 tab, make L4 entry */
            l3tab = xc_dom_pfn_to_ptr(dom, l3pfn, 1);
            l4off = l4_table_offset_x86_64(addr);
            l4tab[l4off] =
                pfn_to_paddr(xc_dom_p2m_guest(dom, l3pfn)) | L4_PROT;
            l3pfn++;
        }

        if ( l2tab == NULL )
        {
            /* get L2 tab, make L3 entry */
            l2tab = xc_dom_pfn_to_ptr(dom, l2pfn, 1);
            l3off = l3_table_offset_x86_64(addr);
            l3tab[l3off] =
                pfn_to_paddr(xc_dom_p2m_guest(dom, l2pfn)) | L3_PROT;
            if ( l3off == (L3_PAGETABLE_ENTRIES_X86_64 - 1) )
                l3tab = NULL;
            l2pfn++;
        }

        if ( l1tab == NULL )
        {
            /* get L1 tab, make L2 entry */
            l1tab = xc_dom_pfn_to_ptr(dom, l1pfn, 1);
            l2off = l2_table_offset_x86_64(addr);
            l2tab[l2off] =
                pfn_to_paddr(xc_dom_p2m_guest(dom, l1pfn)) | L2_PROT;
            if ( l2off == (L2_PAGETABLE_ENTRIES_X86_64 - 1) )
                l2tab = NULL;
            l1pfn++;
        }

        /* make L1 entry */
        l1off = l1_table_offset_x86_64(addr);
        pgpfn = (addr - dom->parms.virt_base) >> PAGE_SHIFT_X86;
        l1tab[l1off] =
            pfn_to_paddr(xc_dom_p2m_guest(dom, pgpfn)) | L1_PROT;
        if ( (addr >= dom->pgtables_seg.vstart) && 
             (addr < dom->pgtables_seg.vend) )
            l1tab[l1off] &= ~_PAGE_RW; /* page tables are r/o */
        if ( l1off == (L1_PAGETABLE_ENTRIES_X86_64 - 1) )
            l1tab = NULL;
    }
    return 0;
}

#undef L1_PROT
#undef L2_PROT
#undef L3_PROT
#undef L4_PROT

/* ------------------------------------------------------------------------ */

static int alloc_magic_pages(struct xc_dom_image *dom)
{
    size_t p2m_size = dom->total_pages * dom->arch_hooks->sizeof_pfn;

    /* allocate phys2mach table */
    if ( xc_dom_alloc_segment(dom, &dom->p2m_seg, "phys2mach", 0, p2m_size) )
        return -1;
    dom->p2m_guest = xc_dom_seg_to_ptr(dom, &dom->p2m_seg);

    /* allocate special pages */
    dom->start_info_pfn = xc_dom_alloc_page(dom, "start info");
    dom->xenstore_pfn = xc_dom_alloc_page(dom, "xenstore");
    dom->console_pfn = xc_dom_alloc_page(dom, "console");
    if ( xc_dom_feature_translated(dom) )
        dom->shared_info_pfn = xc_dom_alloc_page(dom, "shared info");
    dom->alloc_bootstack = 1;

    return 0;
}

/* ------------------------------------------------------------------------ */

static int start_info_x86_32(struct xc_dom_image *dom)
{
    start_info_x86_32_t *start_info =
        xc_dom_pfn_to_ptr(dom, dom->start_info_pfn, 1);
    xen_pfn_t shinfo =
        xc_dom_feature_translated(dom) ? dom->shared_info_pfn : dom->
        shared_info_mfn;

    xc_dom_printf("%s: called\n", __FUNCTION__);

    memset(start_info, 0, sizeof(*start_info));
    strncpy(start_info->magic, dom->guest_type, sizeof(start_info->magic));
    start_info->magic[sizeof(start_info->magic) - 1] = '\0';
    start_info->nr_pages = dom->total_pages;
    start_info->shared_info = shinfo << PAGE_SHIFT_X86;
    start_info->pt_base = dom->pgtables_seg.vstart;
    start_info->nr_pt_frames = dom->pgtables;
    start_info->mfn_list = dom->p2m_seg.vstart;

    start_info->flags = dom->flags;
    start_info->store_mfn = xc_dom_p2m_guest(dom, dom->xenstore_pfn);
    start_info->store_evtchn = dom->xenstore_evtchn;
    start_info->console.domU.mfn = xc_dom_p2m_guest(dom, dom->console_pfn);
    start_info->console.domU.evtchn = dom->console_evtchn;

    if ( dom->ramdisk_blob )
    {
        start_info->mod_start = dom->ramdisk_seg.vstart;
        start_info->mod_len = dom->ramdisk_seg.vend - dom->ramdisk_seg.vstart;
    }

    if ( dom->cmdline )
    {
        strncpy((char *)start_info->cmd_line, dom->cmdline, MAX_GUEST_CMDLINE);
        start_info->cmd_line[MAX_GUEST_CMDLINE - 1] = '\0';
    }

    return 0;
}

static int start_info_x86_64(struct xc_dom_image *dom)
{
    start_info_x86_64_t *start_info =
        xc_dom_pfn_to_ptr(dom, dom->start_info_pfn, 1);
    xen_pfn_t shinfo =
        xc_dom_feature_translated(dom) ? dom->shared_info_pfn : dom->
        shared_info_mfn;

    xc_dom_printf("%s: called\n", __FUNCTION__);

    memset(start_info, 0, sizeof(*start_info));
    strncpy(start_info->magic, dom->guest_type, sizeof(start_info->magic));
    start_info->magic[sizeof(start_info->magic) - 1] = '\0';
    start_info->nr_pages = dom->total_pages;
    start_info->shared_info = shinfo << PAGE_SHIFT_X86;
    start_info->pt_base = dom->pgtables_seg.vstart;
    start_info->nr_pt_frames = dom->pgtables;
    start_info->mfn_list = dom->p2m_seg.vstart;

    start_info->flags = dom->flags;
    start_info->store_mfn = xc_dom_p2m_guest(dom, dom->xenstore_pfn);
    start_info->store_evtchn = dom->xenstore_evtchn;
    start_info->console.domU.mfn = xc_dom_p2m_guest(dom, dom->console_pfn);
    start_info->console.domU.evtchn = dom->console_evtchn;

    if ( dom->ramdisk_blob )
    {
        start_info->mod_start = dom->ramdisk_seg.vstart;
        start_info->mod_len = dom->ramdisk_seg.vend - dom->ramdisk_seg.vstart;
    }

    if ( dom->cmdline )
    {
        strncpy((char *)start_info->cmd_line, dom->cmdline, MAX_GUEST_CMDLINE);
        start_info->cmd_line[MAX_GUEST_CMDLINE - 1] = '\0';
    }

    return 0;
}

static int shared_info_x86_32(struct xc_dom_image *dom, void *ptr)
{
    shared_info_x86_32_t *shared_info = ptr;
    int i;

    xc_dom_printf("%s: called\n", __FUNCTION__);

    memset(shared_info, 0, sizeof(*shared_info));
    for ( i = 0; i < XEN_LEGACY_MAX_VCPUS; i++ )
        shared_info->vcpu_info[i].evtchn_upcall_mask = 1;
    return 0;
}

static int shared_info_x86_64(struct xc_dom_image *dom, void *ptr)
{
    shared_info_x86_64_t *shared_info = ptr;
    int i;

    xc_dom_printf("%s: called\n", __FUNCTION__);

    memset(shared_info, 0, sizeof(*shared_info));
    for ( i = 0; i < XEN_LEGACY_MAX_VCPUS; i++ )
        shared_info->vcpu_info[i].evtchn_upcall_mask = 1;
    return 0;
}

/* ------------------------------------------------------------------------ */

static int vcpu_x86_32(struct xc_dom_image *dom, void *ptr)
{
    vcpu_guest_context_x86_32_t *ctxt = ptr;
    xen_pfn_t cr3_pfn;

    xc_dom_printf("%s: called\n", __FUNCTION__);

    /* clear everything */
    memset(ctxt, 0, sizeof(*ctxt));

    ctxt->user_regs.ds = FLAT_KERNEL_DS_X86_32;
    ctxt->user_regs.es = FLAT_KERNEL_DS_X86_32;
    ctxt->user_regs.fs = FLAT_KERNEL_DS_X86_32;
    ctxt->user_regs.gs = FLAT_KERNEL_DS_X86_32;
    ctxt->user_regs.ss = FLAT_KERNEL_SS_X86_32;
    ctxt->user_regs.cs = FLAT_KERNEL_CS_X86_32;
    ctxt->user_regs.eip = dom->parms.virt_entry;
    ctxt->user_regs.esp =
        dom->parms.virt_base + (dom->bootstack_pfn + 1) * PAGE_SIZE_X86;
    ctxt->user_regs.esi =
        dom->parms.virt_base + (dom->start_info_pfn) * PAGE_SIZE_X86;
    ctxt->user_regs.eflags = 1 << 9; /* Interrupt Enable */

    ctxt->kernel_ss = ctxt->user_regs.ss;
    ctxt->kernel_sp = ctxt->user_regs.esp;

    ctxt->flags = VGCF_in_kernel_X86_32 | VGCF_online_X86_32;
    if ( dom->parms.pae == 2 /* extended_cr3 */ ||
         dom->parms.pae == 3 /* bimodal */ )
        ctxt->vm_assist |= (1UL << VMASST_TYPE_pae_extended_cr3);

    cr3_pfn = xc_dom_p2m_guest(dom, dom->pgtables_seg.pfn);
    ctxt->ctrlreg[3] = xen_pfn_to_cr3_x86_32(cr3_pfn);
    xc_dom_printf("%s: cr3: pfn 0x%" PRIpfn " mfn 0x%" PRIpfn "\n",
                  __FUNCTION__, dom->pgtables_seg.pfn, cr3_pfn);

    return 0;
}

static int vcpu_x86_64(struct xc_dom_image *dom, void *ptr)
{
    vcpu_guest_context_x86_64_t *ctxt = ptr;
    xen_pfn_t cr3_pfn;

    xc_dom_printf("%s: called\n", __FUNCTION__);

    /* clear everything */
    memset(ctxt, 0, sizeof(*ctxt));

    ctxt->user_regs.ds = FLAT_KERNEL_DS_X86_64;
    ctxt->user_regs.es = FLAT_KERNEL_DS_X86_64;
    ctxt->user_regs.fs = FLAT_KERNEL_DS_X86_64;
    ctxt->user_regs.gs = FLAT_KERNEL_DS_X86_64;
    ctxt->user_regs.ss = FLAT_KERNEL_SS_X86_64;
    ctxt->user_regs.cs = FLAT_KERNEL_CS_X86_64;
    ctxt->user_regs.rip = dom->parms.virt_entry;
    ctxt->user_regs.rsp =
        dom->parms.virt_base + (dom->bootstack_pfn + 1) * PAGE_SIZE_X86;
    ctxt->user_regs.rsi =
        dom->parms.virt_base + (dom->start_info_pfn) * PAGE_SIZE_X86;
    ctxt->user_regs.rflags = 1 << 9; /* Interrupt Enable */

    ctxt->kernel_ss = ctxt->user_regs.ss;
    ctxt->kernel_sp = ctxt->user_regs.esp;

    ctxt->flags = VGCF_in_kernel_X86_64 | VGCF_online_X86_64;
    cr3_pfn = xc_dom_p2m_guest(dom, dom->pgtables_seg.pfn);
    ctxt->ctrlreg[3] = xen_pfn_to_cr3_x86_64(cr3_pfn);
    xc_dom_printf("%s: cr3: pfn 0x%" PRIpfn " mfn 0x%" PRIpfn "\n",
                  __FUNCTION__, dom->pgtables_seg.pfn, cr3_pfn);

    return 0;
}

/* ------------------------------------------------------------------------ */

static struct xc_dom_arch xc_dom_32 = {
    .guest_type = "xen-3.0-x86_32",
    .native_protocol = XEN_IO_PROTO_ABI_X86_32,
    .page_shift = PAGE_SHIFT_X86,
    .sizeof_pfn = 4,
    .alloc_magic_pages = alloc_magic_pages,
    .count_pgtables = count_pgtables_x86_32,
    .setup_pgtables = setup_pgtables_x86_32,
    .start_info = start_info_x86_32,
    .shared_info = shared_info_x86_32,
    .vcpu = vcpu_x86_32,
};
static struct xc_dom_arch xc_dom_32_pae = {
    .guest_type = "xen-3.0-x86_32p",
    .native_protocol = XEN_IO_PROTO_ABI_X86_32,
    .page_shift = PAGE_SHIFT_X86,
    .sizeof_pfn = 4,
    .alloc_magic_pages = alloc_magic_pages,
    .count_pgtables = count_pgtables_x86_32_pae,
    .setup_pgtables = setup_pgtables_x86_32_pae,
    .start_info = start_info_x86_32,
    .shared_info = shared_info_x86_32,
    .vcpu = vcpu_x86_32,
};

static struct xc_dom_arch xc_dom_64 = {
    .guest_type = "xen-3.0-x86_64",
    .native_protocol = XEN_IO_PROTO_ABI_X86_64,
    .page_shift = PAGE_SHIFT_X86,
    .sizeof_pfn = 8,
    .alloc_magic_pages = alloc_magic_pages,
    .count_pgtables = count_pgtables_x86_64,
    .setup_pgtables = setup_pgtables_x86_64,
    .start_info = start_info_x86_64,
    .shared_info = shared_info_x86_64,
    .vcpu = vcpu_x86_64,
};

static void __init register_arch_hooks(void)
{
    xc_dom_register_arch_hooks(&xc_dom_32);
    xc_dom_register_arch_hooks(&xc_dom_32_pae);
    xc_dom_register_arch_hooks(&xc_dom_64);
}

static int x86_compat(int xc, domid_t domid, char *guest_type)
{
    static const struct {
        char           *guest;
        uint32_t        size;
    } types[] = {
        { "xen-3.0-x86_32p", 32 },
        { "xen-3.0-x86_64",  64 },
    };
    DECLARE_DOMCTL;
    int i,rc;

    memset(&domctl, 0, sizeof(domctl));
    domctl.domain = domid;
    domctl.cmd    = XEN_DOMCTL_set_address_size;
    for ( i = 0; i < sizeof(types)/sizeof(types[0]); i++ )
        if ( !strcmp(types[i].guest, guest_type) )
            domctl.u.address_size.size = types[i].size;
    if ( domctl.u.address_size.size == 0 )
        /* nothing to do */
        return 0;

    xc_dom_printf("%s: guest %s, address size %" PRId32 "\n", __FUNCTION__,
                  guest_type, domctl.u.address_size.size);
    rc = do_domctl(xc, &domctl);
    if ( rc != 0 )
        xc_dom_printf("%s: warning: failed (rc=%d)\n",
                      __FUNCTION__, rc);
    return rc;
}


static int x86_shadow(int xc, domid_t domid)
{
    int rc, mode;

    xc_dom_printf("%s: called\n", __FUNCTION__);

    mode = XEN_DOMCTL_SHADOW_ENABLE_REFCOUNT |
        XEN_DOMCTL_SHADOW_ENABLE_TRANSLATE;

    rc = xc_shadow_control(xc, domid,
                           XEN_DOMCTL_SHADOW_OP_ENABLE,
                           NULL, 0, NULL, mode, NULL);
    if ( rc != 0 )
    {
        xc_dom_panic(XC_INTERNAL_ERROR,
                     "%s: SHADOW_OP_ENABLE (mode=0x%x) failed (rc=%d)\n",
                     __FUNCTION__, mode, rc);
        return rc;
    }
    xc_dom_printf("%s: shadow enabled (mode=0x%x)\n", __FUNCTION__, mode);
    return rc;
}

int arch_setup_meminit(struct xc_dom_image *dom)
{
    int rc;
    xen_pfn_t pfn, allocsz, i, j, mfn;

    rc = x86_compat(dom->guest_xc, dom->guest_domid, dom->guest_type);
    if ( rc )
        return rc;
    if ( xc_dom_feature_translated(dom) )
    {
        dom->shadow_enabled = 1;
        rc = x86_shadow(dom->guest_xc, dom->guest_domid);
        if ( rc )
            return rc;
    }

    dom->p2m_host = xc_dom_malloc(dom, sizeof(xen_pfn_t) * dom->total_pages);
    if ( dom->superpages )
    {
        int count = dom->total_pages >> SUPERPAGE_PFN_SHIFT;
        xen_pfn_t extents[count];

        xc_dom_printf("Populating memory with %d superpages\n", count);
        for ( pfn = 0; pfn < count; pfn++ )
            extents[pfn] = pfn << SUPERPAGE_PFN_SHIFT;
        rc = xc_domain_memory_populate_physmap(dom->guest_xc, dom->guest_domid,
                                               count, SUPERPAGE_PFN_SHIFT, 0,
                                               extents);
        if ( rc )
            return rc;

        /* Expand the returned mfn into the p2m array */
        pfn = 0;
        for ( i = 0; i < count; i++ )
        {
            mfn = extents[i];
            for ( j = 0; j < SUPERPAGE_NR_PFNS; j++, pfn++ )
                dom->p2m_host[pfn] = mfn + j;
        }
    }
    else
    {
        /* setup initial p2m */
        for ( pfn = 0; pfn < dom->total_pages; pfn++ )
            dom->p2m_host[pfn] = pfn;
        
        /* allocate guest memory */
        for ( i = rc = allocsz = 0;
              (i < dom->total_pages) && !rc;
              i += allocsz )
        {
            allocsz = dom->total_pages - i;
            if ( allocsz > 1024*1024 )
                allocsz = 1024*1024;
            rc = xc_domain_memory_populate_physmap(
                dom->guest_xc, dom->guest_domid, allocsz,
                0, 0, &dom->p2m_host[i]);
        }
    }

    return rc;
}

int arch_setup_bootearly(struct xc_dom_image *dom)
{
    xc_dom_printf("%s: doing nothing\n", __FUNCTION__);
    return 0;
}

int arch_setup_bootlate(struct xc_dom_image *dom)
{
    static const struct {
        char *guest;
        unsigned long pgd_type;
    } types[] = {
        { "xen-3.0-x86_32",  MMUEXT_PIN_L2_TABLE},
        { "xen-3.0-x86_32p", MMUEXT_PIN_L3_TABLE},
        { "xen-3.0-x86_64",  MMUEXT_PIN_L4_TABLE},
    };
    unsigned long pgd_type = 0;
    shared_info_t *shared_info;
    xen_pfn_t shinfo;
    int i, rc;

    for ( i = 0; i < sizeof(types) / sizeof(types[0]); i++ )
        if ( !strcmp(types[i].guest, dom->guest_type) )
            pgd_type = types[i].pgd_type;

    if ( !xc_dom_feature_translated(dom) )
    {
        /* paravirtualized guest */
        xc_dom_unmap_one(dom, dom->pgtables_seg.pfn);
        rc = pin_table(dom->guest_xc, pgd_type,
                       xc_dom_p2m_host(dom, dom->pgtables_seg.pfn),
                       dom->guest_domid);
        if ( rc != 0 )
        {
            xc_dom_panic(XC_INTERNAL_ERROR,
                         "%s: pin_table failed (pfn 0x%" PRIpfn ", rc=%d)\n",
                         __FUNCTION__, dom->pgtables_seg.pfn, rc);
            return rc;
        }
        shinfo = dom->shared_info_mfn;
    }
    else
    {
        /* paravirtualized guest with auto-translation */
        struct xen_add_to_physmap xatp;
        int i;

        /* Map shared info frame into guest physmap. */
        xatp.domid = dom->guest_domid;
        xatp.space = XENMAPSPACE_shared_info;
        xatp.idx = 0;
        xatp.gpfn = dom->shared_info_pfn;
        rc = xc_memory_op(dom->guest_xc, XENMEM_add_to_physmap, &xatp);
        if ( rc != 0 )
        {
            xc_dom_panic(XC_INTERNAL_ERROR, "%s: mapping shared_info failed "
                         "(pfn=0x%" PRIpfn ", rc=%d)\n",
                         __FUNCTION__, xatp.gpfn, rc);
            return rc;
        }

        /* Map grant table frames into guest physmap. */
        for ( i = 0; ; i++ )
        {
            xatp.domid = dom->guest_domid;
            xatp.space = XENMAPSPACE_grant_table;
            xatp.idx = i;
            xatp.gpfn = dom->total_pages + i;
            rc = xc_memory_op(dom->guest_xc, XENMEM_add_to_physmap, &xatp);
            if ( rc != 0 )
            {
                if ( (i > 0) && (errno == EINVAL) )
                {
                    xc_dom_printf("%s: %d grant tables mapped\n", __FUNCTION__,
                                  i);
                    break;
                }
                xc_dom_panic(XC_INTERNAL_ERROR,
                             "%s: mapping grant tables failed " "(pfn=0x%"
                             PRIpfn ", rc=%d)\n", __FUNCTION__, xatp.gpfn, rc);
                return rc;
            }
        }
        shinfo = dom->shared_info_pfn;
    }

    /* setup shared_info page */
    xc_dom_printf("%s: shared_info: pfn 0x%" PRIpfn ", mfn 0x%" PRIpfn "\n",
                  __FUNCTION__, dom->shared_info_pfn, dom->shared_info_mfn);
    shared_info = xc_map_foreign_range(dom->guest_xc, dom->guest_domid,
                                       PAGE_SIZE_X86,
                                       PROT_READ | PROT_WRITE,
                                       shinfo);
    if ( shared_info == NULL )
        return -1;
    dom->arch_hooks->shared_info(dom, shared_info);
    munmap(shared_info, PAGE_SIZE_X86);

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

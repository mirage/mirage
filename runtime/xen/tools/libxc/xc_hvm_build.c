/******************************************************************************
 * xc_hvm_build.c
 */

#include <stddef.h>
#include <inttypes.h>
#include <stdlib.h>
#include <unistd.h>
#include <zlib.h>

#include "xg_private.h"
#include "xc_private.h"

#include <xen/foreign/x86_32.h>
#include <xen/foreign/x86_64.h>
#include <xen/hvm/hvm_info_table.h>
#include <xen/hvm/params.h>
#include <xen/hvm/e820.h>

#include <xen/libelf/libelf.h>

#define SUPERPAGE_PFN_SHIFT  9
#define SUPERPAGE_NR_PFNS    (1UL << SUPERPAGE_PFN_SHIFT)

#define SPECIALPAGE_BUFIOREQ 0
#define SPECIALPAGE_XENSTORE 1
#define SPECIALPAGE_IOREQ    2
#define SPECIALPAGE_IDENT_PT 3
#define SPECIALPAGE_SHINFO   4
#define NR_SPECIAL_PAGES     5
#define special_pfn(x) (0xff000u - NR_SPECIAL_PAGES + (x))

static void build_hvm_info(void *hvm_info_page, uint64_t mem_size)
{
    struct hvm_info_table *hvm_info = (struct hvm_info_table *)
        (((unsigned char *)hvm_info_page) + HVM_INFO_OFFSET);
    uint64_t lowmem_end = mem_size, highmem_end = 0;
    uint8_t sum;
    int i;

    if ( lowmem_end > HVM_BELOW_4G_RAM_END )
    {
        highmem_end = lowmem_end + (1ull<<32) - HVM_BELOW_4G_RAM_END;
        lowmem_end = HVM_BELOW_4G_RAM_END;
    }

    memset(hvm_info_page, 0, PAGE_SIZE);

    /* Fill in the header. */
    strncpy(hvm_info->signature, "HVM INFO", 8);
    hvm_info->length = sizeof(struct hvm_info_table);

    /* Sensible defaults: these can be overridden by the caller. */
    hvm_info->acpi_enabled = 1;
    hvm_info->apic_mode = 1;
    hvm_info->nr_vcpus = 1;

    /* Memory parameters. */
    hvm_info->low_mem_pgend = lowmem_end >> PAGE_SHIFT;
    hvm_info->high_mem_pgend = highmem_end >> PAGE_SHIFT;
    hvm_info->reserved_mem_pgstart = special_pfn(0);

    /* Finish with the checksum. */
    for ( i = 0, sum = 0; i < hvm_info->length; i++ )
        sum += ((uint8_t *)hvm_info)[i];
    hvm_info->checksum = -sum;
}

static int loadelfimage(
    struct elf_binary *elf, int xch, uint32_t dom, unsigned long *parray)
{
    privcmd_mmap_entry_t *entries = NULL;
    size_t pages = (elf->pend - elf->pstart + PAGE_SIZE - 1) >> PAGE_SHIFT;
    int i, rc = -1;

    /* Map address space for initial elf image. */
    entries = calloc(pages, sizeof(privcmd_mmap_entry_t));
    if ( entries == NULL )
        goto err;

    for ( i = 0; i < pages; i++ )
        entries[i].mfn = parray[(elf->pstart >> PAGE_SHIFT) + i];

    elf->dest = xc_map_foreign_ranges(
        xch, dom, pages << PAGE_SHIFT, PROT_READ | PROT_WRITE, 1 << PAGE_SHIFT,
        entries, pages);
    if ( elf->dest == NULL )
        goto err;

    /* Load the initial elf image. */
    elf_load_binary(elf);
    rc = 0;

    munmap(elf->dest, pages << PAGE_SHIFT);
    elf->dest = NULL;

 err:
    free(entries);

    return rc;
}

static int setup_guest(int xc_handle,
                       uint32_t dom, int memsize, int target,
                       char *image, unsigned long image_size)
{
    xen_pfn_t *page_array = NULL;
    unsigned long i, nr_pages = (unsigned long)memsize << (20 - PAGE_SHIFT);
    unsigned long target_pages = (unsigned long)target << (20 - PAGE_SHIFT);
    unsigned long pod_pages = 0;
    unsigned long entry_eip, cur_pages;
    struct xen_add_to_physmap xatp;
    struct shared_info *shared_info;
    void *hvm_info_page;
    uint32_t *ident_pt;
    struct elf_binary elf;
    uint64_t v_start, v_end;
    int rc;
    xen_capabilities_info_t caps;
    int pod_mode = 0;
    

    /* An HVM guest must be initialised with at least 2MB memory. */
    if ( memsize < 2 || target < 2 )
        goto error_out;

    if ( memsize > target )
        pod_mode = 1;

    if ( elf_init(&elf, image, image_size) != 0 )
        goto error_out;
    elf_parse_binary(&elf);
    v_start = 0;
    v_end = (unsigned long long)memsize << 20;

    if ( xc_version(xc_handle, XENVER_capabilities, &caps) != 0 )
    {
        PERROR("Could not get Xen capabilities\n");
        goto error_out;
    }

    if ( (elf.pstart & (PAGE_SIZE - 1)) != 0 )
    {
        PERROR("Guest OS must load to a page boundary.\n");
        goto error_out;
    }

    IPRINTF("VIRTUAL MEMORY ARRANGEMENT:\n"
            "  Loader:        %016"PRIx64"->%016"PRIx64"\n"
            "  TOTAL:         %016"PRIx64"->%016"PRIx64"\n"
            "  ENTRY ADDRESS: %016"PRIx64"\n",
            elf.pstart, elf.pend,
            v_start, v_end,
            elf_uval(&elf, elf.ehdr, e_entry));

    if ( (page_array = malloc(nr_pages * sizeof(xen_pfn_t))) == NULL )
    {
        PERROR("Could not allocate memory.\n");
        goto error_out;
    }

    for ( i = 0; i < nr_pages; i++ )
        page_array[i] = i;
    for ( i = HVM_BELOW_4G_RAM_END >> PAGE_SHIFT; i < nr_pages; i++ )
        page_array[i] += HVM_BELOW_4G_MMIO_LENGTH >> PAGE_SHIFT;

    /*
     * Allocate memory for HVM guest, skipping VGA hole 0xA0000-0xC0000.
     * We allocate pages in batches of no more than 8MB to ensure that
     * we can be preempted and hence dom0 remains responsive.
     */
    rc = xc_domain_memory_populate_physmap(
        xc_handle, dom, 0xa0, 0, 0, &page_array[0x00]);
    cur_pages = 0xc0;
    while ( (rc == 0) && (nr_pages > cur_pages) )
    {
        /* Clip count to maximum 8MB extent. */
        unsigned long count = nr_pages - cur_pages;
        if ( count > 2048 )
            count = 2048;

        /* Clip partial superpage extents to superpage boundaries. */
        if ( ((cur_pages & (SUPERPAGE_NR_PFNS-1)) != 0) &&
             (count > (-cur_pages & (SUPERPAGE_NR_PFNS-1))) )
            count = -cur_pages & (SUPERPAGE_NR_PFNS-1); /* clip s.p. tail */
        else if ( ((count & (SUPERPAGE_NR_PFNS-1)) != 0) &&
                  (count > SUPERPAGE_NR_PFNS) )
            count &= ~(SUPERPAGE_NR_PFNS - 1); /* clip non-s.p. tail */

        /* Attempt to allocate superpage extents. */
        if ( ((count | cur_pages) & (SUPERPAGE_NR_PFNS - 1)) == 0 )
        {
            long done;
            xen_pfn_t sp_extents[count >> SUPERPAGE_PFN_SHIFT];
            struct xen_memory_reservation sp_req = {
                .nr_extents   = count >> SUPERPAGE_PFN_SHIFT,
                .extent_order = SUPERPAGE_PFN_SHIFT,
                .domid        = dom
            };

            if ( pod_mode )
                sp_req.mem_flags = XENMEMF_populate_on_demand;

            set_xen_guest_handle(sp_req.extent_start, sp_extents);
            for ( i = 0; i < sp_req.nr_extents; i++ )
                sp_extents[i] = page_array[cur_pages+(i<<SUPERPAGE_PFN_SHIFT)];
            done = xc_memory_op(xc_handle, XENMEM_populate_physmap, &sp_req);
            if ( done > 0 )
            {
                done <<= SUPERPAGE_PFN_SHIFT;
                if ( pod_mode && target_pages > cur_pages )
                {
                    int d = target_pages - cur_pages;
                    pod_pages += ( done < d ) ? done : d;
                }
                cur_pages += done;
                count -= done;
            }
        }

        /* Fall back to 4kB extents. */
        if ( count != 0 )
        {
            rc = xc_domain_memory_populate_physmap(
                xc_handle, dom, count, 0, 0, &page_array[cur_pages]);
            cur_pages += count;
            if ( pod_mode )
                pod_pages -= count;
        }
    }

    if ( pod_mode )
        rc = xc_domain_memory_set_pod_target(xc_handle,
                                             dom,
                                             pod_pages,
                                             NULL, NULL, NULL);

    if ( rc != 0 )
    {
        PERROR("Could not allocate memory for HVM guest.\n");
        goto error_out;
    }

    if ( loadelfimage(&elf, xc_handle, dom, page_array) != 0 )
        goto error_out;

    if ( (hvm_info_page = xc_map_foreign_range(
              xc_handle, dom, PAGE_SIZE, PROT_READ | PROT_WRITE,
              HVM_INFO_PFN)) == NULL )
        goto error_out;
    build_hvm_info(hvm_info_page, v_end);
    munmap(hvm_info_page, PAGE_SIZE);

    /* Map and initialise shared_info page. */
    xatp.domid = dom;
    xatp.space = XENMAPSPACE_shared_info;
    xatp.idx   = 0;
    xatp.gpfn  = special_pfn(SPECIALPAGE_SHINFO);
    if ( (xc_memory_op(xc_handle, XENMEM_add_to_physmap, &xatp) != 0) ||
         ((shared_info = xc_map_foreign_range(
             xc_handle, dom, PAGE_SIZE, PROT_READ | PROT_WRITE,
             special_pfn(SPECIALPAGE_SHINFO))) == NULL) )
        goto error_out;
    memset(shared_info, 0, PAGE_SIZE);
    /* NB. evtchn_upcall_mask is unused: leave as zero. */
    memset(&shared_info->evtchn_mask[0], 0xff,
           sizeof(shared_info->evtchn_mask));
    munmap(shared_info, PAGE_SIZE);

    /* Allocate and clear special pages. */
    for ( i = 0; i < NR_SPECIAL_PAGES; i++ )
    {
        xen_pfn_t pfn = special_pfn(i);
        if ( i == SPECIALPAGE_SHINFO )
            continue;
        rc = xc_domain_memory_populate_physmap(xc_handle, dom, 1, 0, 0, &pfn);
        if ( rc != 0 )
        {
            PERROR("Could not allocate %d'th special page.\n", i);
            goto error_out;
        }
        if ( xc_clear_domain_page(xc_handle, dom, special_pfn(i)) )
            goto error_out;
    }

    xc_set_hvm_param(xc_handle, dom, HVM_PARAM_STORE_PFN,
                     special_pfn(SPECIALPAGE_XENSTORE));
    xc_set_hvm_param(xc_handle, dom, HVM_PARAM_BUFIOREQ_PFN,
                     special_pfn(SPECIALPAGE_BUFIOREQ));
    xc_set_hvm_param(xc_handle, dom, HVM_PARAM_IOREQ_PFN,
                     special_pfn(SPECIALPAGE_IOREQ));

    /*
     * Identity-map page table is required for running with CR0.PG=0 when
     * using Intel EPT. Create a 32-bit non-PAE page directory of superpages.
     */
    if ( (ident_pt = xc_map_foreign_range(
              xc_handle, dom, PAGE_SIZE, PROT_READ | PROT_WRITE,
              special_pfn(SPECIALPAGE_IDENT_PT))) == NULL )
        goto error_out;
    for ( i = 0; i < PAGE_SIZE / sizeof(*ident_pt); i++ )
        ident_pt[i] = ((i << 22) | _PAGE_PRESENT | _PAGE_RW | _PAGE_USER |
                       _PAGE_ACCESSED | _PAGE_DIRTY | _PAGE_PSE);
    munmap(ident_pt, PAGE_SIZE);
    xc_set_hvm_param(xc_handle, dom, HVM_PARAM_IDENT_PT,
                     special_pfn(SPECIALPAGE_IDENT_PT) << PAGE_SHIFT);

    /* Insert JMP <rel32> instruction at address 0x0 to reach entry point. */
    entry_eip = elf_uval(&elf, elf.ehdr, e_entry);
    if ( entry_eip != 0 )
    {
        char *page0 = xc_map_foreign_range(
            xc_handle, dom, PAGE_SIZE, PROT_READ | PROT_WRITE, 0);
        if ( page0 == NULL )
            goto error_out;
        page0[0] = 0xe9;
        *(uint32_t *)&page0[1] = entry_eip - 5;
        munmap(page0, PAGE_SIZE);
    }

    free(page_array);
    return 0;

 error_out:
    free(page_array);
    return -1;
}

static int xc_hvm_build_internal(int xc_handle,
                                 uint32_t domid,
                                 int memsize,
                                 int target,
                                 char *image,
                                 unsigned long image_size)
{
    if ( (image == NULL) || (image_size == 0) )
    {
        ERROR("Image required");
        return -1;
    }

    return setup_guest(xc_handle, domid, memsize, target, image, image_size);
}

/* xc_hvm_build:
 * Create a domain for a virtualized Linux, using files/filenames.
 */
int xc_hvm_build(int xc_handle,
                 uint32_t domid,
                 int memsize,
                 const char *image_name)
{
    char *image;
    int  sts;
    unsigned long image_size;

    if ( (image_name == NULL) ||
         ((image = xc_read_image(image_name, &image_size)) == NULL) )
        return -1;

    sts = xc_hvm_build_internal(xc_handle, domid, memsize, memsize, image, image_size);

    free(image);

    return sts;
}

/* xc_hvm_build_target_mem: 
 * Create a domain for a pre-ballooned virtualized Linux, using
 * files/filenames.  If target < memsize, domain is created with
 * memsize pages marked populate-on-demand, and with a PoD cache size
 * of target.  If target == memsize, pages are populated normally.
 */
int xc_hvm_build_target_mem(int xc_handle,
                           uint32_t domid,
                           int memsize,
                           int target,
                           const char *image_name)
{
    char *image;
    int  sts;
    unsigned long image_size;

    if ( (image_name == NULL) ||
         ((image = xc_read_image(image_name, &image_size)) == NULL) )
        return -1;

    sts = xc_hvm_build_internal(xc_handle, domid, memsize, target, image, image_size);

    free(image);

    return sts;
}

/* xc_hvm_build_mem:
 * Create a domain for a virtualized Linux, using memory buffers.
 */
int xc_hvm_build_mem(int xc_handle,
                     uint32_t domid,
                     int memsize,
                     const char *image_buffer,
                     unsigned long image_size)
{
    int           sts;
    unsigned long img_len;
    char         *img;

    /* Validate that there is a kernel buffer */

    if ( (image_buffer == NULL) || (image_size == 0) )
    {
        ERROR("kernel image buffer not present");
        return -1;
    }

    img = xc_inflate_buffer(image_buffer, image_size, &img_len);
    if ( img == NULL )
    {
        ERROR("unable to inflate ram disk buffer");
        return -1;
    }

    sts = xc_hvm_build_internal(xc_handle, domid, memsize, memsize,
                                img, img_len);

    /* xc_inflate_buffer may return the original buffer pointer (for
       for already inflated buffers), so exercise some care in freeing */

    if ( (img != NULL) && (img != image_buffer) )
        free(img);

    return sts;
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

/*
 * Xen domain builder -- core bits.
 *
 * The core code goes here:
 *   - allocate and release domain structs.
 *   - memory management functions.
 *   - misc helper functions.
 *
 * This code is licenced under the GPL.
 * written 2006 by Gerd Hoffmann <kraxel@suse.de>.
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <inttypes.h>
#include <zlib.h>

#include "xg_private.h"
#include "xc_dom.h"

/* ------------------------------------------------------------------------ */
/* debugging                                                                */

FILE *xc_dom_logfile = NULL;

void xc_dom_loginit(void)
{
    if ( xc_dom_logfile )
        return;
    xc_dom_logfile = fopen("/var/log/xen/domain-builder-ng.log", "a");
    setvbuf(xc_dom_logfile, NULL, _IONBF, 0);
    xc_dom_printf("### ----- xc domain builder logfile opened -----\n");
}

int xc_dom_printf(const char *fmt, ...)
{
    va_list args;
    char buf[1024];
    int rc;

    if ( !xc_dom_logfile )
        return 0;

    va_start(args, fmt);
    rc = vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    rc = fwrite(buf, rc, 1, xc_dom_logfile);

    return rc;
}

int xc_dom_panic_func(const char *file, int line, xc_error_code err,
                      const char *fmt, ...)
{
    va_list args;
    FILE *fp = stderr;
    int rc = 0;
    char pos[256];
    char msg[XC_MAX_ERROR_MSG_LEN];

    if ( xc_dom_logfile )
        fp = xc_dom_logfile;

    snprintf(pos, sizeof(pos), "%s:%d: panic: ", file, line);
    va_start(args, fmt);
    vsnprintf(msg, sizeof(msg), fmt, args);
    va_end(args);
    xc_set_error(err, "%s", msg);
    rc = fprintf(fp, "%s%s", pos, msg);
    return rc;
}

static void print_mem(const char *name, size_t mem)
{
    if ( mem > (32 * 1024 * 1024) )
        xc_dom_printf("%-24s : %zd MB\n", name, mem / (1024 * 1024));
    else if ( mem > (32 * 1024) )
        xc_dom_printf("%-24s : %zd kB\n", name, mem / 1024);
    else
        xc_dom_printf("%-24s : %zd bytes\n", name, mem);
}

void xc_dom_log_memory_footprint(struct xc_dom_image *dom)
{
    xc_dom_printf("domain builder memory footprint\n");
    xc_dom_printf("   allocated\n");
    print_mem("      malloc", dom->alloc_malloc);
    print_mem("      anon mmap", dom->alloc_mem_map);
    xc_dom_printf("   mapped\n");
    print_mem("      file mmap", dom->alloc_file_map);
    print_mem("      domU mmap", dom->alloc_domU_map);
}

/* ------------------------------------------------------------------------ */
/* simple memory pool                                                       */

void *xc_dom_malloc(struct xc_dom_image *dom, size_t size)
{
    struct xc_dom_mem *block;

    block = malloc(sizeof(*block) + size);
    if ( block == NULL )
        return NULL;
    memset(block, 0, sizeof(*block) + size);
    block->next = dom->memblocks;
    dom->memblocks = block;
    dom->alloc_malloc += sizeof(*block) + size;
    if ( size > (100 * 1024) )
        print_mem(__FUNCTION__, size);
    return block->memory;
}

void *xc_dom_malloc_page_aligned(struct xc_dom_image *dom, size_t size)
{
    struct xc_dom_mem *block;

    block = malloc(sizeof(*block));
    if ( block == NULL )
        return NULL;
    memset(block, 0, sizeof(*block));
    block->mmap_len = size;
    block->mmap_ptr = mmap(NULL, block->mmap_len,
                           PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON,
                           -1, 0);
    if ( block->mmap_ptr == MAP_FAILED )
    {
        free(block);
        return NULL;
    }
    block->next = dom->memblocks;
    dom->memblocks = block;
    dom->alloc_malloc += sizeof(*block);
    dom->alloc_mem_map += block->mmap_len;
    if ( size > (100 * 1024) )
        print_mem(__FUNCTION__, size);
    return block->mmap_ptr;
}

void *xc_dom_malloc_filemap(struct xc_dom_image *dom,
                            const char *filename, size_t * size)
{
    struct xc_dom_mem *block = NULL;
    int fd = -1;

    fd = open(filename, O_RDONLY);
    if ( fd == -1 )
        goto err;

    lseek(fd, 0, SEEK_SET);
    *size = lseek(fd, 0, SEEK_END);

    block = malloc(sizeof(*block));
    if ( block == NULL )
        goto err;
    memset(block, 0, sizeof(*block));
    block->mmap_len = *size;
    block->mmap_ptr = mmap(NULL, block->mmap_len, PROT_READ,
                           MAP_SHARED, fd, 0);
    if ( block->mmap_ptr == MAP_FAILED )
        goto err;
    block->next = dom->memblocks;
    dom->memblocks = block;
    dom->alloc_malloc += sizeof(*block);
    dom->alloc_file_map += block->mmap_len;
    close(fd);
    if ( *size > (100 * 1024) )
        print_mem(__FUNCTION__, *size);
    return block->mmap_ptr;

 err:
    if ( fd != -1 )
        close(fd);
    if ( block != NULL )
        free(block);
    return NULL;
}

static void xc_dom_free_all(struct xc_dom_image *dom)
{
    struct xc_dom_mem *block;

    while ( (block = dom->memblocks) != NULL )
    {
        dom->memblocks = block->next;
        if ( block->mmap_ptr )
            munmap(block->mmap_ptr, block->mmap_len);
        free(block);
    }
}

char *xc_dom_strdup(struct xc_dom_image *dom, const char *str)
{
    size_t len = strlen(str) + 1;
    char *nstr = xc_dom_malloc(dom, len);

    if ( nstr == NULL )
        return NULL;
    memcpy(nstr, str, len);
    return nstr;
}

/* ------------------------------------------------------------------------ */
/* read files, copy memory blocks, with transparent gunzip                  */

size_t xc_dom_check_gzip(void *blob, size_t ziplen)
{
    unsigned char *gzlen;
    size_t unziplen;

    if ( strncmp(blob, "\037\213", 2) )
        /* not gzipped */
        return 0;

    gzlen = blob + ziplen - 4;
    unziplen = gzlen[3] << 24 | gzlen[2] << 16 | gzlen[1] << 8 | gzlen[0];
    if ( (unziplen < 0) || (unziplen > (1024*1024*1024)) ) /* 1GB limit */
    {
        xc_dom_printf
            ("%s: size (zip %zd, unzip %zd) looks insane, skip gunzip\n",
             __FUNCTION__, ziplen, unziplen);
        return 0;
    }

    return unziplen + 16;
}

int xc_dom_do_gunzip(void *src, size_t srclen, void *dst, size_t dstlen)
{
    z_stream zStream;
    int rc;

    memset(&zStream, 0, sizeof(zStream));
    zStream.next_in = src;
    zStream.avail_in = srclen;
    zStream.next_out = dst;
    zStream.avail_out = dstlen;
    rc = inflateInit2(&zStream, (MAX_WBITS + 32)); /* +32 means "handle gzip" */
    if ( rc != Z_OK )
    {
        xc_dom_panic(XC_INTERNAL_ERROR,
                     "%s: inflateInit2 failed (rc=%d)\n", __FUNCTION__, rc);
        return -1;
    }
    rc = inflate(&zStream, Z_FINISH);
    inflateEnd(&zStream);
    if ( rc != Z_STREAM_END )
    {
        xc_dom_panic(XC_INTERNAL_ERROR,
                     "%s: inflate failed (rc=%d)\n", __FUNCTION__, rc);
        return -1;
    }

    xc_dom_printf("%s: unzip ok, 0x%zx -> 0x%zx\n",
                  __FUNCTION__, srclen, dstlen);
    return 0;
}

int xc_dom_try_gunzip(struct xc_dom_image *dom, void **blob, size_t * size)
{
    void *unzip;
    size_t unziplen;

    unziplen = xc_dom_check_gzip(*blob, *size);
    if ( unziplen == 0 )
        return 0;

    unzip = xc_dom_malloc(dom, unziplen);
    if ( unzip == NULL )
        return -1;

    if ( xc_dom_do_gunzip(*blob, *size, unzip, unziplen) == -1 )
        return -1;

    *blob = unzip;
    *size = unziplen;
    return 0;
}

/* ------------------------------------------------------------------------ */
/* domain memory                                                            */

void *xc_dom_pfn_to_ptr(struct xc_dom_image *dom, xen_pfn_t pfn,
                        xen_pfn_t count)
{
    struct xc_dom_phys *phys;
    unsigned int page_shift = XC_DOM_PAGE_SHIFT(dom);
    char *mode = "unset";

    if ( pfn > dom->total_pages )
    {
        xc_dom_printf("%s: pfn out of range (0x%" PRIpfn " > 0x%" PRIpfn ")\n",
                      __FUNCTION__, pfn, dom->total_pages);
        return NULL;
    }

    /* already allocated? */
    for ( phys = dom->phys_pages; phys != NULL; phys = phys->next )
    {
        if ( pfn >= (phys->first + phys->count) )
            continue;
        if ( count )
        {
            /* size given: must be completely within the already allocated block */
            if ( (pfn + count) <= phys->first )
                continue;
            if ( (pfn < phys->first) ||
                 ((pfn + count) > (phys->first + phys->count)) )
            {
                xc_dom_printf("%s: request overlaps allocated block"
                              " (req 0x%" PRIpfn "+0x%" PRIpfn ","
                              " blk 0x%" PRIpfn "+0x%" PRIpfn ")\n",
                              __FUNCTION__, pfn, count, phys->first,
                              phys->count);
                return NULL;
            }
        }
        else
        {
            /* no size given: block must be allocated already,
               just hand out a pointer to it */
            if ( pfn < phys->first )
                continue;
        }
        return phys->ptr + ((pfn - phys->first) << page_shift);
    }

    /* allocating is allowed with size specified only */
    if ( count == 0 )
    {
        xc_dom_printf("%s: no block found, no size given,"
                      " can't malloc (pfn 0x%" PRIpfn ")\n",
                      __FUNCTION__, pfn);
        return NULL;
    }

    /* not found, no overlap => allocate */
    phys = xc_dom_malloc(dom, sizeof(*phys));
    if ( phys == NULL )
        return NULL;
    memset(phys, 0, sizeof(*phys));
    phys->first = pfn;
    phys->count = count;

    if ( dom->guest_domid )
    {
        mode = "domU mapping";
        phys->ptr = xc_dom_boot_domU_map(dom, phys->first, phys->count);
        if ( phys->ptr == NULL )
            return NULL;
        dom->alloc_domU_map += phys->count << page_shift;
    }
    else
    {
        int err;

        mode = "anonymous memory";
        phys->ptr = mmap(NULL, phys->count << page_shift,
                         PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON,
                         -1, 0);
        if ( phys->ptr == MAP_FAILED )
        {
            err = errno;
            xc_dom_panic(XC_OUT_OF_MEMORY,
                         "%s: oom: can't allocate 0x%" PRIpfn " pages"
                         " [mmap, errno=%i (%s)]\n",
                         __FUNCTION__, count, err, strerror(err));
            return NULL;
        }
        dom->alloc_mem_map += phys->count << page_shift;
    }

#if 1
    xc_dom_printf("%s: %s: pfn 0x%" PRIpfn "+0x%" PRIpfn " at %p\n",
                  __FUNCTION__, mode, phys->first, phys->count, phys->ptr);
#endif
    phys->next = dom->phys_pages;
    dom->phys_pages = phys;
    return phys->ptr;
}

int xc_dom_alloc_segment(struct xc_dom_image *dom,
                         struct xc_dom_seg *seg, char *name,
                         xen_vaddr_t start, xen_vaddr_t size)
{
    unsigned int page_size = XC_DOM_PAGE_SIZE(dom);
    xen_pfn_t pages = (size + page_size - 1) / page_size;
    void *ptr;

    if ( start == 0 )
        start = dom->virt_alloc_end;

    if ( start & (page_size - 1) )
    {
        xc_dom_panic(XC_INTERNAL_ERROR,
                     "%s: segment start isn't page aligned (0x%" PRIx64 ")\n",
                     __FUNCTION__, start);
        return -1;
    }
    if ( start < dom->virt_alloc_end )
    {
        xc_dom_panic(XC_INTERNAL_ERROR,
                     "%s: segment start too low (0x%" PRIx64 " < 0x%" PRIx64
                     ")\n", __FUNCTION__, start, dom->virt_alloc_end);
        return -1;
    }

    seg->vstart = start;
    seg->vend = start + pages * page_size;
    seg->pfn = (seg->vstart - dom->parms.virt_base) / page_size;
    dom->virt_alloc_end = seg->vend;
    if (dom->allocate)
        dom->allocate(dom, dom->virt_alloc_end);

    xc_dom_printf("%-20s:   %-12s : 0x%" PRIx64 " -> 0x%" PRIx64
                  "  (pfn 0x%" PRIpfn " + 0x%" PRIpfn " pages)\n",
                  __FUNCTION__, name, seg->vstart, seg->vend, seg->pfn, pages);

    /* map and clear pages */
    ptr = xc_dom_seg_to_ptr(dom, seg);
    if ( ptr == NULL )
        return -1;
    memset(ptr, 0, pages * page_size);

    return 0;
}

int xc_dom_alloc_page(struct xc_dom_image *dom, char *name)
{
    unsigned int page_size = XC_DOM_PAGE_SIZE(dom);
    xen_vaddr_t start;
    xen_pfn_t pfn;

    start = dom->virt_alloc_end;
    dom->virt_alloc_end += page_size;
    if (dom->allocate)
        dom->allocate(dom, dom->virt_alloc_end);
    pfn = (start - dom->parms.virt_base) / page_size;

    xc_dom_printf("%-20s:   %-12s : 0x%" PRIx64 " (pfn 0x%" PRIpfn ")\n",
                  __FUNCTION__, name, start, pfn);
    return pfn;
}

void xc_dom_unmap_one(struct xc_dom_image *dom, xen_pfn_t pfn)
{
    unsigned int page_shift = XC_DOM_PAGE_SHIFT(dom);
    struct xc_dom_phys *phys, *prev = NULL;

    for ( phys = dom->phys_pages; phys != NULL; phys = phys->next )
    {
        if ( (pfn >= phys->first) && (pfn < (phys->first + phys->count)) )
            break;
        prev = phys;
    }
    if ( !phys )
    {
        xc_dom_printf("%s: Huh? no mapping with pfn 0x%" PRIpfn "\n",
                      __FUNCTION__, pfn);
        return;
    }

    munmap(phys->ptr, phys->count << page_shift);
    if ( prev )
        prev->next = phys->next;
    else
        dom->phys_pages = phys->next;
}

void xc_dom_unmap_all(struct xc_dom_image *dom)
{
    while ( dom->phys_pages )
        xc_dom_unmap_one(dom, dom->phys_pages->first);
}

/* ------------------------------------------------------------------------ */
/* pluggable kernel loaders                                                 */

static struct xc_dom_loader *first_loader = NULL;
static struct xc_dom_arch *first_hook = NULL;

void xc_dom_register_loader(struct xc_dom_loader *loader)
{
    loader->next = first_loader;
    first_loader = loader;
}

static struct xc_dom_loader *xc_dom_find_loader(struct xc_dom_image *dom)
{
    struct xc_dom_loader *loader = first_loader;

    while ( loader != NULL )
    {
        xc_dom_printf("%s: trying %s loader ... ", __FUNCTION__, loader->name);
        if ( loader->probe(dom) == 0 )
        {
            xc_dom_printf("OK\n");
            return loader;
        }
        xc_dom_printf("failed\n");
        loader = loader->next;
    }
    xc_dom_panic(XC_INVALID_KERNEL, "%s: no loader found\n", __FUNCTION__);
    return NULL;
}

void xc_dom_register_arch_hooks(struct xc_dom_arch *hooks)
{
    hooks->next = first_hook;
    first_hook = hooks;
}

struct xc_dom_arch *xc_dom_find_arch_hooks(char *guest_type)
{
    struct xc_dom_arch *hooks = first_hook;

    while (  hooks != NULL )
    {
        if ( !strcmp(hooks->guest_type, guest_type))
            return hooks;
        hooks = hooks->next;
    }
    xc_dom_panic(XC_INVALID_KERNEL,
                 "%s: not found (type %s)\n", __FUNCTION__, guest_type);
    return NULL;
}

/* ------------------------------------------------------------------------ */
/* public interface                                                         */

void xc_dom_release(struct xc_dom_image *dom)
{
    xc_dom_printf("%s: called\n", __FUNCTION__);
    if ( dom->phys_pages )
        xc_dom_unmap_all(dom);
    xc_dom_free_all(dom);
    free(dom);
}

struct xc_dom_image *xc_dom_allocate(const char *cmdline, const char *features)
{
    struct xc_dom_image *dom;

    xc_dom_printf("%s: cmdline=\"%s\", features=\"%s\"\n",
                  __FUNCTION__, cmdline, features);
    dom = malloc(sizeof(*dom));
    if ( !dom )
        goto err;

    memset(dom, 0, sizeof(*dom));
    if ( cmdline )
        dom->cmdline = xc_dom_strdup(dom, cmdline);
    if ( features )
        elf_xen_parse_features(features, dom->f_requested, NULL);

    dom->parms.virt_base = UNSET_ADDR;
    dom->parms.virt_entry = UNSET_ADDR;
    dom->parms.virt_hypercall = UNSET_ADDR;
    dom->parms.virt_hv_start_low = UNSET_ADDR;
    dom->parms.elf_paddr_offset = UNSET_ADDR;

    dom->alloc_malloc += sizeof(*dom);
    return dom;

 err:
    if ( dom )
        xc_dom_release(dom);
    return NULL;
}

int xc_dom_kernel_file(struct xc_dom_image *dom, const char *filename)
{
    xc_dom_printf("%s: filename=\"%s\"\n", __FUNCTION__, filename);
    dom->kernel_blob = xc_dom_malloc_filemap(dom, filename, &dom->kernel_size);
    if ( dom->kernel_blob == NULL )
        return -1;
    return xc_dom_try_gunzip(dom, &dom->kernel_blob, &dom->kernel_size);
}

int xc_dom_ramdisk_file(struct xc_dom_image *dom, const char *filename)
{
    xc_dom_printf("%s: filename=\"%s\"\n", __FUNCTION__, filename);
    dom->ramdisk_blob =
        xc_dom_malloc_filemap(dom, filename, &dom->ramdisk_size);
    if ( dom->ramdisk_blob == NULL )
        return -1;
//    return xc_dom_try_gunzip(dom, &dom->ramdisk_blob, &dom->ramdisk_size);
    return 0;
}

int xc_dom_kernel_mem(struct xc_dom_image *dom, const void *mem, size_t memsize)
{
    xc_dom_printf("%s: called\n", __FUNCTION__);
    dom->kernel_blob = (void *)mem;
    dom->kernel_size = memsize;
    return xc_dom_try_gunzip(dom, &dom->kernel_blob, &dom->kernel_size);
}

int xc_dom_ramdisk_mem(struct xc_dom_image *dom, const void *mem,
                       size_t memsize)
{
    xc_dom_printf("%s: called\n", __FUNCTION__);
    dom->ramdisk_blob = (void *)mem;
    dom->ramdisk_size = memsize;
//    return xc_dom_try_gunzip(dom, &dom->ramdisk_blob, &dom->ramdisk_size);
    return 0;
}

int xc_dom_parse_image(struct xc_dom_image *dom)
{
    int i;

    xc_dom_printf("%s: called\n", __FUNCTION__);

    /* parse kernel image */
    dom->kernel_loader = xc_dom_find_loader(dom);
    if ( dom->kernel_loader == NULL )
        goto err;
    if ( dom->kernel_loader->parser(dom) != 0 )
        goto err;
    if ( dom->guest_type == NULL )
    {
        xc_dom_panic(XC_INTERNAL_ERROR,
                     "%s: guest_type not set\n", __FUNCTION__);
        goto err;
    }

    /* check features */
    for ( i = 0; i < XENFEAT_NR_SUBMAPS; i++ )
    {
        dom->f_active[i] |= dom->f_requested[i]; /* cmd line */
        dom->f_active[i] |= dom->parms.f_required[i]; /* kernel   */
        if ( (dom->f_active[i] & dom->parms.f_supported[i]) !=
             dom->f_active[i] )
        {
            xc_dom_panic(XC_INVALID_PARAM,
                         "%s: unsupported feature requested\n", __FUNCTION__);
            goto err;
        }
    }
    return 0;

 err:
    return -1;
}

int xc_dom_mem_init(struct xc_dom_image *dom, unsigned int mem_mb)
{
    unsigned int page_shift;
    xen_pfn_t nr_pages;

    dom->arch_hooks = xc_dom_find_arch_hooks(dom->guest_type);
    if ( dom->arch_hooks == NULL )
    {
        xc_dom_panic(XC_INTERNAL_ERROR, "%s: arch hooks not set\n",
                     __FUNCTION__);
        return -1;
    }

    page_shift = XC_DOM_PAGE_SHIFT(dom);
    nr_pages = mem_mb << (20 - page_shift);

    xc_dom_printf("%s: mem %d MB, pages 0x%" PRIpfn " pages, %dk each\n",
                  __FUNCTION__, mem_mb, nr_pages, 1 << (page_shift-10));
    dom->total_pages = nr_pages;

    xc_dom_printf("%s: 0x%" PRIpfn " pages\n",
                  __FUNCTION__, dom->total_pages);

    return 0;
}

int xc_dom_update_guest_p2m(struct xc_dom_image *dom)
{
    uint32_t *p2m_32;
    uint64_t *p2m_64;
    xen_pfn_t i;

    if ( !dom->p2m_guest )
        return 0;

    switch ( dom->arch_hooks->sizeof_pfn )
    {
    case 4:
        xc_dom_printf("%s: dst 32bit, pages 0x%" PRIpfn " \n",
                      __FUNCTION__, dom->total_pages);
        p2m_32 = dom->p2m_guest;
        for ( i = 0; i < dom->total_pages; i++ )
            if ( dom->p2m_host[i] != INVALID_P2M_ENTRY )
                p2m_32[i] = dom->p2m_host[i];
            else
                p2m_32[i] = (uint32_t) - 1;
        break;
    case 8:
        xc_dom_printf("%s: dst 64bit, pages 0x%" PRIpfn " \n",
                      __FUNCTION__, dom->total_pages);
        p2m_64 = dom->p2m_guest;
        for ( i = 0; i < dom->total_pages; i++ )
            if ( dom->p2m_host[i] != INVALID_P2M_ENTRY )
                p2m_64[i] = dom->p2m_host[i];
            else
                p2m_64[i] = (uint64_t) - 1;
        break;
    default:
        xc_dom_panic(XC_INTERNAL_ERROR,
                     "sizeof_pfn is invalid (is %d, can be 4 or 8)",
                     dom->arch_hooks->sizeof_pfn);
        return -1;
    }
    return 0;
}

int xc_dom_build_image(struct xc_dom_image *dom)
{
    unsigned int page_size;

    xc_dom_printf("%s: called\n", __FUNCTION__);

    /* check for arch hooks */
    if ( dom->arch_hooks == NULL )
    {
        xc_dom_panic(XC_INTERNAL_ERROR, "%s: arch hooks not set\n",
                     __FUNCTION__);
        goto err;
    }
    page_size = XC_DOM_PAGE_SIZE(dom);

    /* load kernel */
    if ( xc_dom_alloc_segment(dom, &dom->kernel_seg, "kernel",
                              dom->kernel_seg.vstart,
                              dom->kernel_seg.vend -
                              dom->kernel_seg.vstart) != 0 )
        goto err;
    if ( dom->kernel_loader->loader(dom) != 0 )
        goto err;

    /* load ramdisk */
    if ( dom->ramdisk_blob )
    {
        size_t unziplen, ramdisklen;
        void *ramdiskmap;

        unziplen = xc_dom_check_gzip(dom->ramdisk_blob, dom->ramdisk_size);
        ramdisklen = unziplen ? unziplen : dom->ramdisk_size;
        if ( xc_dom_alloc_segment(dom, &dom->ramdisk_seg, "ramdisk", 0,
                                  ramdisklen) != 0 )
            goto err;
        ramdiskmap = xc_dom_seg_to_ptr(dom, &dom->ramdisk_seg);
        if ( unziplen )
        {
            if ( xc_dom_do_gunzip(dom->ramdisk_blob, dom->ramdisk_size,
                                  ramdiskmap, ramdisklen) == -1 )
                goto err;
        }
        else
            memcpy(ramdiskmap, dom->ramdisk_blob, dom->ramdisk_size);
    }

    /* allocate other pages */
    if ( dom->arch_hooks->alloc_magic_pages(dom) != 0 )
        goto err;
    if ( dom->arch_hooks->count_pgtables )
    {
        dom->arch_hooks->count_pgtables(dom);
        if ( (dom->pgtables > 0) &&
             (xc_dom_alloc_segment(dom, &dom->pgtables_seg, "page tables", 0,
                                   dom->pgtables * page_size) != 0) )
                goto err;
    }
    if ( dom->alloc_bootstack )
        dom->bootstack_pfn = xc_dom_alloc_page(dom, "boot stack");
    xc_dom_printf("%-20s: virt_alloc_end : 0x%" PRIx64 "\n",
                  __FUNCTION__, dom->virt_alloc_end);
    xc_dom_printf("%-20s: virt_pgtab_end : 0x%" PRIx64 "\n",
                  __FUNCTION__, dom->virt_pgtab_end);
    return 0;

 err:
    return -1;
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

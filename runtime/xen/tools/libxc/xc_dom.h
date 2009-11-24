#include <xen/libelf/libelf.h>

#define INVALID_P2M_ENTRY   ((xen_pfn_t)-1)

/* --- typedefs and structs ---------------------------------------- */

typedef uint64_t xen_vaddr_t;
typedef uint64_t xen_paddr_t;

#define PRIpfn PRI_xen_pfn

struct xc_dom_seg {
    xen_vaddr_t vstart;
    xen_vaddr_t vend;
    xen_pfn_t pfn;
};

struct xc_dom_mem {
    struct xc_dom_mem *next;
    void *mmap_ptr;
    size_t mmap_len;
    unsigned char memory[0];
};

struct xc_dom_phys {
    struct xc_dom_phys *next;
    void *ptr;
    xen_pfn_t first;
    xen_pfn_t count;
};

struct xc_dom_image {
    /* files */
    void *kernel_blob;
    size_t kernel_size;
    void *ramdisk_blob;
    size_t ramdisk_size;

    /* arguments and parameters */
    char *cmdline;
    uint32_t f_requested[XENFEAT_NR_SUBMAPS];

    /* info from (elf) kernel image */
    struct elf_dom_parms parms;
    char *guest_type;

    /* memory layout */
    struct xc_dom_seg kernel_seg;
    struct xc_dom_seg ramdisk_seg;
    struct xc_dom_seg p2m_seg;
    struct xc_dom_seg pgtables_seg;
    struct xc_dom_seg devicetree_seg;
    xen_pfn_t start_info_pfn;
    xen_pfn_t console_pfn;
    xen_pfn_t xenstore_pfn;
    xen_pfn_t shared_info_pfn;
    xen_pfn_t bootstack_pfn;
    xen_vaddr_t virt_alloc_end;
    xen_vaddr_t bsd_symtab_start;

    /* initial page tables */
    unsigned int pgtables;
    unsigned int pg_l4;
    unsigned int pg_l3;
    unsigned int pg_l2;
    unsigned int pg_l1;
    unsigned int alloc_bootstack;
    unsigned int extra_pages;
    xen_vaddr_t virt_pgtab_end;

    /* other state info */
    uint32_t f_active[XENFEAT_NR_SUBMAPS];
    xen_pfn_t *p2m_host;
    void *p2m_guest;

    /* physical memory */
    xen_pfn_t total_pages;
    struct xc_dom_phys *phys_pages;
    int realmodearea_log;

    /* malloc memory pool */
    struct xc_dom_mem *memblocks;

    /* memory footprint stats */
    size_t alloc_malloc;
    size_t alloc_mem_map;
    size_t alloc_file_map;
    size_t alloc_domU_map;

    /* misc xen domain config stuff */
    unsigned long flags;
    unsigned int console_evtchn;
    unsigned int xenstore_evtchn;
    xen_pfn_t shared_info_mfn;

    int guest_xc;
    domid_t guest_domid;
    int8_t vhpt_size_log2; /* for IA64 */
    int8_t superpages;
    int shadow_enabled;

    int xen_version;
    xen_capabilities_info_t xen_caps;

    /* kernel loader, arch hooks */
    struct xc_dom_loader *kernel_loader;
    void *private_loader;

    /* kernel loader */
    struct xc_dom_arch *arch_hooks;
    /* allocate up to virt_alloc_end */
    int (*allocate) (struct xc_dom_image * dom, xen_vaddr_t up_to);
};

/* --- pluggable kernel loader ------------------------------------- */

struct xc_dom_loader {
    char *name;
    int (*probe) (struct xc_dom_image * dom);
    int (*parser) (struct xc_dom_image * dom);
    int (*loader) (struct xc_dom_image * dom);

    struct xc_dom_loader *next;
};

#define __init __attribute__ ((constructor))
void xc_dom_register_loader(struct xc_dom_loader *loader);

/* --- arch specific hooks ----------------------------------------- */

struct xc_dom_arch {
    /* pagetable setup */
    int (*alloc_magic_pages) (struct xc_dom_image * dom);
    int (*count_pgtables) (struct xc_dom_image * dom);
    int (*setup_pgtables) (struct xc_dom_image * dom);

    /* arch-specific data structs setup */
    int (*start_info) (struct xc_dom_image * dom);
    int (*shared_info) (struct xc_dom_image * dom, void *shared_info);
    int (*vcpu) (struct xc_dom_image * dom, void *vcpu_ctxt);

    char *guest_type;
    char *native_protocol;
    int page_shift;
    int sizeof_pfn;

    struct xc_dom_arch *next;
};
void xc_dom_register_arch_hooks(struct xc_dom_arch *hooks);

#define XC_DOM_PAGE_SHIFT(dom)  ((dom)->arch_hooks->page_shift)
#define XC_DOM_PAGE_SIZE(dom)   (1 << (dom)->arch_hooks->page_shift)

/* --- main functions ---------------------------------------------- */

struct xc_dom_image *xc_dom_allocate(const char *cmdline, const char *features);
void xc_dom_release_phys(struct xc_dom_image *dom);
void xc_dom_release(struct xc_dom_image *dom);
int xc_dom_mem_init(struct xc_dom_image *dom, unsigned int mem_mb);

size_t xc_dom_check_gzip(void *blob, size_t ziplen);
int xc_dom_do_gunzip(void *src, size_t srclen, void *dst, size_t dstlen);
int xc_dom_try_gunzip(struct xc_dom_image *dom, void **blob, size_t * size);

int xc_dom_kernel_file(struct xc_dom_image *dom, const char *filename);
int xc_dom_ramdisk_file(struct xc_dom_image *dom, const char *filename);
int xc_dom_kernel_mem(struct xc_dom_image *dom, const void *mem,
                      size_t memsize);
int xc_dom_ramdisk_mem(struct xc_dom_image *dom, const void *mem,
                       size_t memsize);

int xc_dom_parse_image(struct xc_dom_image *dom);
struct xc_dom_arch *xc_dom_find_arch_hooks(char *guest_type);
int xc_dom_build_image(struct xc_dom_image *dom);
int xc_dom_update_guest_p2m(struct xc_dom_image *dom);

int xc_dom_boot_xen_init(struct xc_dom_image *dom, int xc, domid_t domid);
int xc_dom_boot_mem_init(struct xc_dom_image *dom);
void *xc_dom_boot_domU_map(struct xc_dom_image *dom, xen_pfn_t pfn,
                           xen_pfn_t count);
int xc_dom_boot_image(struct xc_dom_image *dom);
int xc_dom_compat_check(struct xc_dom_image *dom);

/* --- debugging bits ---------------------------------------------- */

extern FILE *xc_dom_logfile;

void xc_dom_loginit(void);
int xc_dom_printf(const char *fmt, ...) __attribute__ ((format(printf, 1, 2)));
int xc_dom_panic_func(const char *file, int line, xc_error_code err,
                      const char *fmt, ...)
    __attribute__ ((format(printf, 4, 5)));
#define xc_dom_panic(err, fmt, args...) \
    xc_dom_panic_func(__FILE__, __LINE__, err, fmt, ## args)
#define xc_dom_trace(mark) \
    xc_dom_printf("%s:%d: trace %s\n", __FILE__, __LINE__, mark)

void xc_dom_log_memory_footprint(struct xc_dom_image *dom);

/* --- simple memory pool ------------------------------------------ */

void *xc_dom_malloc(struct xc_dom_image *dom, size_t size);
void *xc_dom_malloc_page_aligned(struct xc_dom_image *dom, size_t size);
void *xc_dom_malloc_filemap(struct xc_dom_image *dom,
                            const char *filename, size_t * size);
char *xc_dom_strdup(struct xc_dom_image *dom, const char *str);

/* --- alloc memory pool ------------------------------------------- */

int xc_dom_alloc_page(struct xc_dom_image *dom, char *name);
int xc_dom_alloc_segment(struct xc_dom_image *dom,
                         struct xc_dom_seg *seg, char *name,
                         xen_vaddr_t start, xen_vaddr_t size);

/* --- misc bits --------------------------------------------------- */

void *xc_dom_pfn_to_ptr(struct xc_dom_image *dom, xen_pfn_t first,
                        xen_pfn_t count);
void xc_dom_unmap_one(struct xc_dom_image *dom, xen_pfn_t pfn);
void xc_dom_unmap_all(struct xc_dom_image *dom);

static inline void *xc_dom_seg_to_ptr(struct xc_dom_image *dom,
                                      struct xc_dom_seg *seg)
{
    xen_vaddr_t segsize = seg->vend - seg->vstart;
    unsigned int page_size = XC_DOM_PAGE_SIZE(dom);
    xen_pfn_t pages = (segsize + page_size - 1) / page_size;

    return xc_dom_pfn_to_ptr(dom, seg->pfn, pages);
}

static inline void *xc_dom_vaddr_to_ptr(struct xc_dom_image *dom,
                                        xen_vaddr_t vaddr)
{
    unsigned int page_size = XC_DOM_PAGE_SIZE(dom);
    xen_pfn_t page = (vaddr - dom->parms.virt_base) / page_size;
    unsigned int offset = (vaddr - dom->parms.virt_base) % page_size;
    void *ptr = xc_dom_pfn_to_ptr(dom, page, 0);
    return (ptr ? (ptr + offset) : NULL);
}

static inline int xc_dom_feature_translated(struct xc_dom_image *dom)
{
    return elf_xen_feature_get(XENFEAT_auto_translated_physmap, dom->f_active);
}

static inline xen_pfn_t xc_dom_p2m_host(struct xc_dom_image *dom, xen_pfn_t pfn)
{
    if (dom->shadow_enabled)
        return pfn;
    return dom->p2m_host[pfn];
}

static inline xen_pfn_t xc_dom_p2m_guest(struct xc_dom_image *dom,
                                         xen_pfn_t pfn)
{
    if (xc_dom_feature_translated(dom))
        return pfn;
    return dom->p2m_host[pfn];
}

/* --- arch bits --------------------------------------------------- */

int arch_setup_meminit(struct xc_dom_image *dom);
int arch_setup_bootearly(struct xc_dom_image *dom);
int arch_setup_bootlate(struct xc_dom_image *dom);

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

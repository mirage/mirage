/*
 * New elf format support.
 * Copyright (c) 2007 Isaku Yamahata <yamahata at valinux co jp>
 *                    VA Linux Systems Japan K.K.
 */

#include <sys/ptrace.h>
#include <sys/wait.h>
#include "xc_private.h"
#include "xg_private.h"
#include "xc_ptrace.h"
#include <time.h>
#include <inttypes.h>

static unsigned int    max_nr_vcpus;
static unsigned long  *cr3;
static unsigned long  *cr3_phys;
static unsigned long **cr3_virt;
static unsigned long  *pde_phys;
static unsigned long **pde_virt;
static unsigned long  *page_phys;
static unsigned long **page_virt;

static vcpu_guest_context_t *
ptrace_core_get_vcpu_ctxt(unsigned int nr_vcpus)
{
    if (nr_vcpus > max_nr_vcpus) {
        void *new;

#define REALLOC(what) \
        new = realloc(what, nr_vcpus * sizeof(*what)); \
        if (!new) \
            return NULL; \
        memset(what + max_nr_vcpus, 0, \
              (nr_vcpus - max_nr_vcpus) * sizeof(*what)); \
        what = new

        REALLOC(cr3);
        REALLOC(cr3_phys);
        REALLOC(cr3_virt);
        REALLOC(pde_phys);
        REALLOC(pde_virt);
        REALLOC(page_phys);
        REALLOC(page_virt);

#undef REALLOC
        max_nr_vcpus = nr_vcpus;
    }

    return &xc_ptrace_get_vcpu_ctxt(nr_vcpus)->c;
}

/* Leave the code for the old format as is. */
/* --- compatible layer for old format ------------------------------------- */
/* XXX application state */

static int    current_is_hvm_compat = 0;
static long   nr_pages_compat = 0;
static unsigned long  *p2m_array_compat = NULL;
static unsigned long  *m2p_array_compat = NULL;
static unsigned long   pages_offset_compat;

/* --------------------- */

static unsigned long
map_mtop_offset_compat(unsigned long ma)
{
    return pages_offset_compat + (m2p_array_compat[ma >> PAGE_SHIFT] << PAGE_SHIFT);
    return 0;
}


static void *
map_domain_va_core_compat(unsigned long domfd, int cpu, void *guest_va)
{
    unsigned long pde, page;
    unsigned long va = (unsigned long)guest_va;
    void *v;

    if (cr3[cpu] != cr3_phys[cpu])
    {
        cr3_phys[cpu] = cr3[cpu];
        if (cr3_virt[cpu])
            munmap(cr3_virt[cpu], PAGE_SIZE);
        v = mmap(
            NULL, PAGE_SIZE, PROT_READ, MAP_PRIVATE, domfd,
            map_mtop_offset_compat(xen_cr3_to_pfn(cr3_phys[cpu])));
        if (v == MAP_FAILED)
        {
            perror("mmap failed");
            return NULL;
        }
        cr3_virt[cpu] = v;
    }
    if ((pde = cr3_virt[cpu][l2_table_offset_i386(va)]) == 0) /* logical address */
        return NULL;
    if (current_is_hvm_compat)
        pde = p2m_array_compat[pde >> PAGE_SHIFT] << PAGE_SHIFT;
    if (pde != pde_phys[cpu])
    {
        pde_phys[cpu] = pde;
        if (pde_virt[cpu])
            munmap(pde_virt[cpu], PAGE_SIZE);
        v = mmap(
            NULL, PAGE_SIZE, PROT_READ, MAP_PRIVATE, domfd,
            map_mtop_offset_compat(pde_phys[cpu]));
        if (v == MAP_FAILED)
            return NULL;
        pde_virt[cpu] = v;
    }
    if ((page = pde_virt[cpu][l1_table_offset_i386(va)]) == 0) /* logical address */
        return NULL;
    if (current_is_hvm_compat)
        page = p2m_array_compat[page >> PAGE_SHIFT] << PAGE_SHIFT;
    if (page != page_phys[cpu])
    {
        page_phys[cpu] = page;
        if (page_virt[cpu])
            munmap(page_virt[cpu], PAGE_SIZE);
        v = mmap(
            NULL, PAGE_SIZE, PROT_READ, MAP_PRIVATE, domfd,
            map_mtop_offset_compat(page_phys[cpu]));
        if (v == MAP_FAILED)
        {
            IPRINTF("cr3 %lx pde %lx page %lx pti %lx\n", cr3[cpu], pde, page, l1_table_offset_i386(va));
            page_phys[cpu] = 0;
            return NULL;
        }
        page_virt[cpu] = v;
    }
    return (void *)(((unsigned long)page_virt[cpu]) | (va & BSD_PAGE_MASK));
}

static int
xc_waitdomain_core_compat(
    int xc_handle,
    int domfd,
    int *status,
    int options)
{
    int nr_vcpus;
    int i;
    vcpu_guest_context_t *ctxt;
    xc_core_header_t header;

    if ( nr_pages_compat == 0 )
    {
        if (read(domfd, &header, sizeof(header)) != sizeof(header))
            return -1;

        current_is_hvm_compat = (header.xch_magic == XC_CORE_MAGIC_HVM);
        if ( !current_is_hvm_compat && (header.xch_magic != XC_CORE_MAGIC) )
        {
            IPRINTF("Magic number missmatch: 0x%08x (file) != "
                    " 0x%08x (code)\n", header.xch_magic,
                    XC_CORE_MAGIC);
            return -1;
        }

        nr_pages_compat = header.xch_nr_pages;
        nr_vcpus = header.xch_nr_vcpus;
        pages_offset_compat = header.xch_pages_offset;

        if ((ctxt = ptrace_core_get_vcpu_ctxt(nr_vcpus)) == NULL)
        {
            IPRINTF("Could not allocate vcpu context array\n");
            return -1;
        }

        if (read(domfd, ctxt, sizeof(vcpu_guest_context_t)*nr_vcpus) !=
            sizeof(vcpu_guest_context_t)*nr_vcpus)
            return -1;

        for (i = 0; i < nr_vcpus; i++)
            cr3[i] = ctxt[i].ctrlreg[3];

        if ((p2m_array_compat = malloc(nr_pages_compat * sizeof(unsigned long))) == NULL)
        {
            IPRINTF("Could not allocate p2m_array\n");
            return -1;
        }

        if (read(domfd, p2m_array_compat, sizeof(unsigned long)*nr_pages_compat) !=
            sizeof(unsigned long)*nr_pages_compat)
            return -1;

        if ((m2p_array_compat = malloc((1<<20) * sizeof(unsigned long))) == NULL)
        {
            IPRINTF("Could not allocate m2p array\n");
            return -1;
        }
        memset(m2p_array_compat, 0, sizeof(unsigned long)* 1 << 20);

        for (i = 0; i < nr_pages_compat; i++)
            m2p_array_compat[p2m_array_compat[i]] = i;
    }
    return 0;
}


/* --- new format based on ELF -------------------------------------------- */
#include "xc_core.h"

static int
pread_exact(int fd, void* buffer, size_t size, off_t offset)
{
    off_t ret;
    unsigned char *buf = buffer;
    size_t done = 0;
    ret = lseek(fd, offset, SEEK_SET);
    if (ret < 0 || ret != offset)
        return -1;

    while (done < size) {
        ssize_t s = read(fd, buf, size - done);
        if (s == -1 && errno == EINTR)
            continue;
        if (s <= 0)
            return -1;

        done += s;
        buf += s;
    }
    return 0;
}

struct elf_core
{
    int         domfd;
    Elf64_Ehdr  ehdr;

    char*       shdr;
    
    char*       shstrtab;
    uint64_t    shstrtab_size;

    char*       note_sec;
    uint64_t    note_sec_size;
};

static int
elf_core_alloc_read_sec_by_index(struct elf_core* ecore, uint16_t index,
                                 char** buf, uint64_t* size);
static int
elf_core_alloc_read_sec_by_name(struct elf_core* ecore, const char* name,
                                char** buf, uint64_t* size);

static void
elf_core_free(struct elf_core* ecore)
{
    if (ecore->shdr != NULL) {
        free(ecore->shdr);
        ecore->shdr = NULL;
    }
    if (ecore->shstrtab != NULL) {
        free(ecore->shstrtab);
        ecore->shstrtab = NULL;
    }
    if (ecore->note_sec != NULL) {
        free(ecore->note_sec);
        ecore->note_sec = NULL;
    }
}

static int
elf_core_init(struct elf_core* ecore, int domfd)
{
    uint64_t sh_size;
    ecore->domfd = domfd;
    ecore->shdr = NULL;
    ecore->shstrtab = NULL;
    ecore->note_sec = NULL;
    
    if (pread_exact(ecore->domfd, &ecore->ehdr, sizeof(ecore->ehdr), 0) < 0)
        goto out;
    
    /* check elf header */
    if (!IS_ELF(ecore->ehdr) || ecore->ehdr.e_type != ET_CORE)
        goto out;
    if (ecore->ehdr.e_ident[EI_CLASS] != ELFCLASS64)
        goto out;
    /* check elf header more: EI_DATA, EI_VERSION, e_machine... */

    /* read section headers */
    sh_size = ecore->ehdr.e_shentsize * ecore->ehdr.e_shnum;
    ecore->shdr = malloc(sh_size);
    if (ecore->shdr == NULL)
        goto out;
    if (pread_exact(ecore->domfd, ecore->shdr, sh_size,
                    ecore->ehdr.e_shoff) < 0)
        goto out;

    /* read shstrtab */
    if (elf_core_alloc_read_sec_by_index(ecore, ecore->ehdr.e_shstrndx,
                                         &ecore->shstrtab,
                                         &ecore->shstrtab_size) < 0)
        goto out;

    /* read .note.Xen section */
    if (elf_core_alloc_read_sec_by_name(ecore, XEN_DUMPCORE_SEC_NOTE,
                                        &ecore->note_sec,
                                        &ecore->note_sec_size) < 0)
        goto out;

    return 0;
out:
    elf_core_free(ecore);
    return -1;
}

static int
elf_core_search_note(struct elf_core* ecore, const char* name, uint32_t type,
                     void** elfnotep)
{
    const char* note_sec_end = ecore->note_sec + ecore->note_sec_size;
    const char* n;

    n = ecore->note_sec;
    while (n < note_sec_end) {
        const struct elfnote *elfnote = (const struct elfnote *)n;
        if (elfnote->namesz == strlen(name) + 1 &&
            strncmp(elfnote->name, name, elfnote->namesz) == 0 &&
            elfnote->type == type) {
            *elfnotep = (void*)elfnote;
            return 0;
        }

        n += sizeof(*elfnote) + elfnote->descsz;
    }
    return -1;
}

static int
elf_core_alloc_read_sec(struct elf_core* ecore, const Elf64_Shdr* shdr,
                        char** buf)
{
    int ret;
    *buf = malloc(shdr->sh_size);
    if (*buf == NULL)
        return -1;
    ret = pread_exact(ecore->domfd, *buf, shdr->sh_size, shdr->sh_offset);
    if (ret < 0) {
        free(*buf);
        *buf = NULL;
    }
    return ret;
}

static Elf64_Shdr*
elf_core_shdr_by_index(struct elf_core* ecore, uint16_t index)
{
    if (index >= ecore->ehdr.e_shnum)
        return NULL;
    return (Elf64_Shdr*)(ecore->shdr + ecore->ehdr.e_shentsize * index);
}

static int
elf_core_alloc_read_sec_by_index(struct elf_core* ecore, uint16_t index,
                                 char** buf, uint64_t* size)
{
    Elf64_Shdr* shdr = elf_core_shdr_by_index(ecore, index);
    if (shdr == NULL)
        return -1;
    if (size != NULL)
        *size = shdr->sh_size;
    return elf_core_alloc_read_sec(ecore, shdr, buf);
}

static Elf64_Shdr*
elf_core_shdr_by_name(struct elf_core* ecore, const char* name)
{
    const char* s;
    for (s = ecore->shdr;
         s < ecore->shdr + ecore->ehdr.e_shentsize * ecore->ehdr.e_shnum;
         s += ecore->ehdr.e_shentsize) {
        Elf64_Shdr* shdr = (Elf64_Shdr*)s;

        if (strncmp(ecore->shstrtab + shdr->sh_name, name, strlen(name)) == 0)
            return shdr;
    }

    return NULL;
}

static int
elf_core_read_sec_by_name(struct elf_core* ecore, const char* name, char* buf)
{
    Elf64_Shdr* shdr = elf_core_shdr_by_name(ecore, name);
    return pread_exact(ecore->domfd, buf, shdr->sh_size, shdr->sh_offset);
    
}

static int
elf_core_alloc_read_sec_by_name(struct elf_core* ecore, const char* name,
                                char** buf, uint64_t* size)
{
    Elf64_Shdr* shdr = elf_core_shdr_by_name(ecore, name);
    if (shdr == NULL)
        return -1;
    if (size != NULL)
        *size = shdr->sh_size;
    return elf_core_alloc_read_sec(ecore, shdr, buf);
}

/* XXX application state */
static int current_is_auto_translated_physmap = 0;
static struct xen_dumpcore_p2m* p2m_array = NULL; /* for non auto translated physmap mode */
static uint64_t p2m_array_size = 0;
static uint64_t* pfn_array = NULL; /* for auto translated physmap mode */
static uint64_t pfn_array_size = 0;
static long nr_pages = 0;
static uint64_t pages_offset;

static const struct xen_dumpcore_elfnote_format_version_desc
known_format_version[] =
{
    {XEN_DUMPCORE_FORMAT_VERSION((uint64_t)0, (uint64_t)1)},
};
#define KNOWN_FORMAT_VERSION_NR \
    (sizeof(known_format_version)/sizeof(known_format_version[0]))

static unsigned long
map_gmfn_to_offset_elf(unsigned long gmfn)
{
    /* 
     * linear search
     */
    unsigned long i;
    if (current_is_auto_translated_physmap) {
        if (pfn_array == NULL)
            return 0;
        for (i = 0; i < pfn_array_size; i++) {
            if (pfn_array[i] == gmfn) {
                return pages_offset + (i << PAGE_SHIFT);
            }
        }
    } else {
        if (p2m_array == NULL)
            return 0;
        for (i = 0; i < p2m_array_size; i++) {
            if (p2m_array[i].gmfn == gmfn) {
                return pages_offset + (i << PAGE_SHIFT);
            }
        }
    }
    return 0;
}

static void *
map_domain_va_core_elf(unsigned long domfd, int cpu, void *guest_va)
{
    unsigned long pde, page;
    unsigned long va = (unsigned long)guest_va;
    unsigned long offset;
    void *v;

    if (cr3[cpu] != cr3_phys[cpu])
    {
        if (cr3_virt[cpu])
        {
            munmap(cr3_virt[cpu], PAGE_SIZE);
            cr3_virt[cpu] = NULL;
            cr3_phys[cpu] = 0;
        }
        offset = map_gmfn_to_offset_elf(xen_cr3_to_pfn(cr3[cpu]));
        if (offset == 0)
            return NULL;
        v = mmap(NULL, PAGE_SIZE, PROT_READ, MAP_PRIVATE, domfd, offset);
        if (v == MAP_FAILED)
        {
            perror("mmap failed");
            return NULL;
        }
        cr3_phys[cpu] = cr3[cpu];
        cr3_virt[cpu] = v;
    }
    if ((pde = cr3_virt[cpu][l2_table_offset_i386(va)]) == 0) /* logical address */
        return NULL;
    if (pde != pde_phys[cpu])
    {
        if (pde_virt[cpu])
        {
            munmap(pde_virt[cpu], PAGE_SIZE);
            pde_virt[cpu] = NULL;
            pde_phys[cpu] = 0;
        }
        offset = map_gmfn_to_offset_elf(pde >> PAGE_SHIFT);
        if (offset == 0)
            return NULL;
        v = mmap(NULL, PAGE_SIZE, PROT_READ, MAP_PRIVATE, domfd, offset);
        if (v == MAP_FAILED)
            return NULL;
        pde_phys[cpu] = pde;
        pde_virt[cpu] = v;
    }
    if ((page = pde_virt[cpu][l1_table_offset_i386(va)]) == 0) /* logical address */
        return NULL;
    if (page != page_phys[cpu])
    {
        if (page_virt[cpu])
        {
            munmap(page_virt[cpu], PAGE_SIZE);
            page_virt[cpu] = NULL;
            page_phys[cpu] = 0;
        }
        offset = map_gmfn_to_offset_elf(page >> PAGE_SHIFT);
        if (offset == 0)
            return NULL;
        v = mmap(NULL, PAGE_SIZE, PROT_READ, MAP_PRIVATE, domfd, offset);
        if (v == MAP_FAILED)
        {
            IPRINTF("cr3 %lx pde %lx page %lx pti %lx\n",
                    cr3[cpu], pde, page, l1_table_offset_i386(va));
            return NULL;
        }
        page_phys[cpu] = page;
        page_virt[cpu] = v;
    }
    return (void *)(((unsigned long)page_virt[cpu]) | (va & BSD_PAGE_MASK));
}

static int
xc_waitdomain_core_elf(
    int xc_handle,
    int domfd,
    int *status,
    int options)
{
    int i;
    vcpu_guest_context_t *ctxt;
    struct elf_core ecore;

    struct xen_dumpcore_elfnote_none *none;
    struct xen_dumpcore_elfnote_header *header;
    struct xen_dumpcore_elfnote_xen_version *xen_version;
    struct xen_dumpcore_elfnote_format_version *format_version;

    Elf64_Shdr* table_shdr;
    Elf64_Shdr* pages_shdr;

    if (elf_core_init(&ecore, domfd) < 0)
        goto out;
    
    /* .note.Xen: none */
    if (elf_core_search_note(&ecore, XEN_DUMPCORE_ELFNOTE_NAME,
                             XEN_ELFNOTE_DUMPCORE_NONE, (void**)&none) < 0)
        goto out;
    
    /* .note.Xen: header */
    if (elf_core_search_note(&ecore, XEN_DUMPCORE_ELFNOTE_NAME,
                             XEN_ELFNOTE_DUMPCORE_HEADER, (void**)&header) < 0)
        goto out;
    if ((header->header.xch_magic != XC_CORE_MAGIC &&
         header->header.xch_magic != XC_CORE_MAGIC_HVM) ||
        header->header.xch_nr_vcpus == 0 ||
        header->header.xch_nr_pages == 0 ||
        header->header.xch_page_size != PAGE_SIZE)
        goto out;
    current_is_auto_translated_physmap =
        (header->header.xch_magic == XC_CORE_MAGIC_HVM);
    nr_pages = header->header.xch_nr_pages;

    /* .note.Xen: xen_version */
    if (elf_core_search_note(&ecore, XEN_DUMPCORE_ELFNOTE_NAME,
                             XEN_ELFNOTE_DUMPCORE_XEN_VERSION,
                             (void**)&xen_version) < 0)
        goto out;
    /* shifted case covers 32 bit FV guest core file created on 64 bit Dom0 */
    if (xen_version->xen_version.pagesize != PAGE_SIZE &&
        (xen_version->xen_version.pagesize >> 32) != PAGE_SIZE)
        goto out;

    /* .note.Xen: format_version */
    if (elf_core_search_note(&ecore, XEN_DUMPCORE_ELFNOTE_NAME, 
                             XEN_ELFNOTE_DUMPCORE_FORMAT_VERSION,
                             (void**)&format_version) < 0)
        goto out;
    for (i = 0; i < KNOWN_FORMAT_VERSION_NR; i++) {
        if (format_version->format_version.version ==
            known_format_version[i].version)
            break;
    }
    if (i == KNOWN_FORMAT_VERSION_NR) {
        /* complain if unknown format */
        IPRINTF("warning:unknown format version. %"PRIx64"\n",
                format_version->format_version.version);
    }

    if ((ctxt = ptrace_core_get_vcpu_ctxt(header->header.xch_nr_vcpus)) == NULL)
        goto out;

    /* .xen_prstatus: read vcpu_guest_context_t*/
    if (elf_core_read_sec_by_name(&ecore, XEN_DUMPCORE_SEC_PRSTATUS,
                                  (char*)ctxt) < 0)
        goto out;
    for (i = 0; i < header->header.xch_nr_vcpus; i++)
        cr3[i] = ctxt[i].ctrlreg[3];

    /* read .xen_p2m or .xen_pfn */
    if (current_is_auto_translated_physmap) {
        table_shdr = elf_core_shdr_by_name(&ecore, XEN_DUMPCORE_SEC_PFN);
        if (table_shdr == NULL)
            goto out;
        pfn_array_size = table_shdr->sh_size / table_shdr->sh_entsize;
        if (pfn_array != NULL)
            free(pfn_array);
        if (elf_core_alloc_read_sec(&ecore, table_shdr,
                                    (char**)&pfn_array) < 0)
            goto out;
        if (table_shdr->sh_entsize != sizeof(pfn_array[0]))
            goto out;
    } else {
        table_shdr = elf_core_shdr_by_name(&ecore, XEN_DUMPCORE_SEC_P2M);
        if (table_shdr == NULL)
            goto out;
        p2m_array_size = table_shdr->sh_size / table_shdr->sh_entsize;
        if (p2m_array != NULL)
            free(p2m_array);
        if (elf_core_alloc_read_sec(&ecore, table_shdr,
                                    (char**)&p2m_array) < 0)
            goto out;
        if (table_shdr->sh_entsize != sizeof(p2m_array[0]))
            goto out;
    }
    if (table_shdr->sh_size / table_shdr->sh_entsize != nr_pages)
        goto out;

    /* pages_offset and check the file size */
    pages_shdr = elf_core_shdr_by_name(&ecore, XEN_DUMPCORE_SEC_PAGES);
    if (pages_shdr == NULL)
        goto out;
    pages_offset = pages_shdr->sh_offset;
    if ((pages_shdr->sh_size / pages_shdr->sh_entsize) != nr_pages ||
        pages_shdr->sh_entsize != PAGE_SIZE ||
        (pages_shdr->sh_addralign % PAGE_SIZE) != 0 ||
        (pages_offset % PAGE_SIZE) != 0)
        goto out;
    
    elf_core_free(&ecore);
    return 0;

out:
    elf_core_free(&ecore);
    return -1;
}

/* --- interface ----------------------------------------------------------- */

typedef int (*xc_waitdomain_core_t)(int xc_handle,
                                    int domfd,
                                    int *status,
                                    int options);
typedef void *(*map_domain_va_core_t)(unsigned long domfd,
                                      int cpu,
                                      void *guest_va);
struct xc_core_format_type {
    xc_waitdomain_core_t waitdomain_core;
    map_domain_va_core_t map_domain_va_core;
};

static const struct xc_core_format_type format_type[] = {
    {xc_waitdomain_core_elf,    map_domain_va_core_elf},
    {xc_waitdomain_core_compat, map_domain_va_core_compat},
};
#define NR_FORMAT_TYPE (sizeof(format_type)/sizeof(format_type[0]))

/* XXX application state */
static const struct xc_core_format_type* current_format_type = NULL;

void *
map_domain_va_core(unsigned long domfd, int cpu, void *guest_va)
{
    if (current_format_type == NULL)
        return NULL;
    return (current_format_type->map_domain_va_core)(domfd, cpu, guest_va);
}

int
xc_waitdomain_core(int xc_handle, int domfd, int *status, int options)
{
    int ret;
    int i;

    for (i = 0; i < NR_FORMAT_TYPE; i++) {
        ret = (format_type[i].waitdomain_core)(xc_handle, domfd, status,
                                               options);
        if (ret == 0) {
            current_format_type = &format_type[i];
            break;
        }
    }
    return ret;
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

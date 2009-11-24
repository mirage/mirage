#include "xg_private.h"
#include "xc_efi.h"
#include "xc_ia64.h"

/* this is a very ugly way of getting FPSR_DEFAULT.  struct ia64_fpreg is
 * mysteriously declared in two places: /usr/include/asm/fpu.h and
 * /usr/include/bits/sigcontext.h.  The former also defines FPSR_DEFAULT,
 * the latter doesn't but is included (indirectly) by xg_private.h */
#define __ASSEMBLY__
#include <asm/fpu.h>
#undef __IA64_UL
#define __IA64_UL(x)           ((unsigned long)(x))
#undef __ASSEMBLY__

unsigned long
xc_ia64_fpsr_default(void)
{
    return FPSR_DEFAULT;
}

static int
xc_ia64_get_pfn_list(int xc_handle, uint32_t domid, xen_pfn_t *pfn_buf,
                     unsigned int start_page, unsigned int nr_pages)
{
    DECLARE_DOMCTL;
    int ret;

    domctl.cmd = XEN_DOMCTL_getmemlist;
    domctl.domain = (domid_t)domid;
    domctl.u.getmemlist.max_pfns = nr_pages;
    domctl.u.getmemlist.start_pfn = start_page;
    domctl.u.getmemlist.num_pfns = 0;
    set_xen_guest_handle(domctl.u.getmemlist.buffer, pfn_buf);

    if (lock_pages(pfn_buf, nr_pages * sizeof(xen_pfn_t)) != 0) {
        PERROR("Could not lock pfn list buffer");
        return -1;
    }
    ret = do_domctl(xc_handle, &domctl);
    unlock_pages(pfn_buf, nr_pages * sizeof(xen_pfn_t));

    return ret < 0 ? -1 : nr_pages;
}

int
xc_get_pfn_list(int xc_handle, uint32_t domid, uint64_t *pfn_buf,
                unsigned long max_pfns)
{
    return xc_ia64_get_pfn_list(xc_handle, domid, (xen_pfn_t *)pfn_buf,
                                0, max_pfns);
}

long
xc_get_max_pages(int xc_handle, uint32_t domid)
{
    struct xen_domctl domctl;
    domctl.cmd = XEN_DOMCTL_getdomaininfo;
    domctl.domain = (domid_t)domid;
    return ((do_domctl(xc_handle, &domctl) < 0)
            ? -1 : domctl.u.getdomaininfo.max_pages);
}

/* It is possible to get memmap_info and memmap by
   foreign domain page mapping. But it's racy. Use hypercall to avoid race. */
static int
xc_ia64_get_memmap(int xc_handle,
                   uint32_t domid, char *buf, unsigned long bufsize)
{
    privcmd_hypercall_t hypercall;
    int ret;

    hypercall.op = __HYPERVISOR_ia64_dom0vp_op;
    hypercall.arg[0] = IA64_DOM0VP_get_memmap;
    hypercall.arg[1] = domid;
    hypercall.arg[2] = (unsigned long)buf;
    hypercall.arg[3] = bufsize;
    hypercall.arg[4] = 0;

    if (lock_pages(buf, bufsize) != 0)
        return -1;
    ret = do_xen_hypercall(xc_handle, &hypercall);
    unlock_pages(buf, bufsize);
    return ret;
}

int
xc_ia64_copy_memmap(int xc_handle, uint32_t domid, shared_info_t *live_shinfo,
                    xen_ia64_memmap_info_t **memmap_info_p,
                    unsigned long *memmap_info_num_pages_p)
{
    unsigned long gpfn_max_prev;
    unsigned long gpfn_max_post;

    unsigned long num_pages;
    unsigned long num_pages_post;
    unsigned long memmap_size;
    xen_ia64_memmap_info_t *memmap_info;

    int ret;

    gpfn_max_prev = xc_memory_op(xc_handle, XENMEM_maximum_gpfn, &domid);
    if (gpfn_max_prev < 0)
        return -1;

 again:
    num_pages = live_shinfo->arch.memmap_info_num_pages;
    if (num_pages == 0) {
        ERROR("num_pages 0x%x", num_pages);
        return -1;
    }

    memmap_size = num_pages << PAGE_SHIFT;
    memmap_info = malloc(memmap_size);
    if (memmap_info == NULL)
        return -1;
    ret = xc_ia64_get_memmap(xc_handle,
                             domid, (char*)memmap_info, memmap_size);
    if (ret != 0) {
        free(memmap_info);
        return -1;
    }
    xen_rmb();
    num_pages_post = live_shinfo->arch.memmap_info_num_pages;
    if (num_pages != num_pages_post) {
        free(memmap_info);
        num_pages = num_pages_post;
        goto again;
    }

    gpfn_max_post = xc_memory_op(xc_handle, XENMEM_maximum_gpfn, &domid);
    if (gpfn_max_prev < 0) {
        free(memmap_info);
        return -1;
    }
    if (gpfn_max_post > gpfn_max_prev) {
        free(memmap_info);
        gpfn_max_prev = gpfn_max_post;
        goto again;
    }

    /* reject unknown memmap */
    if (memmap_info->efi_memdesc_size != sizeof(efi_memory_desc_t) ||
        (memmap_info->efi_memmap_size / memmap_info->efi_memdesc_size) == 0 ||
        memmap_info->efi_memmap_size >
        (num_pages << PAGE_SHIFT) - sizeof(memmap_info) ||
        memmap_info->efi_memdesc_version != EFI_MEMORY_DESCRIPTOR_VERSION) {
        PERROR("unknown memmap header. defaulting to compat mode.");
        free(memmap_info);
        return -1;
    }

    *memmap_info_p = memmap_info;
    if (memmap_info_num_pages_p != NULL)
        *memmap_info_num_pages_p = num_pages;

    return 0;
}

/*
 * XXX from xen/include/asm-ia64/linux-xen/asm/pgtable.h
 * Should PTRS_PER_PTE be exported by arch-ia64.h?
 */
#define PTRS_PER_PTE    (1UL << (PAGE_SHIFT - 3))

static void*
xc_ia64_map_foreign_p2m(int xc_handle, uint32_t dom,
                        struct xen_ia64_memmap_info *memmap_info,
                        unsigned long flags, unsigned long *p2m_size_p)
{
    unsigned long gpfn_max;
    unsigned long p2m_size;
    void *addr;
    privcmd_hypercall_t hypercall;
    int ret;
    int saved_errno;

    gpfn_max = xc_memory_op(xc_handle, XENMEM_maximum_gpfn, &dom);
    if (gpfn_max < 0)
        return NULL;
    p2m_size =
        (((gpfn_max + 1) + PTRS_PER_PTE - 1) / PTRS_PER_PTE) << PAGE_SHIFT;
    addr = mmap(NULL, p2m_size, PROT_READ, MAP_SHARED, xc_handle, 0);
    if (addr == MAP_FAILED)
        return NULL;

    hypercall.op = __HYPERVISOR_ia64_dom0vp_op;
    hypercall.arg[0] = IA64_DOM0VP_expose_foreign_p2m;
    hypercall.arg[1] = (unsigned long)addr;
    hypercall.arg[2] = dom;
    hypercall.arg[3] = (unsigned long)memmap_info;
    hypercall.arg[4] = flags;

    if (lock_pages(memmap_info,
                   sizeof(*memmap_info) + memmap_info->efi_memmap_size) != 0) {
        saved_errno = errno;
        munmap(addr, p2m_size);
        errno = saved_errno;
        return NULL;
    }
    ret = do_xen_hypercall(xc_handle, &hypercall);
    saved_errno = errno;
    unlock_pages(memmap_info,
                 sizeof(*memmap_info) + memmap_info->efi_memmap_size);
    if (ret < 0) {
        munmap(addr, p2m_size);
        errno = saved_errno;
        return NULL;
    }

    *p2m_size_p = p2m_size;
    return addr;
}

void
xc_ia64_p2m_init(struct xen_ia64_p2m_table *p2m_table)
{
    p2m_table->size = 0;
    p2m_table->p2m = NULL;
}

int
xc_ia64_p2m_map(struct xen_ia64_p2m_table *p2m_table, int xc_handle,
                uint32_t domid, struct xen_ia64_memmap_info *memmap_info,
                unsigned long flag)
{
    p2m_table->p2m = xc_ia64_map_foreign_p2m(xc_handle, domid, memmap_info,
                                             flag, &p2m_table->size);
    if (p2m_table->p2m == NULL) {
        PERROR("Could not map foreign p2m. falling back to old method");
        return -1;
    }
    return 0;
}

void
xc_ia64_p2m_unmap(struct xen_ia64_p2m_table *p2m_table)
{
    if (p2m_table->p2m == NULL)
        return;
    munmap(p2m_table->p2m, p2m_table->size);
    //p2m_table->p2m = NULL;
    //p2m_table->size = 0;
}

/*
 * XXX from xen/include/asm-ia64/linux-xen/asm/pgtable.h
 * Should those be exported by arch-ia64.h?
 */
#define _PAGE_P_BIT             0
#define _PAGE_P                 (1UL << _PAGE_P_BIT)      /* page present bit */
#define _PAGE_PGC_ALLOCATED_BIT 59      /* _PGC_allocated */
#define _PAGE_PGC_ALLOCATED     (1UL << _PAGE_PGC_ALLOCATED_BIT)
#define _PAGE_IO_BIT            60
#define _PAGE_IO                (1UL << _PAGE_IO_BIT)

#define IA64_MAX_PHYS_BITS      50      /* max. number of physical address bits (architected) */
#define _PAGE_PPN_MASK  (((1UL << IA64_MAX_PHYS_BITS) - 1) & ~0xfffUL)

int
xc_ia64_p2m_present(struct xen_ia64_p2m_table *p2m_table, unsigned long gpfn)
{
    if (sizeof(p2m_table->p2m[0]) * gpfn < p2m_table->size) {
        unsigned long pte = p2m_table->p2m[gpfn];
        return !!((pte & _PAGE_P) && !(pte & _PAGE_IO));
    }
    return 0;
}

int
xc_ia64_p2m_allocated(struct xen_ia64_p2m_table *p2m_table, unsigned long gpfn)
{
    if (sizeof(p2m_table->p2m[0]) * gpfn < p2m_table->size) {
        unsigned long pte = p2m_table->p2m[gpfn];
        return !!((pte & _PAGE_P) && (pte & _PAGE_PGC_ALLOCATED) &&
                  !(pte & _PAGE_IO));
    }
    return 0;
}

unsigned long
xc_ia64_p2m_mfn(struct xen_ia64_p2m_table *p2m_table, unsigned long gpfn)
{
    unsigned long pte;
    
    if (sizeof(p2m_table->p2m[0]) * gpfn >= p2m_table->size)
        return INVALID_MFN;
    pte = p2m_table->p2m[gpfn];
    if (pte & _PAGE_IO)
        return INVALID_MFN;
    if (!(pte & _PAGE_P))
        return INVALID_MFN;
    return (pte & _PAGE_PPN_MASK) >> PAGE_SHIFT;
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

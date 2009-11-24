
#ifndef XC_PRIVATE_H
#define XC_PRIVATE_H

#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <sys/ioctl.h>

#include "xenctrl.h"

#include <xen/sys/privcmd.h>

/* valgrind cannot see when a hypercall has filled in some values.  For this
   reason, we must zero the privcmd_hypercall_t or domctl/sysctl instance
   before a call, if using valgrind.  */
#ifdef VALGRIND
#define DECLARE_HYPERCALL privcmd_hypercall_t hypercall = { 0 }
#define DECLARE_DOMCTL struct xen_domctl domctl = { 0 }
#define DECLARE_SYSCTL struct xen_sysctl sysctl = { 0 }
#define DECLARE_PHYSDEV_OP struct physdev_op physdev_op = { 0 }
#else
#define DECLARE_HYPERCALL privcmd_hypercall_t hypercall
#define DECLARE_DOMCTL struct xen_domctl domctl
#define DECLARE_SYSCTL struct xen_sysctl sysctl
#define DECLARE_PHYSDEV_OP struct physdev_op physdev_op
#endif

#undef PAGE_SHIFT
#undef PAGE_SIZE
#undef PAGE_MASK
#define PAGE_SHIFT              XC_PAGE_SHIFT
#define PAGE_SIZE               (1UL << PAGE_SHIFT)
#define PAGE_MASK               (~(PAGE_SIZE-1))

#define DEBUG    1
#define INFO     1
#define PROGRESS 0

/* Force a compilation error if condition is true */
#define XC_BUILD_BUG_ON(p) ((void)sizeof(struct { int:-!!(p); }))

/*
** Define max dirty page cache to permit during save/restore -- need to balance 
** keeping cache usage down with CPU impact of invalidating too often.
** (Currently 16MB)
*/
#define MAX_PAGECACHE_USAGE (4*1024)

#if INFO
#define IPRINTF(_f, _a...) printf(_f , ## _a)
#else
#define IPRINTF(_f, _a...) ((void)0)
#endif

#if DEBUG
#define DPRINTF(_f, _a...) fprintf(stderr, _f , ## _a)
#else
#define DPRINTF(_f, _a...) ((void)0)
#endif

#if PROGRESS
#define PPRINTF(_f, _a...) fprintf(stderr, _f , ## _a)
#else
#define PPRINTF(_f, _a...)
#endif

char *safe_strerror(int errcode);
void xc_set_error(int code, const char *fmt, ...);

#define ERROR(_m, _a...)  xc_set_error(XC_INTERNAL_ERROR, _m , ## _a )
#define PERROR(_m, _a...) xc_set_error(XC_INTERNAL_ERROR, _m " (%d = %s)", \
                                       ## _a , errno, safe_strerror(errno))

int lock_pages(void *addr, size_t len);
void unlock_pages(void *addr, size_t len);

static inline void safe_munlock(const void *addr, size_t len)
{
    int saved_errno = errno;
    (void)munlock(addr, len);
    errno = saved_errno;
}

int do_xen_hypercall(int xc_handle, privcmd_hypercall_t *hypercall);

static inline int do_xen_version(int xc_handle, int cmd, void *dest)
{
    DECLARE_HYPERCALL;

    hypercall.op     = __HYPERVISOR_xen_version;
    hypercall.arg[0] = (unsigned long) cmd;
    hypercall.arg[1] = (unsigned long) dest;

    return do_xen_hypercall(xc_handle, &hypercall);
}

static inline int do_physdev_op(int xc_handle, int cmd, void *op)
{
    int ret = -1;

    DECLARE_HYPERCALL;
    hypercall.op = __HYPERVISOR_physdev_op;
    hypercall.arg[0] = (unsigned long) cmd;
    hypercall.arg[1] = (unsigned long) op;

    if ( lock_pages(op, sizeof(*op)) != 0 )
    {
        PERROR("Could not lock memory for Xen hypercall");
        goto out1;
    }

    if ( (ret = do_xen_hypercall(xc_handle, &hypercall)) < 0 )
    {
        if ( errno == EACCES )
            DPRINTF("physdev operation failed -- need to"
                    " rebuild the user-space tool set?\n");
    }

    unlock_pages(op, sizeof(*op));

out1:
    return ret;
}

static inline int do_domctl(int xc_handle, struct xen_domctl *domctl)
{
    int ret = -1;
    DECLARE_HYPERCALL;

    domctl->interface_version = XEN_DOMCTL_INTERFACE_VERSION;

    hypercall.op     = __HYPERVISOR_domctl;
    hypercall.arg[0] = (unsigned long)domctl;

    if ( lock_pages(domctl, sizeof(*domctl)) != 0 )
    {
        PERROR("Could not lock memory for Xen hypercall");
        goto out1;
    }

    if ( (ret = do_xen_hypercall(xc_handle, &hypercall)) < 0 )
    {
        if ( errno == EACCES )
            DPRINTF("domctl operation failed -- need to"
                    " rebuild the user-space tool set?\n");
    }

    unlock_pages(domctl, sizeof(*domctl));

 out1:
    return ret;
}

static inline int do_sysctl(int xc_handle, struct xen_sysctl *sysctl)
{
    int ret = -1;
    DECLARE_HYPERCALL;

    sysctl->interface_version = XEN_SYSCTL_INTERFACE_VERSION;

    hypercall.op     = __HYPERVISOR_sysctl;
    hypercall.arg[0] = (unsigned long)sysctl;

    if ( lock_pages(sysctl, sizeof(*sysctl)) != 0 )
    {
        PERROR("Could not lock memory for Xen hypercall");
        goto out1;
    }

    if ( (ret = do_xen_hypercall(xc_handle, &hypercall)) < 0 )
    {
        if ( errno == EACCES )
            DPRINTF("sysctl operation failed -- need to"
                    " rebuild the user-space tool set?\n");
    }

    unlock_pages(sysctl, sizeof(*sysctl));

 out1:
    return ret;
}

void *xc_map_foreign_ranges(int xc_handle, uint32_t dom,
                            size_t size, int prot, size_t chunksize,
                            privcmd_mmap_entry_t entries[], int nentries);

void bitmap_64_to_byte(uint8_t *bp, const uint64_t *lp, int nbits);
void bitmap_byte_to_64(uint64_t *lp, const uint8_t *bp, int nbits);

/* Optionally flush file to disk and discard page cache */
void discard_file_cache(int fd, int flush);

#define MAX_MMU_UPDATES 1024
struct xc_mmu {
    mmu_update_t updates[MAX_MMU_UPDATES];
    int          idx;
    domid_t      subject;
};
/* Structure returned by xc_alloc_mmu_updates must be free()'ed by caller. */
struct xc_mmu *xc_alloc_mmu_updates(int xc_handle, domid_t dom);
int xc_add_mmu_update(int xc_handle, struct xc_mmu *mmu,
                   unsigned long long ptr, unsigned long long val);
int xc_flush_mmu_updates(int xc_handle, struct xc_mmu *mmu);

/* Return 0 on success; -1 on error. */
int read_exact(int fd, void *data, size_t size);
int write_exact(int fd, const void *data, size_t size);

int xc_ffs8(uint8_t x);
int xc_ffs16(uint16_t x);
int xc_ffs32(uint32_t x);
int xc_ffs64(uint64_t x);

#endif /* __XC_PRIVATE_H__ */

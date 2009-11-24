/******************************************************************************
 * xc_private.c
 *
 * Helper functions for the rest of the library.
 */

#include <inttypes.h>
#include "xc_private.h"
#include "xg_private.h"
#include <stdarg.h>
#include <pthread.h>

static pthread_key_t last_error_pkey;
static pthread_once_t last_error_pkey_once = PTHREAD_ONCE_INIT;

static pthread_key_t errbuf_pkey;
static pthread_once_t errbuf_pkey_once = PTHREAD_ONCE_INIT;

#if DEBUG
static xc_error_handler error_handler = xc_default_error_handler;
#else
static xc_error_handler error_handler = NULL;
#endif

void xc_default_error_handler(const xc_error *err)
{
    const char *desc = xc_error_code_to_desc(err->code);
    fprintf(stderr, "ERROR %s: %s\n", desc, err->message);
}

static void
_xc_clean_last_error(void *m)
{
    free(m);
    pthread_setspecific(last_error_pkey, NULL);
}

static void
_xc_init_last_error(void)
{
    pthread_key_create(&last_error_pkey, _xc_clean_last_error);
}

static xc_error *
_xc_get_last_error(void)
{
    xc_error *last_error;

    pthread_once(&last_error_pkey_once, _xc_init_last_error);

    last_error = pthread_getspecific(last_error_pkey);
    if (last_error == NULL) {
        last_error = malloc(sizeof(xc_error));
        pthread_setspecific(last_error_pkey, last_error);
        xc_clear_last_error();
    }

    return last_error;
}

const xc_error *xc_get_last_error(void)
{
    return _xc_get_last_error();
}

void xc_clear_last_error(void)
{
    xc_error *last_error = _xc_get_last_error();
    last_error->code = XC_ERROR_NONE;
    last_error->message[0] = '\0';
}

const char *xc_error_code_to_desc(int code)
{
    /* Sync to members of xc_error_code enumeration in xenctrl.h */
    switch ( code )
    {
    case XC_ERROR_NONE:
        return "No error details";
    case XC_INTERNAL_ERROR:
        return "Internal error";
    case XC_INVALID_KERNEL:
        return "Invalid kernel";
    case XC_INVALID_PARAM:
        return "Invalid configuration";
    case XC_OUT_OF_MEMORY:
        return "Out of memory";
    }

    return "Unknown error code";
}

xc_error_handler xc_set_error_handler(xc_error_handler handler)
{
    xc_error_handler old = error_handler;
    error_handler = handler;
    return old;
}

static void _xc_set_error(int code, const char *msg)
{
    xc_error *last_error = _xc_get_last_error();
    last_error->code = code;
    strncpy(last_error->message, msg, XC_MAX_ERROR_MSG_LEN - 1);
    last_error->message[XC_MAX_ERROR_MSG_LEN-1] = '\0';
}

void xc_set_error(int code, const char *fmt, ...)
{
    int saved_errno = errno;
    char msg[XC_MAX_ERROR_MSG_LEN];
    va_list args;

    va_start(args, fmt);
    vsnprintf(msg, XC_MAX_ERROR_MSG_LEN-1, fmt, args);
    msg[XC_MAX_ERROR_MSG_LEN-1] = '\0';
    va_end(args);

    _xc_set_error(code, msg);

    errno = saved_errno;

    if ( error_handler != NULL ) {
        xc_error *last_error = _xc_get_last_error();
        error_handler(last_error);
    }
}

int lock_pages(void *addr, size_t len)
{
      int e = 0;
#ifndef __sun__
      void *laddr = (void *)((unsigned long)addr & PAGE_MASK);
      size_t llen = (len + ((unsigned long)addr - (unsigned long)laddr) +
                     PAGE_SIZE - 1) & PAGE_MASK;
      e = mlock(laddr, llen);
#endif
      return e;
}

void unlock_pages(void *addr, size_t len)
{
#ifndef __sun__
    void *laddr = (void *)((unsigned long)addr & PAGE_MASK);
    size_t llen = (len + ((unsigned long)addr - (unsigned long)laddr) +
                   PAGE_SIZE - 1) & PAGE_MASK;
    safe_munlock(laddr, llen);
#endif
}

/* NB: arr must be locked */
int xc_get_pfn_type_batch(int xc_handle,
                          uint32_t dom, int num, uint32_t *arr)
{
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_getpageframeinfo2;
    domctl.domain = (domid_t)dom;
    domctl.u.getpageframeinfo2.num    = num;
    set_xen_guest_handle(domctl.u.getpageframeinfo2.array, arr);
    return do_domctl(xc_handle, &domctl);
}

int xc_mmuext_op(
    int xc_handle,
    struct mmuext_op *op,
    unsigned int nr_ops,
    domid_t dom)
{
    DECLARE_HYPERCALL;
    long ret = -EINVAL;

    hypercall.op     = __HYPERVISOR_mmuext_op;
    hypercall.arg[0] = (unsigned long)op;
    hypercall.arg[1] = (unsigned long)nr_ops;
    hypercall.arg[2] = (unsigned long)0;
    hypercall.arg[3] = (unsigned long)dom;

    if ( lock_pages(op, nr_ops*sizeof(*op)) != 0 )
    {
        PERROR("Could not lock memory for Xen hypercall");
        goto out1;
    }

    ret = do_xen_hypercall(xc_handle, &hypercall);

    unlock_pages(op, nr_ops*sizeof(*op));

 out1:
    return ret;
}

static int flush_mmu_updates(int xc_handle, struct xc_mmu *mmu)
{
    int err = 0;
    DECLARE_HYPERCALL;

    if ( mmu->idx == 0 )
        return 0;

    hypercall.op     = __HYPERVISOR_mmu_update;
    hypercall.arg[0] = (unsigned long)mmu->updates;
    hypercall.arg[1] = (unsigned long)mmu->idx;
    hypercall.arg[2] = 0;
    hypercall.arg[3] = mmu->subject;

    if ( lock_pages(mmu->updates, sizeof(mmu->updates)) != 0 )
    {
        PERROR("flush_mmu_updates: mmu updates lock_pages failed");
        err = 1;
        goto out;
    }

    if ( do_xen_hypercall(xc_handle, &hypercall) < 0 )
    {
        ERROR("Failure when submitting mmu updates");
        err = 1;
    }

    mmu->idx = 0;

    unlock_pages(mmu->updates, sizeof(mmu->updates));

 out:
    return err;
}

struct xc_mmu *xc_alloc_mmu_updates(int xc_handle, domid_t dom)
{
    struct xc_mmu *mmu = malloc(sizeof(*mmu));
    if ( mmu == NULL )
        return mmu;
    mmu->idx     = 0;
    mmu->subject = dom;
    return mmu;
}

int xc_add_mmu_update(int xc_handle, struct xc_mmu *mmu,
                      unsigned long long ptr, unsigned long long val)
{
    mmu->updates[mmu->idx].ptr = ptr;
    mmu->updates[mmu->idx].val = val;

    if ( ++mmu->idx == MAX_MMU_UPDATES )
        return flush_mmu_updates(xc_handle, mmu);

    return 0;
}

int xc_flush_mmu_updates(int xc_handle, struct xc_mmu *mmu)
{
    return flush_mmu_updates(xc_handle, mmu);
}

int xc_memory_op(int xc_handle,
                 int cmd,
                 void *arg)
{
    DECLARE_HYPERCALL;
    struct xen_memory_reservation *reservation = arg;
    struct xen_machphys_mfn_list *xmml = arg;
    xen_pfn_t *extent_start;
    long ret = -EINVAL;

    hypercall.op     = __HYPERVISOR_memory_op;
    hypercall.arg[0] = (unsigned long)cmd;
    hypercall.arg[1] = (unsigned long)arg;

    switch ( cmd )
    {
    case XENMEM_increase_reservation:
    case XENMEM_decrease_reservation:
    case XENMEM_populate_physmap:
        if ( lock_pages(reservation, sizeof(*reservation)) != 0 )
        {
            PERROR("Could not lock");
            goto out1;
        }
        get_xen_guest_handle(extent_start, reservation->extent_start);
        if ( (extent_start != NULL) &&
             (lock_pages(extent_start,
                    reservation->nr_extents * sizeof(xen_pfn_t)) != 0) )
        {
            PERROR("Could not lock");
            unlock_pages(reservation, sizeof(*reservation));
            goto out1;
        }
        break;
    case XENMEM_machphys_mfn_list:
        if ( lock_pages(xmml, sizeof(*xmml)) != 0 )
        {
            PERROR("Could not lock");
            goto out1;
        }
        get_xen_guest_handle(extent_start, xmml->extent_start);
        if ( lock_pages(extent_start,
                   xmml->max_extents * sizeof(xen_pfn_t)) != 0 )
        {
            PERROR("Could not lock");
            unlock_pages(xmml, sizeof(*xmml));
            goto out1;
        }
        break;
    case XENMEM_add_to_physmap:
        if ( lock_pages(arg, sizeof(struct xen_add_to_physmap)) )
        {
            PERROR("Could not lock");
            goto out1;
        }
        break;
    case XENMEM_current_reservation:
    case XENMEM_maximum_reservation:
    case XENMEM_maximum_gpfn:
        if ( lock_pages(arg, sizeof(domid_t)) )
        {
            PERROR("Could not lock");
            goto out1;
        }
        break;
    case XENMEM_set_pod_target:
    case XENMEM_get_pod_target:
        if ( lock_pages(arg, sizeof(struct xen_pod_target)) )
        {
            PERROR("Could not lock");
            goto out1;
        }
        break;
    }

    ret = do_xen_hypercall(xc_handle, &hypercall);

    switch ( cmd )
    {
    case XENMEM_increase_reservation:
    case XENMEM_decrease_reservation:
    case XENMEM_populate_physmap:
        unlock_pages(reservation, sizeof(*reservation));
        get_xen_guest_handle(extent_start, reservation->extent_start);
        if ( extent_start != NULL )
            unlock_pages(extent_start,
                         reservation->nr_extents * sizeof(xen_pfn_t));
        break;
    case XENMEM_machphys_mfn_list:
        unlock_pages(xmml, sizeof(*xmml));
        get_xen_guest_handle(extent_start, xmml->extent_start);
        unlock_pages(extent_start,
                     xmml->max_extents * sizeof(xen_pfn_t));
        break;
    case XENMEM_add_to_physmap:
        unlock_pages(arg, sizeof(struct xen_add_to_physmap));
        break;
    case XENMEM_current_reservation:
    case XENMEM_maximum_reservation:
    case XENMEM_maximum_gpfn:
        unlock_pages(arg, sizeof(domid_t));
        break;
    case XENMEM_set_pod_target:
    case XENMEM_get_pod_target:
        unlock_pages(arg, sizeof(struct xen_pod_target));
        break;
    }

 out1:
    return ret;
}


long long xc_domain_get_cpu_usage( int xc_handle, domid_t domid, int vcpu )
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_getvcpuinfo;
    domctl.domain = (domid_t)domid;
    domctl.u.getvcpuinfo.vcpu   = (uint16_t)vcpu;
    if ( (do_domctl(xc_handle, &domctl) < 0) )
    {
        PERROR("Could not get info on domain");
        return -1;
    }
    return domctl.u.getvcpuinfo.cpu_time;
}


#ifndef __ia64__
int xc_get_pfn_list(int xc_handle,
                    uint32_t domid,
                    uint64_t *pfn_buf,
                    unsigned long max_pfns)
{
    DECLARE_DOMCTL;
    int ret;
    domctl.cmd = XEN_DOMCTL_getmemlist;
    domctl.domain   = (domid_t)domid;
    domctl.u.getmemlist.max_pfns = max_pfns;
    set_xen_guest_handle(domctl.u.getmemlist.buffer, pfn_buf);

#ifdef VALGRIND
    memset(pfn_buf, 0, max_pfns * sizeof(*pfn_buf));
#endif

    if ( lock_pages(pfn_buf, max_pfns * sizeof(*pfn_buf)) != 0 )
    {
        PERROR("xc_get_pfn_list: pfn_buf lock failed");
        return -1;
    }

    ret = do_domctl(xc_handle, &domctl);

    unlock_pages(pfn_buf, max_pfns * sizeof(*pfn_buf));

    return (ret < 0) ? -1 : domctl.u.getmemlist.num_pfns;
}
#endif

long xc_get_tot_pages(int xc_handle, uint32_t domid)
{
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_getdomaininfo;
    domctl.domain = (domid_t)domid;
    return (do_domctl(xc_handle, &domctl) < 0) ?
        -1 : domctl.u.getdomaininfo.tot_pages;
}

int xc_copy_to_domain_page(int xc_handle,
                           uint32_t domid,
                           unsigned long dst_pfn,
                           const char *src_page)
{
    void *vaddr = xc_map_foreign_range(
        xc_handle, domid, PAGE_SIZE, PROT_WRITE, dst_pfn);
    if ( vaddr == NULL )
        return -1;
    memcpy(vaddr, src_page, PAGE_SIZE);
    munmap(vaddr, PAGE_SIZE);
    return 0;
}

int xc_clear_domain_page(int xc_handle,
                         uint32_t domid,
                         unsigned long dst_pfn)
{
    void *vaddr = xc_map_foreign_range(
        xc_handle, domid, PAGE_SIZE, PROT_WRITE, dst_pfn);
    if ( vaddr == NULL )
        return -1;
    memset(vaddr, 0, PAGE_SIZE);
    munmap(vaddr, PAGE_SIZE);
    return 0;
}

int xc_domctl(int xc_handle, struct xen_domctl *domctl)
{
    return do_domctl(xc_handle, domctl);
}

int xc_sysctl(int xc_handle, struct xen_sysctl *sysctl)
{
    return do_sysctl(xc_handle, sysctl);
}

int xc_version(int xc_handle, int cmd, void *arg)
{
    int rc, argsize = 0;

    switch ( cmd )
    {
    case XENVER_extraversion:
        argsize = sizeof(xen_extraversion_t);
        break;
    case XENVER_compile_info:
        argsize = sizeof(xen_compile_info_t);
        break;
    case XENVER_capabilities:
        argsize = sizeof(xen_capabilities_info_t);
        break;
    case XENVER_changeset:
        argsize = sizeof(xen_changeset_info_t);
        break;
    case XENVER_platform_parameters:
        argsize = sizeof(xen_platform_parameters_t);
        break;
    }

    if ( (argsize != 0) && (lock_pages(arg, argsize) != 0) )
    {
        PERROR("Could not lock memory for version hypercall");
        return -ENOMEM;
    }

#ifdef VALGRIND
    if (argsize != 0)
        memset(arg, 0, argsize);
#endif

    rc = do_xen_version(xc_handle, cmd, arg);

    if ( argsize != 0 )
        unlock_pages(arg, argsize);

    return rc;
}

unsigned long xc_make_page_below_4G(
    int xc_handle, uint32_t domid, unsigned long mfn)
{
    xen_pfn_t old_mfn = mfn;
    xen_pfn_t new_mfn;

    if ( xc_domain_memory_decrease_reservation(
        xc_handle, domid, 1, 0, &old_mfn) != 0 )
    {
        DPRINTF("xc_make_page_below_4G decrease failed. mfn=%lx\n",mfn);
        return 0;
    }

    if ( xc_domain_memory_increase_reservation(
        xc_handle, domid, 1, 0, XENMEMF_address_bits(32), &new_mfn) != 0 )
    {
        DPRINTF("xc_make_page_below_4G increase failed. mfn=%lx\n",mfn);
        return 0;
    }

    return new_mfn;
}

static void
_xc_clean_errbuf(void * m)
{
    free(m);
    pthread_setspecific(errbuf_pkey, NULL);
}

static void
_xc_init_errbuf(void)
{
    pthread_key_create(&errbuf_pkey, _xc_clean_errbuf);
}

char *safe_strerror(int errcode)
{
#define XS_BUFSIZE 32
    char *errbuf;
    static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    char *strerror_str;

    pthread_once(&errbuf_pkey_once, _xc_init_errbuf);

    errbuf = pthread_getspecific(errbuf_pkey);
    if (errbuf == NULL) {
        errbuf = malloc(XS_BUFSIZE);
        pthread_setspecific(errbuf_pkey, errbuf);
    }

    /*
     * Thread-unsafe strerror() is protected by a local mutex. We copy
     * the string to a thread-private buffer before releasing the mutex.
     */
    pthread_mutex_lock(&mutex);
    strerror_str = strerror(errcode);
    strncpy(errbuf, strerror_str, XS_BUFSIZE);
    errbuf[XS_BUFSIZE-1] = '\0';
    pthread_mutex_unlock(&mutex);

    return errbuf;
}

void bitmap_64_to_byte(uint8_t *bp, const uint64_t *lp, int nbits)
{
    uint64_t l;
    int i, j, b;

    for (i = 0, b = 0; nbits > 0; i++, b += sizeof(l)) {
        l = lp[i];
        for (j = 0; (j < sizeof(l)) && (nbits > 0); j++) {
            bp[b+j] = l;
            l >>= 8;
            nbits -= 8;
        }
    }
}

void bitmap_byte_to_64(uint64_t *lp, const uint8_t *bp, int nbits)
{
    uint64_t l;
    int i, j, b;

    for (i = 0, b = 0; nbits > 0; i++, b += sizeof(l)) {
        l = 0;
        for (j = 0; (j < sizeof(l)) && (nbits > 0); j++) {
            l |= (uint64_t)bp[b+j] << (j*8);
            nbits -= 8;
        }
        lp[i] = l;
    }
}

int read_exact(int fd, void *data, size_t size)
{
    size_t offset = 0;
    ssize_t len;

    while ( offset < size )
    {
        len = read(fd, (char *)data + offset, size - offset);
        if ( (len == -1) && (errno == EINTR) )
            continue;
        if ( len <= 0 )
            return -1;
        offset += len;
    }

    return 0;
}

int write_exact(int fd, const void *data, size_t size)
{
    size_t offset = 0;
    ssize_t len;

    while ( offset < size )
    {
        len = write(fd, (const char *)data + offset, size - offset);
        if ( (len == -1) && (errno == EINTR) )
            continue;
        if ( len <= 0 )
            return -1;
        offset += len;
    }

    return 0;
}

int xc_ffs8(uint8_t x)
{
    int i;
    for ( i = 0; i < 8; i++ )
        if ( x & (1u << i) )
            return i+1;
    return 0;
}

int xc_ffs16(uint16_t x)
{
    uint8_t h = x>>8, l = x;
    return l ? xc_ffs8(l) : h ? xc_ffs8(h) + 8 : 0;
}

int xc_ffs32(uint32_t x)
{
    uint16_t h = x>>16, l = x;
    return l ? xc_ffs16(l) : h ? xc_ffs16(h) + 16 : 0;
}

int xc_ffs64(uint64_t x)
{
    uint32_t h = x>>32, l = x;
    return l ? xc_ffs32(l) : h ? xc_ffs32(h) + 32 : 0;
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

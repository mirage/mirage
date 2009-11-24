/******************************************************************************
 * xc_domain.c
 *
 * API for manipulating and obtaining information on domains.
 *
 * Copyright (c) 2003, K A Fraser.
 */

#include "xc_private.h"
#include "xg_save_restore.h"
#include <xen/memory.h>
#include <xen/hvm/hvm_op.h>

int xc_domain_create(int xc_handle,
                     uint32_t ssidref,
                     xen_domain_handle_t handle,
                     uint32_t flags,
                     uint32_t *pdomid)
{
    int err;
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_createdomain;
    domctl.domain = (domid_t)*pdomid;
    domctl.u.createdomain.ssidref = ssidref;
    domctl.u.createdomain.flags   = flags;
    memcpy(domctl.u.createdomain.handle, handle, sizeof(xen_domain_handle_t));
    if ( (err = do_domctl(xc_handle, &domctl)) != 0 )
        return err;

    *pdomid = (uint16_t)domctl.domain;
    return 0;
}


int xc_domain_pause(int xc_handle,
                    uint32_t domid)
{
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_pausedomain;
    domctl.domain = (domid_t)domid;
    return do_domctl(xc_handle, &domctl);
}


int xc_domain_unpause(int xc_handle,
                      uint32_t domid)
{
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_unpausedomain;
    domctl.domain = (domid_t)domid;
    return do_domctl(xc_handle, &domctl);
}


int xc_domain_destroy(int xc_handle,
                      uint32_t domid)
{
    int ret;
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_destroydomain;
    domctl.domain = (domid_t)domid;
    do {
        ret = do_domctl(xc_handle, &domctl);
    } while ( ret && (errno == EAGAIN) );
    return ret;
}

int xc_domain_shutdown(int xc_handle,
                       uint32_t domid,
                       int reason)
{
    int ret = -1;
    sched_remote_shutdown_t arg;
    DECLARE_HYPERCALL;

    hypercall.op     = __HYPERVISOR_sched_op;
    hypercall.arg[0] = (unsigned long)SCHEDOP_remote_shutdown;
    hypercall.arg[1] = (unsigned long)&arg;
    arg.domain_id = domid;
    arg.reason = reason;

    if ( lock_pages(&arg, sizeof(arg)) != 0 )
    {
        PERROR("Could not lock memory for Xen hypercall");
        goto out1;
    }

    ret = do_xen_hypercall(xc_handle, &hypercall);

    unlock_pages(&arg, sizeof(arg));

 out1:
    return ret;
}


int xc_vcpu_setaffinity(int xc_handle,
                        uint32_t domid,
                        int vcpu,
                        uint64_t cpumap)
{
    DECLARE_DOMCTL;
    int ret = -1;
    uint8_t local[sizeof (cpumap)];

    domctl.cmd = XEN_DOMCTL_setvcpuaffinity;
    domctl.domain = (domid_t)domid;
    domctl.u.vcpuaffinity.vcpu    = vcpu;

    bitmap_64_to_byte(local, &cpumap, sizeof(cpumap) * 8);

    set_xen_guest_handle(domctl.u.vcpuaffinity.cpumap.bitmap, local);

    domctl.u.vcpuaffinity.cpumap.nr_cpus = sizeof(cpumap) * 8;
    
    if ( lock_pages(local, sizeof(local)) != 0 )
    {
        PERROR("Could not lock memory for Xen hypercall");
        goto out;
    }

    ret = do_domctl(xc_handle, &domctl);

    unlock_pages(local, sizeof(local));

 out:
    return ret;
}


int xc_vcpu_getaffinity(int xc_handle,
                        uint32_t domid,
                        int vcpu,
                        uint64_t *cpumap)
{
    DECLARE_DOMCTL;
    int ret = -1;
    uint8_t local[sizeof (cpumap)];

    domctl.cmd = XEN_DOMCTL_getvcpuaffinity;
    domctl.domain = (domid_t)domid;
    domctl.u.vcpuaffinity.vcpu = vcpu;

    set_xen_guest_handle(domctl.u.vcpuaffinity.cpumap.bitmap, local);
    domctl.u.vcpuaffinity.cpumap.nr_cpus = sizeof(cpumap) * 8;
    
    if ( lock_pages(local, sizeof(local)) != 0 )
    {
        PERROR("Could not lock memory for Xen hypercall");
        goto out;
    }

    ret = do_domctl(xc_handle, &domctl);

    unlock_pages(local, sizeof (local));
    bitmap_byte_to_64(cpumap, local, sizeof(local) * 8);
 out:
    return ret;
}


int xc_domain_getinfo(int xc_handle,
                      uint32_t first_domid,
                      unsigned int max_doms,
                      xc_dominfo_t *info)
{
    unsigned int nr_doms;
    uint32_t next_domid = first_domid;
    DECLARE_DOMCTL;
    int rc = 0;

    memset(info, 0, max_doms*sizeof(xc_dominfo_t));

    for ( nr_doms = 0; nr_doms < max_doms; nr_doms++ )
    {
        domctl.cmd = XEN_DOMCTL_getdomaininfo;
        domctl.domain = (domid_t)next_domid;
        if ( (rc = do_domctl(xc_handle, &domctl)) < 0 )
            break;
        info->domid      = (uint16_t)domctl.domain;

        info->dying    = !!(domctl.u.getdomaininfo.flags&XEN_DOMINF_dying);
        info->shutdown = !!(domctl.u.getdomaininfo.flags&XEN_DOMINF_shutdown);
        info->paused   = !!(domctl.u.getdomaininfo.flags&XEN_DOMINF_paused);
        info->blocked  = !!(domctl.u.getdomaininfo.flags&XEN_DOMINF_blocked);
        info->running  = !!(domctl.u.getdomaininfo.flags&XEN_DOMINF_running);
        info->hvm      = !!(domctl.u.getdomaininfo.flags&XEN_DOMINF_hvm_guest);
        info->debugged = !!(domctl.u.getdomaininfo.flags&XEN_DOMINF_debugged);

        info->shutdown_reason =
            (domctl.u.getdomaininfo.flags>>XEN_DOMINF_shutdownshift) &
            XEN_DOMINF_shutdownmask;

        if ( info->shutdown && (info->shutdown_reason == SHUTDOWN_crash) )
        {
            info->shutdown = 0;
            info->crashed  = 1;
        }

        info->ssidref  = domctl.u.getdomaininfo.ssidref;
        info->nr_pages = domctl.u.getdomaininfo.tot_pages;
        info->max_memkb = domctl.u.getdomaininfo.max_pages << (PAGE_SHIFT-10);
        info->shared_info_frame = domctl.u.getdomaininfo.shared_info_frame;
        info->cpu_time = domctl.u.getdomaininfo.cpu_time;
        info->nr_online_vcpus = domctl.u.getdomaininfo.nr_online_vcpus;
        info->max_vcpu_id = domctl.u.getdomaininfo.max_vcpu_id;

        memcpy(info->handle, domctl.u.getdomaininfo.handle,
               sizeof(xen_domain_handle_t));

        next_domid = (uint16_t)domctl.domain + 1;
        info++;
    }

    if ( nr_doms == 0 )
        return rc;

    return nr_doms;
}

int xc_domain_getinfolist(int xc_handle,
                          uint32_t first_domain,
                          unsigned int max_domains,
                          xc_domaininfo_t *info)
{
    int ret = 0;
    DECLARE_SYSCTL;

    if ( lock_pages(info, max_domains*sizeof(xc_domaininfo_t)) != 0 )
        return -1;

    sysctl.cmd = XEN_SYSCTL_getdomaininfolist;
    sysctl.u.getdomaininfolist.first_domain = first_domain;
    sysctl.u.getdomaininfolist.max_domains  = max_domains;
    set_xen_guest_handle(sysctl.u.getdomaininfolist.buffer, info);

    if ( xc_sysctl(xc_handle, &sysctl) < 0 )
        ret = -1;
    else
        ret = sysctl.u.getdomaininfolist.num_domains;

    unlock_pages(info, max_domains*sizeof(xc_domaininfo_t));

    return ret;
}

/* get info from hvm guest for save */
int xc_domain_hvm_getcontext(int xc_handle,
                             uint32_t domid,
                             uint8_t *ctxt_buf,
                             uint32_t size)
{
    int ret;
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_gethvmcontext;
    domctl.domain = (domid_t)domid;
    domctl.u.hvmcontext.size = size;
    set_xen_guest_handle(domctl.u.hvmcontext.buffer, ctxt_buf);

    if ( ctxt_buf ) 
        if ( (ret = lock_pages(ctxt_buf, size)) != 0 )
            return ret;

    ret = do_domctl(xc_handle, &domctl);

    if ( ctxt_buf ) 
        unlock_pages(ctxt_buf, size);

    return (ret < 0 ? -1 : domctl.u.hvmcontext.size);
}

/* Get just one element of the HVM guest context.
 * size must be >= HVM_SAVE_LENGTH(type) */
int xc_domain_hvm_getcontext_partial(int xc_handle,
                                     uint32_t domid,
                                     uint16_t typecode,
                                     uint16_t instance,
                                     void *ctxt_buf,
                                     uint32_t size)
{
    int ret;
    DECLARE_DOMCTL;

    if ( !ctxt_buf ) 
        return -EINVAL;

    domctl.cmd = XEN_DOMCTL_gethvmcontext_partial;
    domctl.domain = (domid_t) domid;
    domctl.u.hvmcontext_partial.type = typecode;
    domctl.u.hvmcontext_partial.instance = instance;
    set_xen_guest_handle(domctl.u.hvmcontext_partial.buffer, ctxt_buf);

    if ( (ret = lock_pages(ctxt_buf, size)) != 0 )
        return ret;
    
    ret = do_domctl(xc_handle, &domctl);

    if ( ctxt_buf ) 
        unlock_pages(ctxt_buf, size);

    return ret ? -1 : 0;
}

/* set info to hvm guest for restore */
int xc_domain_hvm_setcontext(int xc_handle,
                             uint32_t domid,
                             uint8_t *ctxt_buf,
                             uint32_t size)
{
    int ret;
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_sethvmcontext;
    domctl.domain = domid;
    domctl.u.hvmcontext.size = size;
    set_xen_guest_handle(domctl.u.hvmcontext.buffer, ctxt_buf);

    if ( (ret = lock_pages(ctxt_buf, size)) != 0 )
        return ret;

    ret = do_domctl(xc_handle, &domctl);

    unlock_pages(ctxt_buf, size);

    return ret;
}

int xc_vcpu_getcontext(int xc_handle,
                       uint32_t domid,
                       uint32_t vcpu,
                       vcpu_guest_context_any_t *ctxt)
{
    int rc;
    DECLARE_DOMCTL;
    size_t sz = sizeof(vcpu_guest_context_any_t);

    domctl.cmd = XEN_DOMCTL_getvcpucontext;
    domctl.domain = (domid_t)domid;
    domctl.u.vcpucontext.vcpu   = (uint16_t)vcpu;
    set_xen_guest_handle(domctl.u.vcpucontext.ctxt, &ctxt->c);

    
    if ( (rc = lock_pages(ctxt, sz)) != 0 )
        return rc;
    rc = do_domctl(xc_handle, &domctl);
    unlock_pages(ctxt, sz);

    return rc;
}


int xc_shadow_control(int xc_handle,
                      uint32_t domid,
                      unsigned int sop,
                      unsigned long *dirty_bitmap,
                      unsigned long pages,
                      unsigned long *mb,
                      uint32_t mode,
                      xc_shadow_op_stats_t *stats)
{
    int rc;
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_shadow_op;
    domctl.domain = (domid_t)domid;
    domctl.u.shadow_op.op     = sop;
    domctl.u.shadow_op.pages  = pages;
    domctl.u.shadow_op.mb     = mb ? *mb : 0;
    domctl.u.shadow_op.mode   = mode;
    set_xen_guest_handle(domctl.u.shadow_op.dirty_bitmap,
                         (uint8_t *)dirty_bitmap);

    rc = do_domctl(xc_handle, &domctl);

    if ( stats )
        memcpy(stats, &domctl.u.shadow_op.stats,
               sizeof(xc_shadow_op_stats_t));
    
    if ( mb ) 
        *mb = domctl.u.shadow_op.mb;

    return (rc == 0) ? domctl.u.shadow_op.pages : rc;
}

int xc_domain_setmaxmem(int xc_handle,
                        uint32_t domid,
                        unsigned int max_memkb)
{
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_max_mem;
    domctl.domain = (domid_t)domid;
    domctl.u.max_mem.max_memkb = max_memkb;
    return do_domctl(xc_handle, &domctl);
}

int xc_domain_pin_memory_cacheattr(int xc_handle,
                                   uint32_t domid,
                                   uint64_t start,
                                   uint64_t end,
                                   uint32_t type)
{
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_pin_mem_cacheattr;
    domctl.domain = (domid_t)domid;
    domctl.u.pin_mem_cacheattr.start = start;
    domctl.u.pin_mem_cacheattr.end = end;
    domctl.u.pin_mem_cacheattr.type = type;
    return do_domctl(xc_handle, &domctl);
}

#if defined(__i386__) || defined(__x86_64__)
#include "xc_e820.h"
int xc_domain_set_memmap_limit(int xc_handle,
                               uint32_t domid,
                               unsigned long map_limitkb)
{
    int rc;

    struct xen_foreign_memory_map fmap = {
        .domid = domid,
        .map = { .nr_entries = 1 }
    };

    struct e820entry e820 = {
        .addr = 0,
        .size = (uint64_t)map_limitkb << 10,
        .type = E820_RAM
    };

    set_xen_guest_handle(fmap.map.buffer, &e820);

    if ( lock_pages(&fmap, sizeof(fmap)) || lock_pages(&e820, sizeof(e820)) )
    {
        PERROR("Could not lock memory for Xen hypercall");
        rc = -1;
        goto out;
    }

    rc = xc_memory_op(xc_handle, XENMEM_set_memory_map, &fmap);

 out:
    unlock_pages(&fmap, sizeof(fmap));
    unlock_pages(&e820, sizeof(e820));
    return rc;
}
#else
int xc_domain_set_memmap_limit(int xc_handle,
                               uint32_t domid,
                               unsigned long map_limitkb)
{
    PERROR("Function not implemented");
    errno = ENOSYS;
    return -1;
}
#endif

int xc_domain_set_time_offset(int xc_handle,
                              uint32_t domid,
                              int32_t time_offset_seconds)
{
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_settimeoffset;
    domctl.domain = (domid_t)domid;
    domctl.u.settimeoffset.time_offset_seconds = time_offset_seconds;
    return do_domctl(xc_handle, &domctl);
}

int xc_domain_set_tsc_native(int xc_handle, uint32_t domid, int is_native)
{
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_set_tsc_native;
    domctl.domain = (domid_t)domid;
    domctl.u.set_tsc_native.is_native = is_native;
    return do_domctl(xc_handle, &domctl);
}

int xc_domain_disable_migrate(int xc_handle, uint32_t domid)
{
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_disable_migrate;
    domctl.domain = (domid_t)domid;
    domctl.u.disable_migrate.disable = 1;
    return do_domctl(xc_handle, &domctl);
}

int xc_domain_memory_increase_reservation(int xc_handle,
                                          uint32_t domid,
                                          unsigned long nr_extents,
                                          unsigned int extent_order,
                                          unsigned int mem_flags,
                                          xen_pfn_t *extent_start)
{
    int err;
    struct xen_memory_reservation reservation = {
        .nr_extents   = nr_extents,
        .extent_order = extent_order,
        .mem_flags    = mem_flags,
        .domid        = domid
    };

    /* may be NULL */
    set_xen_guest_handle(reservation.extent_start, extent_start);

    err = xc_memory_op(xc_handle, XENMEM_increase_reservation, &reservation);
    if ( err == nr_extents )
        return 0;

    if ( err >= 0 )
    {
        DPRINTF("Failed allocation for dom %d: "
                "%ld extents of order %d, mem_flags %x\n",
                domid, nr_extents, extent_order, mem_flags);
        errno = ENOMEM;
        err = -1;
    }

    return err;
}

int xc_domain_memory_decrease_reservation(int xc_handle,
                                          uint32_t domid,
                                          unsigned long nr_extents,
                                          unsigned int extent_order,
                                          xen_pfn_t *extent_start)
{
    int err;
    struct xen_memory_reservation reservation = {
        .nr_extents   = nr_extents,
        .extent_order = extent_order,
        .mem_flags    = 0,
        .domid        = domid
    };

    set_xen_guest_handle(reservation.extent_start, extent_start);

    if ( extent_start == NULL )
    {
        DPRINTF("decrease_reservation extent_start is NULL!\n");
        errno = EINVAL;
        return -1;
    }

    err = xc_memory_op(xc_handle, XENMEM_decrease_reservation, &reservation);
    if ( err == nr_extents )
        return 0;

    if ( err >= 0 )
    {
        DPRINTF("Failed deallocation for dom %d: %ld extents of order %d\n",
                domid, nr_extents, extent_order);
        errno = EINVAL;
        err = -1;
    }

    return err;
}

int xc_domain_memory_populate_physmap(int xc_handle,
                                      uint32_t domid,
                                      unsigned long nr_extents,
                                      unsigned int extent_order,
                                      unsigned int mem_flags,
                                      xen_pfn_t *extent_start)
{
    int err;
    struct xen_memory_reservation reservation = {
        .nr_extents   = nr_extents,
        .extent_order = extent_order,
        .mem_flags    = mem_flags,
        .domid        = domid
    };
    set_xen_guest_handle(reservation.extent_start, extent_start);

    err = xc_memory_op(xc_handle, XENMEM_populate_physmap, &reservation);
    if ( err == nr_extents )
        return 0;

    if ( err >= 0 )
    {
        DPRINTF("Failed allocation for dom %d: %ld extents of order %d\n",
                domid, nr_extents, extent_order);
        errno = EBUSY;
        err = -1;
    }

    return err;
}

static int xc_domain_memory_pod_target(int xc_handle,
                                       int op,
                                       uint32_t domid,
                                       uint64_t target_pages,
                                       uint64_t *tot_pages,
                                       uint64_t *pod_cache_pages,
                                       uint64_t *pod_entries)
{
    int err;

    struct xen_pod_target pod_target = {
        .domid = domid,
        .target_pages = target_pages
    };

    err = xc_memory_op(xc_handle, op, &pod_target);

    if ( err < 0 )
    {
        DPRINTF("Failed %s_memory_target dom %d\n",
                (op==XENMEM_set_pod_target)?"set":"get",
                domid);
        errno = -err;
        err = -1;
    }
    else
        err = 0;

    if ( tot_pages )
        *tot_pages = pod_target.tot_pages;
    if ( pod_cache_pages )
        *pod_cache_pages = pod_target.pod_cache_pages;
    if ( pod_entries )
        *pod_entries = pod_target.pod_entries;

    return err;
}
                                       

int xc_domain_memory_set_pod_target(int xc_handle,
                                    uint32_t domid,
                                    uint64_t target_pages,
                                    uint64_t *tot_pages,
                                    uint64_t *pod_cache_pages,
                                    uint64_t *pod_entries)
{
    return xc_domain_memory_pod_target(xc_handle,
                                       XENMEM_set_pod_target,
                                       domid,
                                       target_pages,
                                       tot_pages,
                                       pod_cache_pages,
                                       pod_entries);
}

int xc_domain_memory_get_pod_target(int xc_handle,
                                    uint32_t domid,
                                    uint64_t *tot_pages,
                                    uint64_t *pod_cache_pages,
                                    uint64_t *pod_entries)
{
    return xc_domain_memory_pod_target(xc_handle,
                                       XENMEM_get_pod_target,
                                       domid,
                                       -1,
                                       tot_pages,
                                       pod_cache_pages,
                                       pod_entries);
}

int xc_domain_max_vcpus(int xc_handle, uint32_t domid, unsigned int max)
{
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_max_vcpus;
    domctl.domain = (domid_t)domid;
    domctl.u.max_vcpus.max    = max;
    return do_domctl(xc_handle, &domctl);
}

int xc_domain_sethandle(int xc_handle, uint32_t domid,
                        xen_domain_handle_t handle)
{
    DECLARE_DOMCTL;
    domctl.cmd = XEN_DOMCTL_setdomainhandle;
    domctl.domain = (domid_t)domid;
    memcpy(domctl.u.setdomainhandle.handle, handle,
           sizeof(xen_domain_handle_t));
    return do_domctl(xc_handle, &domctl);
}

int xc_vcpu_getinfo(int xc_handle,
                    uint32_t domid,
                    uint32_t vcpu,
                    xc_vcpuinfo_t *info)
{
    int rc;
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_getvcpuinfo;
    domctl.domain = (domid_t)domid;
    domctl.u.getvcpuinfo.vcpu   = (uint16_t)vcpu;

    rc = do_domctl(xc_handle, &domctl);

    memcpy(info, &domctl.u.getvcpuinfo, sizeof(*info));

    return rc;
}

int xc_domain_ioport_permission(int xc_handle,
                                uint32_t domid,
                                uint32_t first_port,
                                uint32_t nr_ports,
                                uint32_t allow_access)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_ioport_permission;
    domctl.domain = (domid_t)domid;
    domctl.u.ioport_permission.first_port = first_port;
    domctl.u.ioport_permission.nr_ports = nr_ports;
    domctl.u.ioport_permission.allow_access = allow_access;

    return do_domctl(xc_handle, &domctl);
}

int xc_availheap(int xc_handle,
                 int min_width,
                 int max_width,
                 int node,
                 uint64_t *bytes)
{
    DECLARE_SYSCTL;
    int rc;

    sysctl.cmd = XEN_SYSCTL_availheap;
    sysctl.u.availheap.min_bitwidth = min_width;
    sysctl.u.availheap.max_bitwidth = max_width;
    sysctl.u.availheap.node = node;

    rc = xc_sysctl(xc_handle, &sysctl);

    *bytes = sysctl.u.availheap.avail_bytes;

    return rc;
}

int xc_vcpu_setcontext(int xc_handle,
                       uint32_t domid,
                       uint32_t vcpu,
                       vcpu_guest_context_any_t *ctxt)
{
    DECLARE_DOMCTL;
    int rc;
    size_t sz = sizeof(vcpu_guest_context_any_t);

    if (ctxt == NULL)
    {
        errno = EINVAL;
        return -1;
    }

    domctl.cmd = XEN_DOMCTL_setvcpucontext;
    domctl.domain = domid;
    domctl.u.vcpucontext.vcpu = vcpu;
    set_xen_guest_handle(domctl.u.vcpucontext.ctxt, &ctxt->c);

    if ( (rc = lock_pages(ctxt, sz)) != 0 )
        return rc;
    rc = do_domctl(xc_handle, &domctl);
    
    unlock_pages(ctxt, sz);

    return rc;
}

int xc_domain_irq_permission(int xc_handle,
                             uint32_t domid,
                             uint8_t pirq,
                             uint8_t allow_access)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_irq_permission;
    domctl.domain = domid;
    domctl.u.irq_permission.pirq = pirq;
    domctl.u.irq_permission.allow_access = allow_access;

    return do_domctl(xc_handle, &domctl);
}

int xc_domain_iomem_permission(int xc_handle,
                               uint32_t domid,
                               unsigned long first_mfn,
                               unsigned long nr_mfns,
                               uint8_t allow_access)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_iomem_permission;
    domctl.domain = domid;
    domctl.u.iomem_permission.first_mfn = first_mfn;
    domctl.u.iomem_permission.nr_mfns = nr_mfns;
    domctl.u.iomem_permission.allow_access = allow_access;

    return do_domctl(xc_handle, &domctl);
}

int xc_domain_send_trigger(int xc_handle,
                           uint32_t domid,
                           uint32_t trigger,
                           uint32_t vcpu)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_sendtrigger;
    domctl.domain = domid;
    domctl.u.sendtrigger.trigger = trigger;
    domctl.u.sendtrigger.vcpu = vcpu;

    return do_domctl(xc_handle, &domctl);
}

int xc_set_hvm_param(int handle, domid_t dom, int param, unsigned long value)
{
    DECLARE_HYPERCALL;
    xen_hvm_param_t arg;
    int rc;

    hypercall.op     = __HYPERVISOR_hvm_op;
    hypercall.arg[0] = HVMOP_set_param;
    hypercall.arg[1] = (unsigned long)&arg;
    arg.domid = dom;
    arg.index = param;
    arg.value = value;
    if ( lock_pages(&arg, sizeof(arg)) != 0 )
        return -1;
    rc = do_xen_hypercall(handle, &hypercall);
    unlock_pages(&arg, sizeof(arg));
    return rc;
}

int xc_get_hvm_param(int handle, domid_t dom, int param, unsigned long *value)
{
    DECLARE_HYPERCALL;
    xen_hvm_param_t arg;
    int rc;

    hypercall.op     = __HYPERVISOR_hvm_op;
    hypercall.arg[0] = HVMOP_get_param;
    hypercall.arg[1] = (unsigned long)&arg;
    arg.domid = dom;
    arg.index = param;
    if ( lock_pages(&arg, sizeof(arg)) != 0 )
        return -1;
    rc = do_xen_hypercall(handle, &hypercall);
    unlock_pages(&arg, sizeof(arg));
    *value = arg.value;
    return rc;
}

int xc_domain_setdebugging(int xc_handle,
                           uint32_t domid,
                           unsigned int enable)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_setdebugging;
    domctl.domain = domid;
    domctl.u.setdebugging.enable = enable;
    return do_domctl(xc_handle, &domctl);
}

int xc_assign_device(
    int xc_handle,
    uint32_t domid,
    uint32_t machine_bdf)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_assign_device;
    domctl.domain = domid;
    domctl.u.assign_device.machine_bdf = machine_bdf;

    return do_domctl(xc_handle, &domctl);
}

int xc_get_device_group(
    int xc_handle,
    uint32_t domid,
    uint32_t machine_bdf,
    uint32_t max_sdevs,
    uint32_t *num_sdevs,
    uint32_t *sdev_array)
{
    int rc;
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_get_device_group;
    domctl.domain = (domid_t)domid;

    domctl.u.get_device_group.machine_bdf = machine_bdf;
    domctl.u.get_device_group.max_sdevs = max_sdevs;

    set_xen_guest_handle(domctl.u.get_device_group.sdev_array, sdev_array);

    if ( lock_pages(sdev_array, max_sdevs * sizeof(*sdev_array)) != 0 )
    {
        PERROR("Could not lock memory for xc_get_device_group\n");
        return -ENOMEM;
    }
    rc = do_domctl(xc_handle, &domctl);
    unlock_pages(sdev_array, max_sdevs * sizeof(*sdev_array));

    *num_sdevs = domctl.u.get_device_group.num_sdevs;
    return rc;
}

int xc_test_assign_device(
    int xc_handle,
    uint32_t domid,
    uint32_t machine_bdf)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_test_assign_device;
    domctl.domain = domid;
    domctl.u.assign_device.machine_bdf = machine_bdf;

    return do_domctl(xc_handle, &domctl);
}

int xc_deassign_device(
    int xc_handle,
    uint32_t domid,
    uint32_t machine_bdf)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_deassign_device;
    domctl.domain = domid;
    domctl.u.assign_device.machine_bdf = machine_bdf;
 
    return do_domctl(xc_handle, &domctl);
}

int xc_domain_update_msi_irq(
    int xc_handle,
    uint32_t domid,
    uint32_t gvec,
    uint32_t pirq,
    uint32_t gflags,
    uint64_t gtable)
{
    int rc;
    xen_domctl_bind_pt_irq_t *bind;

    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_bind_pt_irq;
    domctl.domain = (domid_t)domid;

    bind = &(domctl.u.bind_pt_irq);
    bind->hvm_domid = domid;
    bind->irq_type = PT_IRQ_TYPE_MSI;
    bind->machine_irq = pirq;
    bind->u.msi.gvec = gvec;
    bind->u.msi.gflags = gflags;
    bind->u.msi.gtable = gtable;

    rc = do_domctl(xc_handle, &domctl);
    return rc;
}

int xc_domain_unbind_msi_irq(
    int xc_handle,
    uint32_t domid,
    uint32_t gvec,
    uint32_t pirq,
    uint32_t gflags)
{
    int rc;
    xen_domctl_bind_pt_irq_t *bind;

    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_unbind_pt_irq;
    domctl.domain = (domid_t)domid;

    bind = &(domctl.u.bind_pt_irq);
    bind->hvm_domid = domid;
    bind->irq_type = PT_IRQ_TYPE_MSI;
    bind->machine_irq = pirq;
    bind->u.msi.gvec = gvec;
    bind->u.msi.gflags = gflags;

    rc = do_domctl(xc_handle, &domctl);
    return rc;
}

/* Pass-through: binds machine irq to guests irq */
int xc_domain_bind_pt_irq(
    int xc_handle,
    uint32_t domid,
    uint8_t machine_irq,
    uint8_t irq_type,
    uint8_t bus,
    uint8_t device,
    uint8_t intx,
    uint8_t isa_irq)
{
    int rc;
    xen_domctl_bind_pt_irq_t * bind;
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_bind_pt_irq;
    domctl.domain = (domid_t)domid;

    bind = &(domctl.u.bind_pt_irq);
    bind->hvm_domid = domid;
    bind->irq_type = irq_type;
    bind->machine_irq = machine_irq;
    if ( irq_type == PT_IRQ_TYPE_PCI ||
         irq_type == PT_IRQ_TYPE_MSI_TRANSLATE )
    {
        bind->u.pci.bus = bus;
        bind->u.pci.device = device;    
        bind->u.pci.intx = intx;
    } 
    else if ( irq_type == PT_IRQ_TYPE_ISA )
        bind->u.isa.isa_irq = isa_irq;
    
    rc = do_domctl(xc_handle, &domctl);
    return rc;
}

int xc_domain_unbind_pt_irq(
    int xc_handle,
    uint32_t domid,
    uint8_t machine_irq,
    uint8_t irq_type,
    uint8_t bus,
    uint8_t device,
    uint8_t intx,
    uint8_t isa_irq)
{
    int rc;
    xen_domctl_bind_pt_irq_t * bind;
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_unbind_pt_irq;
    domctl.domain = (domid_t)domid;

    bind = &(domctl.u.bind_pt_irq);
    bind->hvm_domid = domid;
    bind->irq_type = irq_type;
    bind->machine_irq = machine_irq;
    bind->u.pci.bus = bus;
    bind->u.pci.device = device;    
    bind->u.pci.intx = intx;
    bind->u.isa.isa_irq = isa_irq;
    
    rc = do_domctl(xc_handle, &domctl);
    return rc;
}

int xc_domain_bind_pt_pci_irq(
    int xc_handle,
    uint32_t domid,
    uint8_t machine_irq,
    uint8_t bus,
    uint8_t device,
    uint8_t intx)
{

    return (xc_domain_bind_pt_irq(xc_handle, domid, machine_irq,
                                  PT_IRQ_TYPE_PCI, bus, device, intx, 0));
}

int xc_domain_bind_pt_isa_irq(
    int xc_handle,
    uint32_t domid,
    uint8_t machine_irq)
{

    return (xc_domain_bind_pt_irq(xc_handle, domid, machine_irq,
                                  PT_IRQ_TYPE_ISA, 0, 0, 0, machine_irq));
}

int xc_domain_memory_mapping(
    int xc_handle,
    uint32_t domid,
    unsigned long first_gfn,
    unsigned long first_mfn,
    unsigned long nr_mfns,
    uint32_t add_mapping)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_memory_mapping;
    domctl.domain = domid;
    domctl.u.memory_mapping.first_gfn = first_gfn;
    domctl.u.memory_mapping.first_mfn = first_mfn;
    domctl.u.memory_mapping.nr_mfns = nr_mfns;
    domctl.u.memory_mapping.add_mapping = add_mapping;

    return do_domctl(xc_handle, &domctl);
}

int xc_domain_ioport_mapping(
    int xc_handle,
    uint32_t domid,
    uint32_t first_gport,
    uint32_t first_mport,
    uint32_t nr_ports,
    uint32_t add_mapping)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_ioport_mapping;
    domctl.domain = domid;
    domctl.u.ioport_mapping.first_gport = first_gport;
    domctl.u.ioport_mapping.first_mport = first_mport;
    domctl.u.ioport_mapping.nr_ports = nr_ports;
    domctl.u.ioport_mapping.add_mapping = add_mapping;

    return do_domctl(xc_handle, &domctl);
}

int xc_domain_set_target(
    int xc_handle,
    uint32_t domid,
    uint32_t target)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_set_target;
    domctl.domain = domid;
    domctl.u.set_target.target = target;

    return do_domctl(xc_handle, &domctl);
}

int xc_domain_subscribe_for_suspend(
    int xc_handle, domid_t dom, evtchn_port_t port)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_subscribe;
    domctl.domain = dom;
    domctl.u.subscribe.port = port;

    return do_domctl(xc_handle, &domctl);
}

int xc_domain_set_machine_address_size(int xc,
                                       uint32_t domid,
                                       unsigned int width)
{
    DECLARE_DOMCTL;

    memset(&domctl, 0, sizeof(domctl));
    domctl.domain = domid;
    domctl.cmd    = XEN_DOMCTL_set_machine_address_size;
    domctl.u.address_size.size = width;

    return do_domctl(xc, &domctl);
}


int xc_domain_get_machine_address_size(int xc, uint32_t domid)
{
    DECLARE_DOMCTL;
    int rc;

    memset(&domctl, 0, sizeof(domctl));
    domctl.domain = domid;
    domctl.cmd    = XEN_DOMCTL_get_machine_address_size;

    rc = do_domctl(xc, &domctl);

    return rc == 0 ? domctl.u.address_size.size : rc;
}

int xc_domain_suppress_spurious_page_faults(int xc, uint32_t domid)
{
    DECLARE_DOMCTL;

    memset(&domctl, 0, sizeof(domctl));
    domctl.domain = domid;
    domctl.cmd    = XEN_DOMCTL_suppress_spurious_page_faults;

    return do_domctl(xc, &domctl);

}

int xc_domain_debug_control(int xc, uint32_t domid, uint32_t sop, uint32_t vcpu)
{
    DECLARE_DOMCTL;

    memset(&domctl, 0, sizeof(domctl));
    domctl.domain = (domid_t)domid;
    domctl.cmd = XEN_DOMCTL_debug_op;
    domctl.u.debug_op.op     = sop;
    domctl.u.debug_op.vcpu   = vcpu;

    return do_domctl(xc, &domctl);
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

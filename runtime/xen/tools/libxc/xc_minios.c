/******************************************************************************
 *
 * Copyright 2007-2008 Samuel Thibault <samuel.thibault@eu.citrix.com>.
 * All rights reserved.
 * Use is subject to license terms.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2 of the
 * License.
 */

#undef NDEBUG
#include <mini-os/types.h>
#include <mini-os/os.h>
#include <mini-os/mm.h>
#include <mini-os/lib.h>
#include <mini-os/gntmap.h>
#include <mini-os/events.h>
#include <mini-os/wait.h>
#include <sys/mman.h>
#include <errno.h>

#include <xen/memory.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <assert.h>
#include <stdint.h>
#include <inttypes.h>

#include "xc_private.h"

extern struct wait_queue_head event_queue;

int xc_interface_open(void)
{
    return alloc_fd(FTYPE_XC);
}

int xc_interface_close(int xc_handle)
{
    files[xc_handle].type = FTYPE_NONE;
    return 0;
}

void *xc_map_foreign_batch(int xc_handle, uint32_t dom, int prot,
                           xen_pfn_t *arr, int num)
{
    unsigned long pt_prot = 0;
#ifdef __ia64__
    /* TODO */
#else
    if (prot & PROT_READ)
	pt_prot = L1_PROT_RO;
    if (prot & PROT_WRITE)
	pt_prot = L1_PROT;
#endif
    return map_frames_ex(arr, num, 1, 0, 1, dom, 1, pt_prot);
}

void *xc_map_foreign_range(int xc_handle, uint32_t dom,
                           int size, int prot,
                           unsigned long mfn)
{
    unsigned long pt_prot = 0;
#ifdef __ia64__
    /* TODO */
#else
    if (prot & PROT_READ)
	pt_prot = L1_PROT_RO;
    if (prot & PROT_WRITE)
	pt_prot = L1_PROT;
#endif
    assert(!(size % getpagesize()));
    return map_frames_ex(&mfn, size / getpagesize(), 0, 1, 1, dom, 0, pt_prot);
}

void *xc_map_foreign_ranges(int xc_handle, uint32_t dom,
                            size_t size, int prot, size_t chunksize,
                            privcmd_mmap_entry_t entries[], int nentries)
{
    unsigned long *mfns;
    int i, j, n;
    unsigned long pt_prot = 0;
    void *ret;
#ifdef __ia64__
    /* TODO */
#else
    if (prot & PROT_READ)
	pt_prot = L1_PROT_RO;
    if (prot & PROT_WRITE)
	pt_prot = L1_PROT;
#endif

    mfns = malloc((size / PAGE_SIZE) * sizeof(*mfns));

    n = 0;
    for (i = 0; i < nentries; i++)
        for (j = 0; j < chunksize / PAGE_SIZE; j++)
            mfns[n++] = entries[i].mfn + j;

    ret = map_frames_ex(mfns, n, 1, 0, 1, dom, 0, pt_prot);
    free(mfns);
    return ret;
}


int do_xen_hypercall(int xc_handle, privcmd_hypercall_t *hypercall)
{
    multicall_entry_t call;
    int i, ret;

    call.op = hypercall->op;
    for (i = 0; i < sizeof(hypercall->arg) / sizeof(*hypercall->arg); i++)
	call.args[i] = hypercall->arg[i];

    ret = HYPERVISOR_multicall(&call, 1);

    if (ret < 0) {
	errno = -ret;
	return -1;
    }
    if ((long) call.result < 0) {
        errno = - (long) call.result;
        return -1;
    }
    return call.result;
}

int xc_find_device_number(const char *name)
{
    printf("xc_find_device_number(%s)\n", name);
    do_exit();
}

int xc_evtchn_open(void)
{
    int fd = alloc_fd(FTYPE_EVTCHN), i;
    for (i = 0; i < MAX_EVTCHN_PORTS; i++) {
	files[fd].evtchn.ports[i].port = -1;
        files[fd].evtchn.ports[i].bound = 0;
    }
    printf("evtchn_open() -> %d\n", fd);
    return fd;
}

int xc_evtchn_close(int xce_handle)
{
    int i;
    for (i = 0; i < MAX_EVTCHN_PORTS; i++)
        if (files[xce_handle].evtchn.ports[i].bound)
            unbind_evtchn(files[xce_handle].evtchn.ports[i].port);
    files[xce_handle].type = FTYPE_NONE;
    return 0;
}

int xc_evtchn_fd(int xce_handle)
{
    return xce_handle;
}

int xc_evtchn_notify(int xce_handle, evtchn_port_t port)
{
    int ret;

    ret = notify_remote_via_evtchn(port);

    if (ret < 0) {
	errno = -ret;
	ret = -1;
    }
    return ret;
}

/* XXX Note: This is not threadsafe */
static int port_alloc(int xce_handle) {
    int i;
    for (i= 0; i < MAX_EVTCHN_PORTS; i++)
	if (files[xce_handle].evtchn.ports[i].port == -1)
	    break;
    if (i == MAX_EVTCHN_PORTS) {
	printf("Too many ports in xc handle\n");
	errno = EMFILE;
	return -1;
    }
    files[xce_handle].evtchn.ports[i].pending = 0;
    return i;
}

static void evtchn_handler(evtchn_port_t port, struct pt_regs *regs, void *data)
{
    int xce_handle = (intptr_t) data;
    int i;
    assert(files[xce_handle].type == FTYPE_EVTCHN);
    mask_evtchn(port);
    for (i= 0; i < MAX_EVTCHN_PORTS; i++)
	if (files[xce_handle].evtchn.ports[i].port == port)
	    break;
    if (i == MAX_EVTCHN_PORTS) {
	printk("Unknown port for handle %d\n", xce_handle);
	return;
    }
    files[xce_handle].evtchn.ports[i].pending = 1;
    files[xce_handle].read = 1;
    wake_up(&event_queue);
}

evtchn_port_or_error_t xc_evtchn_bind_unbound_port(int xce_handle, int domid)
{
    int ret, i;
    evtchn_port_t port;

    assert(get_current() == main_thread);
    i = port_alloc(xce_handle);
    if (i == -1)
	return -1;

    printf("xc_evtchn_bind_unbound_port(%d)", domid);
    ret = evtchn_alloc_unbound(domid, evtchn_handler, (void*)(intptr_t)xce_handle, &port);
    printf(" = %d\n", ret);

    if (ret < 0) {
	errno = -ret;
	return -1;
    }
    files[xce_handle].evtchn.ports[i].bound = 1;
    files[xce_handle].evtchn.ports[i].port = port;
    unmask_evtchn(port);
    return port;
}

evtchn_port_or_error_t xc_evtchn_bind_interdomain(int xce_handle, int domid,
    evtchn_port_t remote_port)
{
    evtchn_port_t local_port;
    int ret, i;

    assert(get_current() == main_thread);
    i = port_alloc(xce_handle);
    if (i == -1)
	return -1;

    printf("xc_evtchn_bind_interdomain(%d, %"PRId32")", domid, remote_port);
    ret = evtchn_bind_interdomain(domid, remote_port, evtchn_handler, (void*)(intptr_t)xce_handle, &local_port);
    printf(" = %d\n", ret);

    if (ret < 0) {
	errno = -ret;
	return -1;
    }
    files[xce_handle].evtchn.ports[i].bound = 1;
    files[xce_handle].evtchn.ports[i].port = local_port;
    unmask_evtchn(local_port);
    return local_port;
}

int xc_evtchn_unbind(int xce_handle, evtchn_port_t port)
{
    int i;
    for (i = 0; i < MAX_EVTCHN_PORTS; i++)
	if (files[xce_handle].evtchn.ports[i].port == port) {
	    files[xce_handle].evtchn.ports[i].port = -1;
	    break;
	}
    if (i == MAX_EVTCHN_PORTS) {
	printf("Warning: couldn't find port %"PRId32" for xc handle %x\n", port, xce_handle);
	errno = -EINVAL;
	return -1;
    }
    files[xce_handle].evtchn.ports[i].bound = 0;
    unbind_evtchn(port);
    return 0;
}

evtchn_port_or_error_t xc_evtchn_bind_virq(int xce_handle, unsigned int virq)
{
    evtchn_port_t port;
    int i;

    assert(get_current() == main_thread);
    i = port_alloc(xce_handle);
    if (i == -1)
	return -1;

    printf("xc_evtchn_bind_virq(%d)", virq);
    port = bind_virq(virq, evtchn_handler, (void*)(intptr_t)xce_handle);

    if (port < 0) {
	errno = -port;
	return -1;
    }
    files[xce_handle].evtchn.ports[i].bound = 1;
    files[xce_handle].evtchn.ports[i].port = port;
    unmask_evtchn(port);
    return port;
}

evtchn_port_or_error_t xc_evtchn_pending(int xce_handle)
{
    int i;
    unsigned long flags;
    evtchn_port_t ret = -1;

    local_irq_save(flags);
    files[xce_handle].read = 0;
    for (i = 0; i < MAX_EVTCHN_PORTS; i++) {
        evtchn_port_t port = files[xce_handle].evtchn.ports[i].port;
        if (port != -1 && files[xce_handle].evtchn.ports[i].pending) {
            if (ret == -1) {
                ret = port;
                files[xce_handle].evtchn.ports[i].pending = 0;
            } else {
                files[xce_handle].read = 1;
                break;
            }
        }
    }
    local_irq_restore(flags);
    return ret;
}

int xc_evtchn_unmask(int xce_handle, evtchn_port_t port)
{
    unmask_evtchn(port);
    return 0;
}

/* Optionally flush file to disk and discard page cache */
void discard_file_cache(int fd, int flush)
{
    if (flush)
        fsync(fd);
}

int xc_gnttab_open(void)
{
    int xcg_handle;
    xcg_handle = alloc_fd(FTYPE_GNTMAP);
    gntmap_init(&files[xcg_handle].gntmap);
    return xcg_handle;
}

int xc_gnttab_close(int xcg_handle)
{
    gntmap_fini(&files[xcg_handle].gntmap);
    files[xcg_handle].type = FTYPE_NONE;
    return 0;
}

void *xc_gnttab_map_grant_ref(int xcg_handle,
                              uint32_t domid,
                              uint32_t ref,
                              int prot)
{
    return gntmap_map_grant_refs(&files[xcg_handle].gntmap,
                                 1,
                                 &domid, 0,
                                 &ref,
                                 prot & PROT_WRITE);
}

void *xc_gnttab_map_grant_refs(int xcg_handle,
                               uint32_t count,
                               uint32_t *domids,
                               uint32_t *refs,
                               int prot)
{
    return gntmap_map_grant_refs(&files[xcg_handle].gntmap,
                                 count,
                                 domids, 1,
                                 refs,
                                 prot & PROT_WRITE);
}

void *xc_gnttab_map_domain_grant_refs(int xcg_handle,
                                      uint32_t count,
                                      uint32_t domid,
                                      uint32_t *refs,
                                      int prot)
{
    return gntmap_map_grant_refs(&files[xcg_handle].gntmap,
                                 count,
                                 &domid, 0,
                                 refs,
                                 prot & PROT_WRITE);
}

int xc_gnttab_munmap(int xcg_handle,
                     void *start_address,
                     uint32_t count)
{
    int ret;
    ret = gntmap_munmap(&files[xcg_handle].gntmap,
                        (unsigned long) start_address,
                        count);
    if (ret < 0) {
        errno = -ret;
        return -1;
    }
    return ret;
}

int xc_gnttab_set_max_grants(int xcg_handle,
                             uint32_t count)
{
    int ret;
    ret = gntmap_set_max_grants(&files[xcg_handle].gntmap,
                                count);
    if (ret < 0) {
        errno = -ret;
        return -1;
    }
    return ret;
}

grant_entry_v1_t *xc_gnttab_map_table_v1(
    int xc_handle, int domid, int *gnt_num)
{
    return NULL;
}

grant_entry_v2_t *xc_gnttab_map_table_v2(
    int xc_handle, int domid, int *gnt_num)
{
    return NULL;
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

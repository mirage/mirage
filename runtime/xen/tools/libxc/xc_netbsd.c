/******************************************************************************
 *
 * Copyright 2006 Sun Microsystems, Inc.  All rights reserved.
 * Use is subject to license terms.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2 of the
 * License.
 */

#include "xc_private.h"

#include <xen/sys/evtchn.h>
#include <unistd.h>
#include <fcntl.h>

int xc_interface_open(void)
{
    int flags, saved_errno;
    int fd = open("/kern/xen/privcmd", O_RDWR);

    if ( fd == -1 )
    {
        PERROR("Could not obtain handle on privileged command interface");
        return -1;
    }

    /* Although we return the file handle as the 'xc handle' the API
       does not specify / guarentee that this integer is in fact
       a file handle. Thus we must take responsiblity to ensure
       it doesn't propagate (ie leak) outside the process */
    if ( (flags = fcntl(fd, F_GETFD)) < 0 )
    {
        PERROR("Could not get file handle flags");
        goto error;
    }
    flags |= FD_CLOEXEC;
    if ( fcntl(fd, F_SETFD, flags) < 0 )
    {
        PERROR("Could not set file handle flags");
        goto error;
    }

    return fd;

 error:
    saved_errno = errno;
    close(fd);
    errno = saved_errno;
    return -1;
}

int xc_interface_close(int xc_handle)
{
    return close(xc_handle);
}

void *xc_map_foreign_batch(int xc_handle, uint32_t dom, int prot,
                           xen_pfn_t *arr, int num)
{
    privcmd_mmapbatch_t ioctlx;
    void *addr;
    addr = mmap(NULL, num*PAGE_SIZE, prot, MAP_ANON | MAP_SHARED, -1, 0);
    if ( addr == MAP_FAILED ) {
        perror("xc_map_foreign_batch: mmap failed");
        return NULL;
    }

    ioctlx.num=num;
    ioctlx.dom=dom;
    ioctlx.addr=(unsigned long)addr;
    ioctlx.arr=arr;
    if ( ioctl(xc_handle, IOCTL_PRIVCMD_MMAPBATCH, &ioctlx) < 0 )
    {
        int saved_errno = errno;
        perror("xc_map_foreign_batch: ioctl failed");
        (void)munmap(addr, num*PAGE_SIZE);
        errno = saved_errno;
        return NULL;
    }
    return addr;

}

void *xc_map_foreign_range(int xc_handle, uint32_t dom,
                           int size, int prot,
                           unsigned long mfn)
{
    privcmd_mmap_t ioctlx;
    privcmd_mmap_entry_t entry;
    void *addr;
    addr = mmap(NULL, size, prot, MAP_ANON | MAP_SHARED, -1, 0);
    if ( addr == MAP_FAILED ) {
        perror("xc_map_foreign_range: mmap failed");
        return NULL;
    }

    ioctlx.num=1;
    ioctlx.dom=dom;
    ioctlx.entry=&entry;
    entry.va=(unsigned long) addr;
    entry.mfn=mfn;
    entry.npages=(size+PAGE_SIZE-1)>>PAGE_SHIFT;
    if ( ioctl(xc_handle, IOCTL_PRIVCMD_MMAP, &ioctlx) < 0 )
    {
        int saved_errno = errno;
        perror("xc_map_foreign_range: ioctl failed");
        (void)munmap(addr, size);
        errno = saved_errno;
        return NULL;
    }
    return addr;
}

void *xc_map_foreign_ranges(int xc_handle, uint32_t dom,
                            size_t size, int prot, size_t chunksize,
                            privcmd_mmap_entry_t entries[], int nentries)
{
	privcmd_mmap_t ioctlx;
	int i, rc;
	void *addr;

	addr = mmap(NULL, size, prot, MAP_ANON | MAP_SHARED, -1, 0);
	if (addr == MAP_FAILED)
		goto mmap_failed;

	for (i = 0; i < nentries; i++) {
		entries[i].va = (uintptr_t)addr + (i * chunksize);
		entries[i].npages = chunksize >> PAGE_SHIFT;
	}

	ioctlx.num   = nentries;
	ioctlx.dom   = dom;
	ioctlx.entry = entries;

	rc = ioctl(xc_handle, IOCTL_PRIVCMD_MMAP, &ioctlx);
	if (rc)
		goto ioctl_failed;

	return addr;

ioctl_failed:
	rc = munmap(addr, size);
	if (rc == -1)
		ERROR("%s: error in error path\n", __FUNCTION__);

mmap_failed:
	return NULL;
}


static int do_privcmd(int xc_handle, unsigned int cmd, unsigned long data)
{
    int err = ioctl(xc_handle, cmd, data);
    if (err == 0)
	return 0;
    else
	return -errno;
}

int do_xen_hypercall(int xc_handle, privcmd_hypercall_t *hypercall)
{
    int error = do_privcmd(xc_handle,
                      IOCTL_PRIVCMD_HYPERCALL,
                      (unsigned long)hypercall);
    if (error)
       return error;
    else
       return (hypercall->retval);
}

#define EVTCHN_DEV_NAME  "/dev/xenevt"

int xc_evtchn_open(void)
{
    return open(EVTCHN_DEV_NAME, O_NONBLOCK|O_RDWR);
}

int xc_evtchn_close(int xce_handle)
{
    return close(xce_handle);
}

int xc_evtchn_fd(int xce_handle)
{
    return xce_handle;
}

int xc_evtchn_notify(int xce_handle, evtchn_port_t port)
{
    struct ioctl_evtchn_notify notify;

    notify.port = port;

    return ioctl(xce_handle, IOCTL_EVTCHN_NOTIFY, &notify);
}

evtchn_port_or_error_t
xc_evtchn_bind_interdomain(int xce_handle, int domid,
                           evtchn_port_t remote_port)
{
    struct ioctl_evtchn_bind_interdomain bind;
    int ret;

    bind.remote_domain = domid;
    bind.remote_port = remote_port;

    ret = ioctl(xce_handle, IOCTL_EVTCHN_BIND_INTERDOMAIN, &bind);
    if (ret == 0)
	return bind.port;
    else
	return -1;
}

int xc_evtchn_unbind(int xce_handle, evtchn_port_t port)
{
    struct ioctl_evtchn_unbind unbind;

    unbind.port = port;

    return ioctl(xce_handle, IOCTL_EVTCHN_UNBIND, &unbind);
}

evtchn_port_or_error_t
xc_evtchn_bind_virq(int xce_handle, unsigned int virq)
{
    struct ioctl_evtchn_bind_virq bind;
    int err;

    bind.virq = virq;

    err = ioctl(xce_handle, IOCTL_EVTCHN_BIND_VIRQ, &bind);
    if (err)
	return -1;
    else
	return bind.port;
}

evtchn_port_or_error_t
xc_evtchn_pending(int xce_handle)
{
    evtchn_port_t port;

    if ( read_exact(xce_handle, (char *)&port, sizeof(port)) == -1 )
        return -1;

    return port;
}

int xc_evtchn_unmask(int xce_handle, evtchn_port_t port)
{
    return write_exact(xce_handle, (char *)&port, sizeof(port));
}

/* Optionally flush file to disk and discard page cache */
void discard_file_cache(int fd, int flush) 
{

    if ( flush && (fsync(fd) < 0) )
    {
        /*PERROR("Failed to flush file: %s", strerror(errno));*/
    }
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

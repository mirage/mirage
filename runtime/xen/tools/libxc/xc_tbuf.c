/******************************************************************************
 * xc_tbuf.c
 *
 * API for manipulating and accessing trace buffer parameters
 *
 * Copyright (c) 2005, Rob Gardner
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

static int tbuf_enable(int xc_handle, int enable)
{
    DECLARE_SYSCTL;

    sysctl.cmd = XEN_SYSCTL_tbuf_op;
    sysctl.interface_version = XEN_SYSCTL_INTERFACE_VERSION;
    if (enable)
        sysctl.u.tbuf_op.cmd  = XEN_SYSCTL_TBUFOP_enable;
    else
        sysctl.u.tbuf_op.cmd  = XEN_SYSCTL_TBUFOP_disable;

    return xc_sysctl(xc_handle, &sysctl);
}

int xc_tbuf_set_size(int xc_handle, unsigned long size)
{
    DECLARE_SYSCTL;

    sysctl.cmd = XEN_SYSCTL_tbuf_op;
    sysctl.interface_version = XEN_SYSCTL_INTERFACE_VERSION;
    sysctl.u.tbuf_op.cmd  = XEN_SYSCTL_TBUFOP_set_size;
    sysctl.u.tbuf_op.size = size;

    return xc_sysctl(xc_handle, &sysctl);
}

int xc_tbuf_get_size(int xc_handle, unsigned long *size)
{
    int rc;
    DECLARE_SYSCTL;

    sysctl.cmd = XEN_SYSCTL_tbuf_op;
    sysctl.interface_version = XEN_SYSCTL_INTERFACE_VERSION;
    sysctl.u.tbuf_op.cmd  = XEN_SYSCTL_TBUFOP_get_info;

    rc = xc_sysctl(xc_handle, &sysctl);
    if (rc == 0)
        *size = sysctl.u.tbuf_op.size;
    return rc;
}

int xc_tbuf_enable(int xc_handle, unsigned long pages, unsigned long *mfn,
                   unsigned long *size)
{
    DECLARE_SYSCTL;
    int rc;

    /*
     * Ignore errors (at least for now) as we get an error if size is already
     * set (since trace buffers cannot be reallocated). If we really have no
     * buffers at all then tbuf_enable() will fail, so this is safe.
     */
    (void)xc_tbuf_set_size(xc_handle, pages);

    if ( tbuf_enable(xc_handle, 1) != 0 )
        return -1;

    sysctl.cmd = XEN_SYSCTL_tbuf_op;
    sysctl.interface_version = XEN_SYSCTL_INTERFACE_VERSION;
    sysctl.u.tbuf_op.cmd  = XEN_SYSCTL_TBUFOP_get_info;

    rc = xc_sysctl(xc_handle, &sysctl);
    if ( rc == 0 )
    {
        *size = sysctl.u.tbuf_op.size;
        *mfn = sysctl.u.tbuf_op.buffer_mfn;
    }

    return 0;
}

int xc_tbuf_disable(int xc_handle)
{
    return tbuf_enable(xc_handle, 0);
}

int xc_tbuf_set_cpu_mask(int xc_handle, uint32_t mask)
{
    DECLARE_SYSCTL;
    int ret = -1;
    uint64_t mask64 = mask;
    uint8_t bytemap[sizeof(mask64)];

    sysctl.cmd = XEN_SYSCTL_tbuf_op;
    sysctl.interface_version = XEN_SYSCTL_INTERFACE_VERSION;
    sysctl.u.tbuf_op.cmd  = XEN_SYSCTL_TBUFOP_set_cpu_mask;

    bitmap_64_to_byte(bytemap, &mask64, sizeof (mask64) * 8);

    set_xen_guest_handle(sysctl.u.tbuf_op.cpu_mask.bitmap, bytemap);
    sysctl.u.tbuf_op.cpu_mask.nr_cpus = sizeof(bytemap) * 8;

    if ( lock_pages(&bytemap, sizeof(bytemap)) != 0 )
    {
        PERROR("Could not lock memory for Xen hypercall");
        goto out;
    }

    ret = do_sysctl(xc_handle, &sysctl);

    unlock_pages(&bytemap, sizeof(bytemap));

 out:
    return ret;
}

int xc_tbuf_set_evt_mask(int xc_handle, uint32_t mask)
{
    DECLARE_SYSCTL;

    sysctl.cmd = XEN_SYSCTL_tbuf_op;
    sysctl.interface_version = XEN_SYSCTL_INTERFACE_VERSION;
    sysctl.u.tbuf_op.cmd  = XEN_SYSCTL_TBUFOP_set_evt_mask;
    sysctl.u.tbuf_op.evt_mask = mask;

    return do_sysctl(xc_handle, &sysctl);
}


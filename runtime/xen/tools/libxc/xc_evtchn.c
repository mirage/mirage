/******************************************************************************
 * xc_evtchn.c
 *
 * API for manipulating and accessing inter-domain event channels.
 *
 * Copyright (c) 2004, K A Fraser.
 */

#include "xc_private.h"


static int do_evtchn_op(int xc_handle, int cmd, void *arg,
                        size_t arg_size, int silently_fail)
{
    int ret = -1;
    DECLARE_HYPERCALL;

    hypercall.op     = __HYPERVISOR_event_channel_op;
    hypercall.arg[0] = cmd;
    hypercall.arg[1] = (unsigned long)arg;

    if ( lock_pages(arg, arg_size) != 0 )
    {
        PERROR("do_evtchn_op: arg lock failed");
        goto out;
    }

    if ((ret = do_xen_hypercall(xc_handle, &hypercall)) < 0 && !silently_fail)
        ERROR("do_evtchn_op: HYPERVISOR_event_channel_op failed: %d", ret);

    unlock_pages(arg, arg_size);
 out:
    return ret;
}


evtchn_port_or_error_t
xc_evtchn_alloc_unbound(int xc_handle,
                        uint32_t dom,
                        uint32_t remote_dom)
{
    int rc;
    struct evtchn_alloc_unbound arg = {
        .dom = (domid_t)dom,
        .remote_dom = (domid_t)remote_dom
    };

    rc = do_evtchn_op(xc_handle, EVTCHNOP_alloc_unbound, &arg, sizeof(arg), 0);
    if ( rc == 0 )
        rc = arg.port;

    return rc;
}

int xc_evtchn_reset(int xc_handle,
                    uint32_t dom)
{
    struct evtchn_reset arg = { .dom = (domid_t)dom };
    return do_evtchn_op(xc_handle, EVTCHNOP_reset, &arg, sizeof(arg), 0);
}

int xc_evtchn_status(int xc_handle, xc_evtchn_status_t *status)
{
    return do_evtchn_op(xc_handle, EVTCHNOP_status, status,
                        sizeof(*status), 1);
}

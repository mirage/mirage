/******************************************************************************
 * xc_sedf.c
 *
 * API for manipulating parameters of the Simple EDF scheduler.
 *
 * changes by Stephan Diestelhorst
 * based on code
 * by Mark Williamson, Copyright (c) 2004 Intel Research Cambridge.
 */

#include "xc_private.h"

int xc_sedf_domain_set(
    int xc_handle,
    uint32_t domid,
    uint64_t period,
    uint64_t slice,
    uint64_t latency,
    uint16_t extratime,
    uint16_t weight)
{
    DECLARE_DOMCTL;
    struct xen_domctl_sched_sedf *p = &domctl.u.scheduler_op.u.sedf;

    domctl.cmd = XEN_DOMCTL_scheduler_op;
    domctl.domain  = (domid_t)domid;
    domctl.u.scheduler_op.sched_id = XEN_SCHEDULER_SEDF;
    domctl.u.scheduler_op.cmd = XEN_DOMCTL_SCHEDOP_putinfo;

    p->period    = period;
    p->slice     = slice;
    p->latency   = latency;
    p->extratime = extratime;
    p->weight    = weight;
    return do_domctl(xc_handle, &domctl);
}

int xc_sedf_domain_get(
    int xc_handle,
    uint32_t domid,
    uint64_t *period,
    uint64_t *slice,
    uint64_t *latency,
    uint16_t *extratime,
    uint16_t *weight)
{
    DECLARE_DOMCTL;
    int ret;
    struct xen_domctl_sched_sedf *p = &domctl.u.scheduler_op.u.sedf;

    domctl.cmd = XEN_DOMCTL_scheduler_op;
    domctl.domain = (domid_t)domid;
    domctl.u.scheduler_op.sched_id = XEN_SCHEDULER_SEDF;
    domctl.u.scheduler_op.cmd = XEN_DOMCTL_SCHEDOP_getinfo;

    ret = do_domctl(xc_handle, &domctl);

    *period    = p->period;
    *slice     = p->slice;
    *latency   = p->latency;
    *extratime = p->extratime;
    *weight    = p->weight;
    return ret;
}

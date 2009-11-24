/****************************************************************************
 * (C) 2006 - Emmanuel Ackaouy - XenSource Inc.
 ****************************************************************************
 *
 *        File: xc_csched.c
 *      Author: Emmanuel Ackaouy
 *
 * Description: XC Interface to the credit scheduler
 *
 */
#include "xc_private.h"


int
xc_sched_credit_domain_set(
    int xc_handle,
    uint32_t domid,
    struct xen_domctl_sched_credit *sdom)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_scheduler_op;
    domctl.domain = (domid_t) domid;
    domctl.u.scheduler_op.sched_id = XEN_SCHEDULER_CREDIT;
    domctl.u.scheduler_op.cmd = XEN_DOMCTL_SCHEDOP_putinfo;
    domctl.u.scheduler_op.u.credit = *sdom;

    return do_domctl(xc_handle, &domctl);
}

int
xc_sched_credit_domain_get(
    int xc_handle,
    uint32_t domid,
    struct xen_domctl_sched_credit *sdom)
{
    DECLARE_DOMCTL;
    int err;

    domctl.cmd = XEN_DOMCTL_scheduler_op;
    domctl.domain = (domid_t) domid;
    domctl.u.scheduler_op.sched_id = XEN_SCHEDULER_CREDIT;
    domctl.u.scheduler_op.cmd = XEN_DOMCTL_SCHEDOP_getinfo;

    err = do_domctl(xc_handle, &domctl);
    if ( err == 0 )
        *sdom = domctl.u.scheduler_op.u.credit;

    return err;
}

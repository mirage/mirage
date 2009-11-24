/******************************************************************************
 * hypercall.h
 */

#ifndef __XEN_HYPERCALL_H__
#define __XEN_HYPERCALL_H__

#include <xen/config.h>
#include <xen/types.h>
#include <xen/time.h>
#include <public/xen.h>
#include <public/domctl.h>
#include <public/sysctl.h>
#include <public/platform.h>
#include <public/event_channel.h>
#include <public/tmem.h>
#include <asm/hypercall.h>
#include <xsm/xsm.h>

extern long
do_ni_hypercall(
    void);

extern long
do_sched_op_compat(
    int cmd,
    unsigned long arg);

extern long
do_sched_op(
    int cmd,
    XEN_GUEST_HANDLE(void) arg);

extern long
do_domctl(
    XEN_GUEST_HANDLE(xen_domctl_t) u_domctl);

extern long
do_sysctl(
    XEN_GUEST_HANDLE(xen_sysctl_t) u_sysctl);

extern long
do_platform_op(
    XEN_GUEST_HANDLE(xen_platform_op_t) u_xenpf_op);

/*
 * To allow safe resume of do_memory_op() after preemption, we need to know
 * at what point in the page list to resume. For this purpose I steal the
 * high-order bits of the @cmd parameter, which are otherwise unused and zero.
 */
#define MEMOP_EXTENT_SHIFT 6 /* cmd[:6] == start_extent */
#define MEMOP_CMD_MASK     ((1 << MEMOP_EXTENT_SHIFT) - 1)

extern long
do_memory_op(
    unsigned long cmd,
    XEN_GUEST_HANDLE(void) arg);

extern long
do_multicall(
    XEN_GUEST_HANDLE(multicall_entry_t) call_list,
    unsigned int nr_calls);

extern long
do_set_timer_op(
    s_time_t timeout);

extern long
do_event_channel_op(
    int cmd, XEN_GUEST_HANDLE(void) arg);

extern long
do_xen_version(
    int cmd,
    XEN_GUEST_HANDLE(void) arg);

extern long
do_console_io(
    int cmd,
    int count,
    XEN_GUEST_HANDLE(char) buffer);

extern long
do_grant_table_op(
    unsigned int cmd,
    XEN_GUEST_HANDLE(void) uop,
    unsigned int count);

extern long
do_vm_assist(
    unsigned int cmd,
    unsigned int type);

extern long
do_vcpu_op(
    int cmd,
    int vcpuid,
    XEN_GUEST_HANDLE(void) arg);

extern long
do_nmi_op(
    unsigned int cmd,
    XEN_GUEST_HANDLE(void) arg);

extern long
do_hvm_op(
    unsigned long op,
    XEN_GUEST_HANDLE(void) arg);

extern long
do_kexec_op(
    unsigned long op,
    int arg1,
    XEN_GUEST_HANDLE(void) arg);

extern long
do_xsm_op(
    XEN_GUEST_HANDLE(xsm_op_t) u_xsm_op);

extern long
do_tmem_op(
    XEN_GUEST_HANDLE(tmem_op_t) uops);

extern int
do_xenoprof_op(int op, XEN_GUEST_HANDLE(void) arg);

#ifdef CONFIG_COMPAT

extern int
compat_memory_op(
    unsigned int cmd,
    XEN_GUEST_HANDLE(void) arg);

extern int
compat_grant_table_op(
    unsigned int cmd,
    XEN_GUEST_HANDLE(void) uop,
    unsigned int count);

extern int
compat_vcpu_op(
    int cmd,
    int vcpuid,
    XEN_GUEST_HANDLE(void) arg);

extern int
compat_xenoprof_op(int op, XEN_GUEST_HANDLE(void) arg);

#endif

#endif /* __XEN_HYPERCALL_H__ */

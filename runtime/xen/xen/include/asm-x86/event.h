/******************************************************************************
 * event.h
 *
 * A nice interface for passing asynchronous events to guest OSes.
 * (architecture-dependent part)
 *
 */

#ifndef __ASM_EVENT_H__
#define __ASM_EVENT_H__

#include <xen/shared.h>

void vcpu_kick(struct vcpu *v);
void vcpu_mark_events_pending(struct vcpu *v);

int hvm_local_events_need_delivery(struct vcpu *v);
static inline int local_events_need_delivery(void)
{
    struct vcpu *v = current;
    return (is_hvm_vcpu(v) ? hvm_local_events_need_delivery(v) :
            (vcpu_info(v, evtchn_upcall_pending) &&
             !vcpu_info(v, evtchn_upcall_mask)));
}

static inline int local_event_delivery_is_enabled(void)
{
    return !vcpu_info(current, evtchn_upcall_mask);
}

static inline void local_event_delivery_disable(void)
{
    vcpu_info(current, evtchn_upcall_mask) = 1;
}

static inline void local_event_delivery_enable(void)
{
    vcpu_info(current, evtchn_upcall_mask) = 0;
}

/* No arch specific virq definition now. Default to global. */
static inline int arch_virq_is_global(int virq)
{
    return 1;
}

#endif

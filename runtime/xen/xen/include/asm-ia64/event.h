/******************************************************************************
 * event.h
 *
 * A nice interface for passing asynchronous events to guest OSes.
 * (architecture-dependent part)
 *
 */

#ifndef __ASM_EVENT_H__
#define __ASM_EVENT_H__

#include <public/xen.h>
#include <asm/vcpu.h>

static inline void vcpu_kick(struct vcpu *v)
{
    /*
     * NB1. 'pause_flags' and 'processor' must be checked /after/ update of
     * pending flag. These values may fluctuate (after all, we hold no
     * locks) but the key insight is that each change will cause
     * evtchn_upcall_pending to be polled.
     * 
     * NB2. We save the running flag across the unblock to avoid a needless
     * IPI for domains that we IPI'd to unblock.
     */
    int running = v->is_running;
    vcpu_unblock(v);
    if ( running )
        smp_send_event_check_cpu(v->processor);

    if(!VMX_DOMAIN(v) && !v->arch.event_callback_ip)
        vcpu_pend_interrupt(v, v->domain->shared_info->arch.evtchn_vector);
}

static inline void vcpu_mark_events_pending(struct vcpu *v)
{
    if ( !test_and_set_bit(0, &v->vcpu_info->evtchn_upcall_pending) )
        vcpu_kick(v);
}

/* Note: Bitwise operations result in fast code with no branches. */
#define event_pending(v)                        \
    (!!(v)->vcpu_info->evtchn_upcall_pending &  \
      !(v)->vcpu_info->evtchn_upcall_mask)

static inline int local_events_need_delivery(void)
{
    return event_pending(current);
}

static inline int local_event_delivery_is_enabled(void)
{
    return !current->vcpu_info->evtchn_upcall_mask;
}

static inline void local_event_delivery_disable(void)
{
    current->vcpu_info->evtchn_upcall_mask = 1;
}

static inline void local_event_delivery_enable(void)
{
    current->vcpu_info->evtchn_upcall_mask = 0;
}

static inline int arch_virq_is_global(int virq)
{
    int rc;

    switch ( virq )
    {
    case VIRQ_ITC:
    case VIRQ_MCA_CMC:
    case VIRQ_MCA_CPE:
        rc = 0;
        break;
    default:
        rc = 1;
        break;
    }

    return rc;
}

#endif

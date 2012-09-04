/* -*-  Mode:C; c-basic-offset:4; tab-width:4 -*-
 ****************************************************************************
 * (C) 2003 - Rolf Neugebauer - Intel Research Cambridge
 * (C) 2005 - Grzegorz Milos - Intel Research Cambridge
 ****************************************************************************
 *
 *        File: events.c
 *      Author: Rolf Neugebauer (neugebar@dcs.gla.ac.uk)
 *     Changes: Grzegorz Milos (gm281@cam.ac.uk)
 *              
 *        Date: Jul 2003, changes Jun 2005
 * 
 * Environment: Xen Minimal OS
 * Description: Deals with events recieved on event channels
 *
 ****************************************************************************
 */

#include <mini-os/x86/os.h>
#include <mini-os/mm.h>
#include <mini-os/hypervisor.h>
#include <mini-os/events.h>
#include <mini-os/lib.h>

void unbind_evtchn(evtchn_port_t port)
{
    struct evtchn_close close;
    int rc;

    mask_evtchn(port);
    clear_evtchn(port);

    close.port = port;
    rc = HYPERVISOR_event_channel_op(EVTCHNOP_close, &close);
    if ( rc )
        printk("WARN: close_port %s failed rc=%d. ignored\n", port, rc);
}

char irqstack[2 * STACK_SIZE];

static struct pda
{
    int irqcount;       /* offset 0 (used in x86_64.S) */
    char *irqstackptr;  /*        8 */
} cpu0_pda;

/*
 * Initially all events are without a handler and disabled
 */
void init_events(void)
{
    asm volatile("movl %0,%%fs ; movl %0,%%gs" :: "r" (0));
    wrmsrl(0xc0000101, &cpu0_pda); /* 0xc0000101 is MSR_GS_BASE */
    cpu0_pda.irqcount = -1;
    cpu0_pda.irqstackptr = (void*) (((unsigned long)irqstack + 2 * STACK_SIZE)
                                    & ~(STACK_SIZE - 1));
}

void fini_events(void)
{
    wrmsrl(0xc0000101, NULL); /* 0xc0000101 is MSR_GS_BASE */
}

/* Create a port available to the pal for exchanging notifications.
   Returns the result of the hypervisor call. */

/* Unfortunate confusion of terminology: the port is unbound as far
   as Xen is concerned, but we automatically bind a handler to it
   from inside mini-os. */

int evtchn_alloc_unbound(domid_t pal, evtchn_port_t *port)
{
    int rc;

    evtchn_alloc_unbound_t op;
    op.dom = DOMID_SELF;
    op.remote_dom = pal;
    rc = HYPERVISOR_event_channel_op(EVTCHNOP_alloc_unbound, &op);
    if ( rc )
    {
        printk("ERROR: alloc_unbound failed with rc=%d", rc);
        return rc;
    }
    *port = op.port;
    return rc;
}

/* Connect to a port so as to allow the exchange of notifications with
   the pal. Returns the result of the hypervisor call. */

int evtchn_bind_interdomain(domid_t pal, evtchn_port_t remote_port,
                            evtchn_port_t *local_port)
{
    int rc;
    evtchn_bind_interdomain_t op;
    op.remote_dom = pal;
    op.remote_port = remote_port;
    rc = HYPERVISOR_event_channel_op(EVTCHNOP_bind_interdomain, &op);
    if ( rc )
    {
        printk("ERROR: bind_interdomain domid = %d port = %d failed: %d", pal, remote_port, rc);
                return rc;
    }
    *local_port = op.local_port;
    return rc;
}


int evtchn_bind_virq(uint32_t virq, evtchn_port_t *port)
{
    int rc;
    evtchn_bind_virq_t op;
    op.virq = virq;
    op.vcpu = 0;
    rc = HYPERVISOR_event_channel_op(EVTCHNOP_bind_virq, &op);
    if ( rc ) {
        printk("ERROR: bind_virq failed with rc=%d", rc);
        return rc;
    }
    *port = op.port;
    return rc;
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

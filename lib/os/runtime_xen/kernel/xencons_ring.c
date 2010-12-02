#include <mini-os/types.h>
#include <mini-os/wait.h>
#include <mini-os/mm.h>
#include <mini-os/hypervisor.h>
#include <mini-os/events.h>
#include <mini-os/x86/os.h>
#include <mini-os/lib.h>
#include <mini-os/xenbus.h>
#include <xen/io/console.h>
#include <xen/io/protocols.h>
#include <xen/io/ring.h>
#include <mini-os/xmalloc.h>
#include <mini-os/gnttab.h>

static inline void notify_daemon(void *dev)
{
    /* Use evtchn: this is called early, before irq is set up. */
    notify_remote_via_evtchn(start_info.console.domU.evtchn);
}

static inline struct xencons_interface *xencons_interface(void)
{
    return mfn_to_virt(start_info.console.domU.mfn);
} 
 
int xencons_ring_send_no_notify(void *dev, const char *data, unsigned int len)
{    
    int sent = 0;
    struct xencons_interface *intf;
    XENCONS_RING_IDX cons, prod;

    intf = xencons_interface();

    cons = intf->out_cons;
    prod = intf->out_prod;
    mb();
    BUG_ON((prod - cons) > sizeof(intf->out));

    while ((sent < len) && ((prod - cons) < sizeof(intf->out)))
        intf->out[MASK_XENCONS_IDX(prod++, intf->out)] = data[sent++];

    wmb();
    intf->out_prod = prod;
    
    return sent;
}

int xencons_ring_send(void *dev, const char *data, unsigned int len)
{
    int sent=0;

    for (int i=0; i<len; i++) {
        if (data[i] == '\n') {
           sent += xencons_ring_send_no_notify(dev, "\r\n", 2);
        } else 
           sent += xencons_ring_send_no_notify(dev, &data[i], 1);
    }
    notify_daemon(dev);
    return sent;
}    



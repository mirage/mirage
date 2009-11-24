#include <mini-os/types.h>
#include <mini-os/wait.h>
#include <mini-os/mm.h>
#include <mini-os/hypervisor.h>
#include <mini-os/events.h>
#include <mini-os/os.h>
#include <mini-os/lib.h>
#include <mini-os/xenbus.h>
#include <xen/io/console.h>
#include <xen/io/protocols.h>
#include <xen/io/ring.h>
#include <mini-os/xmalloc.h>
#include <mini-os/gnttab.h>

DECLARE_WAIT_QUEUE_HEAD(console_queue);

static inline void notify_daemon(struct consfront_dev *dev)
{
    /* Use evtchn: this is called early, before irq is set up. */
    if (!dev)
        notify_remote_via_evtchn(start_info.console.domU.evtchn);
    else
        notify_remote_via_evtchn(dev->evtchn);
}

static inline struct xencons_interface *xencons_interface(void)
{
    return mfn_to_virt(start_info.console.domU.mfn);
} 
 
int xencons_ring_send_no_notify(struct consfront_dev *dev, const char *data, unsigned len)
{	
    int sent = 0;
	struct xencons_interface *intf;
	XENCONS_RING_IDX cons, prod;

	if (!dev)
            intf = xencons_interface();
        else
            intf = dev->ring;

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

int xencons_ring_send(struct consfront_dev *dev, const char *data, unsigned len)
{
    int sent;

    sent = xencons_ring_send_no_notify(dev, data, len);
    notify_daemon(dev);

    return sent;
}	



static void handle_input(evtchn_port_t port, struct pt_regs *regs, void *data)
{
#ifdef HAVE_LIBC
	struct consfront_dev *dev = (struct consfront_dev *) data;
        int fd = dev ? dev->fd : -1;

        if (fd != -1)
            files[fd].read = 1;

        wake_up(&console_queue);
#else
	struct xencons_interface *intf = xencons_interface();
	XENCONS_RING_IDX cons, prod;

	cons = intf->in_cons;
	prod = intf->in_prod;
	mb();
	BUG_ON((prod - cons) > sizeof(intf->in));

	while (cons != prod) {
		xencons_rx(intf->in+MASK_XENCONS_IDX(cons,intf->in), 1, regs);
		cons++;
	}

	mb();
	intf->in_cons = cons;

	notify_daemon(dev);

	xencons_tx();
#endif
}

#ifdef HAVE_LIBC
int xencons_ring_avail(struct consfront_dev *dev)
{
	struct xencons_interface *intf;
	XENCONS_RING_IDX cons, prod;

        if (!dev)
            intf = xencons_interface();
        else
            intf = dev->ring;

	cons = intf->in_cons;
	prod = intf->in_prod;
	mb();
	BUG_ON((prod - cons) > sizeof(intf->in));

        return prod - cons;
}

int xencons_ring_recv(struct consfront_dev *dev, char *data, unsigned len)
{
	struct xencons_interface *intf;
	XENCONS_RING_IDX cons, prod;
        unsigned filled = 0;

        if (!dev)
            intf = xencons_interface();
        else
            intf = dev->ring;

	cons = intf->in_cons;
	prod = intf->in_prod;
	mb();
	BUG_ON((prod - cons) > sizeof(intf->in));

        while (filled < len && cons + filled != prod) {
                data[filled] = *(intf->in + MASK_XENCONS_IDX(cons + filled, intf->in));
                filled++;
	}

	mb();
        intf->in_cons = cons + filled;

	notify_daemon(dev);

        return filled;
}
#endif

struct consfront_dev *xencons_ring_init(void)
{
	int err;
	struct consfront_dev *dev;

	if (!start_info.console.domU.evtchn)
		return 0;

	dev = malloc(sizeof(struct consfront_dev));
	memset(dev, 0, sizeof(struct consfront_dev));
	dev->nodename = "device/console";
	dev->dom = 0;
	dev->backend = 0;
	dev->ring_ref = 0;

#ifdef HAVE_LIBC
	dev->fd = -1;
#endif
	dev->evtchn = start_info.console.domU.evtchn;
	dev->ring = (struct xencons_interface *) mfn_to_virt(start_info.console.domU.mfn);

	err = bind_evtchn(dev->evtchn, handle_input, dev);
	if (err <= 0) {
		printk("XEN console request chn bind failed %i\n", err);
                free(dev);
		return NULL;
	}
        unmask_evtchn(dev->evtchn);

	/* In case we have in-flight data after save/restore... */
	notify_daemon(dev);

	return dev;
}

void free_consfront(struct consfront_dev *dev)
{
    mask_evtchn(dev->evtchn);

    free(dev->backend);

    gnttab_end_access(dev->ring_ref);
    free_page(dev->ring);

    unbind_evtchn(dev->evtchn);

    free(dev->nodename);
    free(dev);
}

struct consfront_dev *init_consfront(char *_nodename)
{
    xenbus_transaction_t xbt;
    char* err;
    char* message=NULL;
    int retry=0;
    char* msg;
    char nodename[256];
    char path[256];
    static int consfrontends = 1;
    struct consfront_dev *dev;
    int res;

    if (!_nodename)
        snprintf(nodename, sizeof(nodename), "device/console/%d", consfrontends);
    else
        strncpy(nodename, _nodename, sizeof(nodename));

    printk("******************* CONSFRONT for %s **********\n\n\n", nodename);

    consfrontends++;
    dev = malloc(sizeof(*dev));
    memset(dev, 0, sizeof(*dev));
    dev->nodename = strdup(nodename);
#ifdef HAVE_LIBC
    dev->fd = -1;
#endif

    snprintf(path, sizeof(path), "%s/backend-id", nodename);
    if ((res = xenbus_read_integer(path)) < 0) 
        return NULL;
    else
        dev->dom = res;
    evtchn_alloc_unbound(dev->dom, handle_input, dev, &dev->evtchn);

    dev->ring = (struct xencons_interface *) alloc_page();
    memset(dev->ring, 0, PAGE_SIZE);
    dev->ring_ref = gnttab_grant_access(dev->dom, virt_to_mfn(dev->ring), 0);

    dev->events = NULL;

again:
    err = xenbus_transaction_start(&xbt);
    if (err) {
        printk("starting transaction\n");
    }

    err = xenbus_printf(xbt, nodename, "ring-ref","%u",
                dev->ring_ref);
    if (err) {
        message = "writing ring-ref";
        goto abort_transaction;
    }
    err = xenbus_printf(xbt, nodename,
                "port", "%u", dev->evtchn);
    if (err) {
        message = "writing event-channel";
        goto abort_transaction;
    }
    err = xenbus_printf(xbt, nodename,
                "protocol", "%s", XEN_IO_PROTO_ABI_NATIVE);
    if (err) {
        message = "writing protocol";
        goto abort_transaction;
    }

    err = xenbus_printf(xbt, nodename, "type", "%s", "ioemu");
    if (err) {
        message = "writing type";
        goto abort_transaction;
    }

    snprintf(path, sizeof(path), "%s/state", nodename);
    err = xenbus_switch_state(xbt, path, XenbusStateConnected);
    if (err) {
        message = "switching state";
        goto abort_transaction;
    }


    err = xenbus_transaction_end(xbt, 0, &retry);
    if (retry) {
            goto again;
        printk("completing transaction\n");
    }

    goto done;

abort_transaction:
    xenbus_transaction_end(xbt, 1, &retry);
    goto error;

done:

    snprintf(path, sizeof(path), "%s/backend", nodename);
    msg = xenbus_read(XBT_NIL, path, &dev->backend);
    if (msg) {
        printk("Error %s when reading the backend path %s\n", msg, path);
        goto error;
    }

    printk("backend at %s\n", dev->backend);

    {
        XenbusState state;
        char path[strlen(dev->backend) + 1 + 19 + 1];
        snprintf(path, sizeof(path), "%s/state", dev->backend);
        
	xenbus_watch_path_token(XBT_NIL, path, path, &dev->events);
        msg = NULL;
        state = xenbus_read_integer(path);
        while (msg == NULL && state < XenbusStateConnected)
            msg = xenbus_wait_for_state_change(path, &state, &dev->events);
        if (msg != NULL || state != XenbusStateConnected) {
            printk("backend not available, state=%d\n", state);
            xenbus_unwatch_path(XBT_NIL, path);
            goto error;
        }
    }
    unmask_evtchn(dev->evtchn);

    printk("**************************\n");

    return dev;

error:
    free_consfront(dev);
    return NULL;
}

void xencons_resume(void)
{
	(void)xencons_ring_init();
}


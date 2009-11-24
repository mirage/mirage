/*
 * Frame Buffer + Keyboard driver for Mini-OS. 
 * Samuel Thibault <samuel.thibault@eu.citrix.com>, 2008
 * Based on blkfront.c.
 */

#include <mini-os/os.h>
#include <mini-os/xenbus.h>
#include <mini-os/events.h>
#include <xen/io/kbdif.h>
#include <xen/io/fbif.h>
#include <xen/io/protocols.h>
#include <mini-os/gnttab.h>
#include <mini-os/xmalloc.h>
#include <mini-os/fbfront.h>
#include <mini-os/lib.h>

DECLARE_WAIT_QUEUE_HEAD(kbdfront_queue);






struct kbdfront_dev {
    domid_t dom;

    struct xenkbd_page *page;
    evtchn_port_t evtchn;

    char *nodename;
    char *backend;

    xenbus_event_queue events;

#ifdef HAVE_LIBC
    int fd;
#endif
};

void kbdfront_handler(evtchn_port_t port, struct pt_regs *regs, void *data)
{
#ifdef HAVE_LIBC
    struct kbdfront_dev *dev = data;
    int fd = dev->fd;

    if (fd != -1)
        files[fd].read = 1;
#endif
    wake_up(&kbdfront_queue);
}

static void free_kbdfront(struct kbdfront_dev *dev)
{
    mask_evtchn(dev->evtchn);

    free(dev->backend);

    free_page(dev->page);

    unbind_evtchn(dev->evtchn);

    free(dev->nodename);
    free(dev);
}

struct kbdfront_dev *init_kbdfront(char *_nodename, int abs_pointer)
{
    xenbus_transaction_t xbt;
    char* err;
    char* message=NULL;
    struct xenkbd_page *s;
    int retry=0;
    char* msg;
    char* nodename = _nodename ? _nodename : "device/vkbd/0";
    struct kbdfront_dev *dev;

    char path[strlen(nodename) + 1 + 10 + 1];

    printk("******************* KBDFRONT for %s **********\n\n\n", nodename);

    dev = malloc(sizeof(*dev));
    dev->nodename = strdup(nodename);
#ifdef HAVE_LIBC
    dev->fd = -1;
#endif

    snprintf(path, sizeof(path), "%s/backend-id", nodename);
    dev->dom = xenbus_read_integer(path); 
    evtchn_alloc_unbound(dev->dom, kbdfront_handler, dev, &dev->evtchn);

    dev->page = s = (struct xenkbd_page*) alloc_page();
    memset(s,0,PAGE_SIZE);

    dev->events = NULL;

    s->in_cons = s->in_prod = 0;
    s->out_cons = s->out_prod = 0;

again:
    err = xenbus_transaction_start(&xbt);
    if (err) {
        printk("starting transaction\n");
    }

    err = xenbus_printf(xbt, nodename, "page-ref","%u", virt_to_mfn(s));
    if (err) {
        message = "writing page-ref";
        goto abort_transaction;
    }
    err = xenbus_printf(xbt, nodename, "event-channel", "%u", dev->evtchn);
    if (err) {
        message = "writing event-channel";
        goto abort_transaction;
    }
    if (abs_pointer) {
        err = xenbus_printf(xbt, nodename, "request-abs-pointer", "1");
        if (err) {
            message = "writing event-channel";
            goto abort_transaction;
        }
    }

    snprintf(path, sizeof(path), "%s/state", nodename);
    err = xenbus_switch_state(xbt, path, XenbusStateInitialised);
    if (err)
        printk("error writing initialized: %s\n", err);


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
        char path[strlen(dev->backend) + 1 + 6 + 1];
        char frontpath[strlen(nodename) + 1 + 6 + 1];

        snprintf(path, sizeof(path), "%s/state", dev->backend);

        xenbus_watch_path_token(XBT_NIL, path, path, &dev->events);

        err = NULL;
        state = xenbus_read_integer(path);
        while (err == NULL && state < XenbusStateConnected)
            err = xenbus_wait_for_state_change(path, &state, &dev->events);
        if (state != XenbusStateConnected) {
            printk("backend not available, state=%d\n", state);
            xenbus_unwatch_path(XBT_NIL, path);
            goto error;
        }

        printk("%s connected\n", dev->backend);

        snprintf(frontpath, sizeof(frontpath), "%s/state", nodename);
        if((err = xenbus_switch_state(XBT_NIL, frontpath, XenbusStateConnected))
            != NULL) {
            printk("error switching state: %s\n", err);
            xenbus_unwatch_path(XBT_NIL, path);
            goto error;
        }
    }
    unmask_evtchn(dev->evtchn);

    printk("************************** KBDFRONT\n");

    return dev;
error:
    free_kbdfront(dev);
    return NULL;
}

int kbdfront_receive(struct kbdfront_dev *dev, union xenkbd_in_event *buf, int n)
{
    struct xenkbd_page *page = dev->page;
    uint32_t prod, cons;
    int i;

#ifdef HAVE_LIBC
    if (dev->fd != -1) {
        files[dev->fd].read = 0;
        mb(); /* Make sure to let the handler set read to 1 before we start looking at the ring */
    }
#endif

    prod = page->in_prod;

    if (prod == page->in_cons)
        return 0;

    rmb();      /* ensure we see ring contents up to prod */

    for (i = 0, cons = page->in_cons; i < n && cons != prod; i++, cons++)
        memcpy(buf + i, &XENKBD_IN_RING_REF(page, cons), sizeof(*buf));

    mb();       /* ensure we got ring contents */
    page->in_cons = cons;
    notify_remote_via_evtchn(dev->evtchn);

#ifdef HAVE_LIBC
    if (cons != prod && dev->fd != -1)
        /* still some events to read */
        files[dev->fd].read = 1;
#endif

    return i;
}


void shutdown_kbdfront(struct kbdfront_dev *dev)
{
    char* err = NULL;
    XenbusState state;

    char path[strlen(dev->backend) + 1 + 5 + 1];
    char nodename[strlen(dev->nodename) + 1 + 5 + 1];

    printk("close kbd: backend at %s\n",dev->backend);

    snprintf(path, sizeof(path), "%s/state", dev->backend);
    snprintf(nodename, sizeof(nodename), "%s/state", dev->nodename);
    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateClosing)) != NULL) {
        printk("shutdown_kbdfront: error changing state to %d: %s\n",
                XenbusStateClosing, err);
        goto close_kbdfront;
    }
    state = xenbus_read_integer(path);
    while (err == NULL && state < XenbusStateClosing)
        err = xenbus_wait_for_state_change(path, &state, &dev->events);

    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateClosed)) != NULL) {
        printk("shutdown_kbdfront: error changing state to %d: %s\n",
                XenbusStateClosed, err);
        goto close_kbdfront;
    }
    state = xenbus_read_integer(path);
    if (state < XenbusStateClosed)
        xenbus_wait_for_state_change(path, &state, &dev->events);

    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateInitialising)) != NULL) {
        printk("shutdown_kbdfront: error changing state to %d: %s\n",
                XenbusStateInitialising, err);
        goto close_kbdfront;
    }
    // does not work yet.
    //xenbus_wait_for_value(path, "2", &dev->events);

close_kbdfront:
    xenbus_unwatch_path(XBT_NIL, path);

    snprintf(path, sizeof(path), "%s/page-ref", nodename);
    xenbus_rm(XBT_NIL, path);
    snprintf(path, sizeof(path), "%s/event-channel", nodename);
    xenbus_rm(XBT_NIL, path);
    snprintf(path, sizeof(path), "%s/request-abs-pointer", nodename);
    xenbus_rm(XBT_NIL, path);

    free_kbdfront(dev);
}

#ifdef HAVE_LIBC
int kbdfront_open(struct kbdfront_dev *dev)
{
    dev->fd = alloc_fd(FTYPE_KBD);
    printk("kbd_open(%s) -> %d\n", dev->nodename, dev->fd);
    files[dev->fd].kbd.dev = dev;
    return dev->fd;
}
#endif





DECLARE_WAIT_QUEUE_HEAD(fbfront_queue);






struct fbfront_dev {
    domid_t dom;

    struct xenfb_page *page;
    evtchn_port_t evtchn;

    char *nodename;
    char *backend;
    int request_update;

    int width;
    int height;
    int depth;
    int stride;
    int mem_length;
    int offset;

    xenbus_event_queue events;

#ifdef HAVE_LIBC
    int fd;
#endif
};

void fbfront_handler(evtchn_port_t port, struct pt_regs *regs, void *data)
{
#ifdef HAVE_LIBC
    struct fbfront_dev *dev = data;
    int fd = dev->fd;

    if (fd != -1)
        files[fd].read = 1;
#endif
    wake_up(&fbfront_queue);
}

static void free_fbfront(struct fbfront_dev *dev)
{
    mask_evtchn(dev->evtchn);

    free(dev->backend);

    free_page(dev->page);

    unbind_evtchn(dev->evtchn);

    free(dev->nodename);
    free(dev);
}

int fbfront_receive(struct fbfront_dev *dev, union xenfb_in_event *buf, int n)
{
    struct xenfb_page *page = dev->page;
    uint32_t prod, cons;
    int i;

#ifdef HAVE_LIBC
    if (dev->fd != -1) {
        files[dev->fd].read = 0;
        mb(); /* Make sure to let the handler set read to 1 before we start looking at the ring */
    }
#endif

    prod = page->in_prod;

    if (prod == page->in_cons)
        return 0;

    rmb();      /* ensure we see ring contents up to prod */

    for (i = 0, cons = page->in_cons; i < n && cons != prod; i++, cons++)
        memcpy(buf + i, &XENFB_IN_RING_REF(page, cons), sizeof(*buf));

    mb();       /* ensure we got ring contents */
    page->in_cons = cons;
    notify_remote_via_evtchn(dev->evtchn);

#ifdef HAVE_LIBC
    if (cons != prod && dev->fd != -1)
        /* still some events to read */
        files[dev->fd].read = 1;
#endif

    return i;
}

struct fbfront_dev *init_fbfront(char *_nodename, unsigned long *mfns, int width, int height, int depth, int stride, int n)
{
    xenbus_transaction_t xbt;
    char* err;
    char* message=NULL;
    struct xenfb_page *s;
    int retry=0;
    char* msg;
    int i, j;
    struct fbfront_dev *dev;
    int max_pd;
    unsigned long mapped;
    char* nodename = _nodename ? _nodename : "device/vfb/0";

    char path[strlen(nodename) + 1 + 10 + 1];

    printk("******************* FBFRONT for %s **********\n\n\n", nodename);

    dev = malloc(sizeof(*dev));
    dev->nodename = strdup(nodename);
#ifdef HAVE_LIBC
    dev->fd = -1;
#endif

    snprintf(path, sizeof(path), "%s/backend-id", nodename);
    dev->dom = xenbus_read_integer(path); 
    evtchn_alloc_unbound(dev->dom, fbfront_handler, dev, &dev->evtchn);

    dev->page = s = (struct xenfb_page*) alloc_page();
    memset(s,0,PAGE_SIZE);

    s->in_cons = s->in_prod = 0;
    s->out_cons = s->out_prod = 0;
    dev->width = s->width = width;
    dev->height = s->height = height;
    dev->depth = s->depth = depth;
    dev->stride = s->line_length = stride;
    dev->mem_length = s->mem_length = n * PAGE_SIZE;
    dev->offset = 0;
    dev->events = NULL;

    max_pd = sizeof(s->pd) / sizeof(s->pd[0]);
    mapped = 0;

    for (i = 0; mapped < n && i < max_pd; i++) {
        unsigned long *pd = (unsigned long *) alloc_page();
        for (j = 0; mapped < n && j < PAGE_SIZE / sizeof(unsigned long); j++)
            pd[j] = mfns[mapped++];
        for ( ; j < PAGE_SIZE / sizeof(unsigned long); j++)
            pd[j] = 0;
        s->pd[i] = virt_to_mfn(pd);
    }
    for ( ; i < max_pd; i++)
        s->pd[i] = 0;


again:
    err = xenbus_transaction_start(&xbt);
    if (err) {
        printk("starting transaction\n");
    }

    err = xenbus_printf(xbt, nodename, "page-ref","%u", virt_to_mfn(s));
    if (err) {
        message = "writing page-ref";
        goto abort_transaction;
    }
    err = xenbus_printf(xbt, nodename, "event-channel", "%u", dev->evtchn);
    if (err) {
        message = "writing event-channel";
        goto abort_transaction;
    }
    err = xenbus_printf(xbt, nodename, "protocol", "%s",
                        XEN_IO_PROTO_ABI_NATIVE);
    if (err) {
        message = "writing event-channel";
        goto abort_transaction;
    }
    err = xenbus_printf(xbt, nodename, "feature-update", "1");
    if (err) {
        message = "writing event-channel";
        goto abort_transaction;
    }

    snprintf(path, sizeof(path), "%s/state", nodename);
    err = xenbus_switch_state(xbt, path, XenbusStateInitialised);
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
        char path[strlen(dev->backend) + 1 + 14 + 1];
        char frontpath[strlen(nodename) + 1 + 6 + 1];

        snprintf(path, sizeof(path), "%s/state", dev->backend);

        xenbus_watch_path_token(XBT_NIL, path, path, &dev->events);

        err = NULL;
        state = xenbus_read_integer(path);
        while (err == NULL && state < XenbusStateConnected)
            err = xenbus_wait_for_state_change(path, &state, &dev->events);
        if (state != XenbusStateConnected) {
            printk("backend not available, state=%d\n", state);
            xenbus_unwatch_path(XBT_NIL, path);
            goto error;
        }

        printk("%s connected\n", dev->backend);

        snprintf(path, sizeof(path), "%s/request-update", dev->backend);
        dev->request_update = xenbus_read_integer(path);

        snprintf(frontpath, sizeof(frontpath), "%s/state", nodename);
        if ((err = xenbus_switch_state(XBT_NIL, frontpath, XenbusStateConnected))
            != NULL) {
            printk("error switching state: %s\n", err);
            xenbus_unwatch_path(XBT_NIL, path);
            goto error;
        }
    }
    unmask_evtchn(dev->evtchn);

    printk("************************** FBFRONT\n");

    return dev;

error:
    free_fbfront(dev);
    return NULL;
}

static void fbfront_out_event(struct fbfront_dev *dev, union xenfb_out_event *event)
{
    struct xenfb_page *page = dev->page;
    uint32_t prod;
    DEFINE_WAIT(w);

    add_waiter(w, fbfront_queue);
    while (page->out_prod - page->out_cons == XENFB_OUT_RING_LEN)
        schedule();
    remove_waiter(w);

    prod = page->out_prod;
    mb(); /* ensure ring space available */
    XENFB_OUT_RING_REF(page, prod) = *event;
    wmb(); /* ensure ring contents visible */
    page->out_prod = prod + 1;
    notify_remote_via_evtchn(dev->evtchn);
}

void fbfront_update(struct fbfront_dev *dev, int x, int y, int width, int height)
{
    struct xenfb_update update;

    if (dev->request_update <= 0)
        return;

    if (x < 0) {
        width += x;
        x = 0;
    }
    if (x + width > dev->width)
        width = dev->width - x;

    if (y < 0) {
        height += y;
        y = 0;
    }
    if (y + height > dev->height)
        height = dev->height - y;

    if (width <= 0 || height <= 0)
        return;

    update.type = XENFB_TYPE_UPDATE;
    update.x = x;
    update.y = y;
    update.width = width;
    update.height = height;
    fbfront_out_event(dev, (union xenfb_out_event *) &update);
}

void fbfront_resize(struct fbfront_dev *dev, int width, int height, int stride, int depth, int offset)
{
    struct xenfb_resize resize;

    resize.type = XENFB_TYPE_RESIZE;
    dev->width  = resize.width = width;
    dev->height = resize.height = height;
    dev->stride = resize.stride = stride;
    dev->depth  = resize.depth = depth;
    dev->offset = resize.offset = offset;
    fbfront_out_event(dev, (union xenfb_out_event *) &resize);
}

void shutdown_fbfront(struct fbfront_dev *dev)
{
    char* err = NULL;
    XenbusState state;

    char path[strlen(dev->backend) + 1 + 5 + 1];
    char nodename[strlen(dev->nodename) + 1 + 5 + 1];

    printk("close fb: backend at %s\n",dev->backend);

    snprintf(path, sizeof(path), "%s/state", dev->backend);
    snprintf(nodename, sizeof(nodename), "%s/state", dev->nodename);
    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateClosing)) != NULL) {
        printk("shutdown_fbfront: error changing state to %d: %s\n",
                XenbusStateClosing, err);
        goto close_fbfront;
    }
    state = xenbus_read_integer(path);
    while (err == NULL && state < XenbusStateClosing)
        err = xenbus_wait_for_state_change(path, &state, &dev->events);

    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateClosed)) != NULL) {
        printk("shutdown_fbfront: error changing state to %d: %s\n",
                XenbusStateClosed, err);
        goto close_fbfront;
    }
    state = xenbus_read_integer(path);
    if (state < XenbusStateClosed)
        xenbus_wait_for_state_change(path, &state, &dev->events);

    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateInitialising)) != NULL) {
        printk("shutdown_fbfront: error changing state to %d: %s\n",
                XenbusStateInitialising, err);
        goto close_fbfront;
    }
    // does not work yet
    //xenbus_wait_for_value(path, "2", &dev->events);

close_fbfront:
    xenbus_unwatch_path(XBT_NIL, path);

    snprintf(path, sizeof(path), "%s/page-ref", nodename);
    xenbus_rm(XBT_NIL, path);
    snprintf(path, sizeof(path), "%s/event-channel", nodename);
    xenbus_rm(XBT_NIL, path);
    snprintf(path, sizeof(path), "%s/protocol", nodename);
    xenbus_rm(XBT_NIL, path);
    snprintf(path, sizeof(path), "%s/feature-update", nodename);
    xenbus_rm(XBT_NIL, path);

    free_fbfront(dev);
}

#ifdef HAVE_LIBC
int fbfront_open(struct fbfront_dev *dev)
{
    dev->fd = alloc_fd(FTYPE_FB);
    printk("fb_open(%s) -> %d\n", dev->nodename, dev->fd);
    files[dev->fd].fb.dev = dev;
    return dev->fd;
}
#endif


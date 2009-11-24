/* Minimal PCI driver for Mini-OS. 
 * Copyright (c) 2007-2008 Samuel Thibault.
 * Based on blkfront.c.
 */

#include <string.h>
#include <mini-os/os.h>
#include <mini-os/lib.h>
#include <mini-os/xenbus.h>
#include <mini-os/events.h>
#include <errno.h>
#include <mini-os/gnttab.h>
#include <mini-os/xmalloc.h>
#include <mini-os/wait.h>
#include <mini-os/pcifront.h>
#include <mini-os/sched.h>

#define PCI_DEVFN(slot, func) ((((slot) & 0x1f) << 3) | ((func) & 0x07))

DECLARE_WAIT_QUEUE_HEAD(pcifront_queue);
static struct pcifront_dev *pcidev;

struct pcifront_dev {
    domid_t dom;

    struct xen_pci_sharedinfo *info;
    grant_ref_t info_ref;
    evtchn_port_t evtchn;

    char *nodename;
    char *backend;

    xenbus_event_queue events;
};

void pcifront_handler(evtchn_port_t port, struct pt_regs *regs, void *data)
{
    wake_up(&pcifront_queue);
}

static void free_pcifront(struct pcifront_dev *dev)
{
    if (!dev)
        dev = pcidev;

    mask_evtchn(dev->evtchn);

    gnttab_end_access(dev->info_ref);
    free_page(dev->info);

    unbind_evtchn(dev->evtchn);

    free(dev->backend);
    free(dev->nodename);
    free(dev);
}

void pcifront_watches(void *opaque)
{
    XenbusState state;
    char *err = NULL, *msg = NULL;
    char *be_path, *be_state;
    char* nodename = opaque ? opaque : "device/pci/0";
    char path[strlen(nodename) + 9];
    char fe_state[strlen(nodename) + 7];
    xenbus_event_queue events = NULL;

    snprintf(path, sizeof(path), "%s/backend", nodename);
    snprintf(fe_state, sizeof(fe_state), "%s/state", nodename);

    while (1) {
        printk("pcifront_watches: waiting for backend path to happear %s\n", path);
        xenbus_watch_path_token(XBT_NIL, path, path, &events);
        while ((err = xenbus_read(XBT_NIL, path, &be_path)) != NULL) {
            free(err);
            xenbus_wait_for_watch(&events);
        }
        xenbus_unwatch_path_token(XBT_NIL, path, path);
        printk("pcifront_watches: waiting for backend to get into the right state %s\n", be_path);
        be_state = (char *) malloc(strlen(be_path) +  7);
        snprintf(be_state, strlen(be_path) +  7, "%s/state", be_path);
        xenbus_watch_path_token(XBT_NIL, be_state, be_state, &events);
        while ((err = xenbus_read(XBT_NIL, be_state, &msg)) != NULL || msg[0] > '4') {
            free(msg);
            free(err);
            xenbus_wait_for_watch(&events);
        }
        xenbus_unwatch_path_token(XBT_NIL, be_state, be_state);
        if (init_pcifront(NULL) == NULL) {
            free(be_state);
            free(be_path);
            continue;
        }
        xenbus_watch_path_token(XBT_NIL, be_state, be_state, &events);
        state = XenbusStateConnected;
        printk("pcifront_watches: waiting for backend events %s\n", be_state);
        while ((err = xenbus_wait_for_state_change(be_state, &state, &events)) == NULL &&
               (err = xenbus_read(XBT_NIL, pcidev->backend, &msg)) == NULL) {
            free(msg);
            printk("pcifront_watches: backend state changed: %s %d\n", be_state, state);
            if (state == XenbusStateReconfiguring) {
                printk("pcifront_watches: writing %s %d\n", fe_state, XenbusStateReconfiguring);
                if ((err = xenbus_switch_state(XBT_NIL, fe_state, XenbusStateReconfiguring)) != NULL) {
                    printk("pcifront_watches: error changing state to %d: %s\n",
                            XenbusStateReconfiguring, err);
                    if (!strcmp(err, "ENOENT")) {
                        xenbus_write(XBT_NIL, fe_state, "7");
                        free(err);
                    }
                }
            } else if (state == XenbusStateReconfigured) {
                printk("pcifront_watches: writing %s %d\n", fe_state, XenbusStateConnected);
                printk("pcifront_watches: changing state to %d\n", XenbusStateConnected);
                if ((err = xenbus_switch_state(XBT_NIL, fe_state, XenbusStateConnected)) != NULL) {
                    printk("pcifront_watches: error changing state to %d: %s\n",
                            XenbusStateConnected, err);
                    if (!strcmp(err, "ENOENT")) {
                        xenbus_write(XBT_NIL, fe_state, "4");
                        free(err);
                    }
                }
            } else if (state == XenbusStateClosing)
                break;
        }
        if (err)
            printk("pcifront_watches: done waiting err=%s\n", err);
        else
            printk("pcifront_watches: done waiting\n");
        xenbus_unwatch_path_token(XBT_NIL, be_state, be_state);
        shutdown_pcifront(pcidev);
        free(be_state);
        free(be_path);
        free(err);
        pcidev = NULL;
    }

    xenbus_unwatch_path_token(XBT_NIL, path, path);
}

struct pcifront_dev *init_pcifront(char *_nodename)
{
    xenbus_transaction_t xbt;
    char* err;
    char* message=NULL;
    int retry=0;
    char* msg;
    char* nodename = _nodename ? _nodename : "device/pci/0";
    int dom;

    struct pcifront_dev *dev;

    char path[strlen(nodename) + 1 + 10 + 1];

    if (!_nodename && pcidev)
        return pcidev;

    printk("******************* PCIFRONT for %s **********\n\n\n", nodename);

    snprintf(path, sizeof(path), "%s/backend-id", nodename);
    dom = xenbus_read_integer(path); 
    if (dom == -1) {
        printk("no backend\n");
        return NULL;
    }

    dev = malloc(sizeof(*dev));
    memset(dev, 0, sizeof(*dev));
    dev->nodename = strdup(nodename);
    dev->dom = dom;

    evtchn_alloc_unbound(dev->dom, pcifront_handler, dev, &dev->evtchn);

    dev->info = (struct xen_pci_sharedinfo*) alloc_page();
    memset(dev->info,0,PAGE_SIZE);

    dev->info_ref = gnttab_grant_access(dev->dom,virt_to_mfn(dev->info),0);

    dev->events = NULL;

again:
    err = xenbus_transaction_start(&xbt);
    if (err) {
        printk("starting transaction\n");
    }

    err = xenbus_printf(xbt, nodename, "pci-op-ref","%u",
                dev->info_ref);
    if (err) {
        message = "writing pci-op-ref";
        goto abort_transaction;
    }
    err = xenbus_printf(xbt, nodename,
                "event-channel", "%u", dev->evtchn);
    if (err) {
        message = "writing event-channel";
        goto abort_transaction;
    }
    err = xenbus_printf(xbt, nodename,
                "magic", XEN_PCI_MAGIC);
    if (err) {
        message = "writing magic";
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
        char path[strlen(dev->backend) + 1 + 5 + 1];
        char frontpath[strlen(nodename) + 1 + 5 + 1];
        XenbusState state;
        snprintf(path, sizeof(path), "%s/state", dev->backend);

        xenbus_watch_path_token(XBT_NIL, path, path, &dev->events);

        err = NULL;
        state = xenbus_read_integer(path);
        while (err == NULL && state < XenbusStateConnected)
            err = xenbus_wait_for_state_change(path, &state, &dev->events);
        if (state != XenbusStateConnected) {
            printk("backend not avalable, state=%d\n", state);
            xenbus_unwatch_path(XBT_NIL, path);
            goto error;
        }

        snprintf(frontpath, sizeof(frontpath), "%s/state", nodename);
        if ((err = xenbus_switch_state(XBT_NIL, frontpath, XenbusStateConnected))
            != NULL) {
            printk("error switching state %s\n", err);
            xenbus_unwatch_path(XBT_NIL, path);
            goto error;
        }
    }
    unmask_evtchn(dev->evtchn);

    printk("**************************\n");

    if (!_nodename)
        pcidev = dev;

    return dev;

error:
    free_pcifront(dev);
    return NULL;
}

void pcifront_scan(struct pcifront_dev *dev, void (*func)(unsigned int domain, unsigned int bus, unsigned slot, unsigned int fun))
{
    char *path;
    int i, n, len;
    char *s, *msg;
    unsigned int domain, bus, slot, fun;

    if (!dev)
        dev = pcidev;
    if (!dev)
        dev = init_pcifront(NULL);
    if (!dev)
        return;

    len = strlen(dev->backend) + 1 + 5 + 10 + 1;
    path = (char *) malloc(len);
    snprintf(path, len, "%s/num_devs", dev->backend);
    n = xenbus_read_integer(path);

    for (i = 0; i < n; i++) {
        snprintf(path, len, "%s/dev-%d", dev->backend, i);
        msg = xenbus_read(XBT_NIL, path, &s);
        if (msg) {
            printk("Error %s when reading the PCI root name at %s\n", msg, path);
            continue;
        }

        if (sscanf(s, "%x:%x:%x.%x", &domain, &bus, &slot, &fun) != 4) {
            printk("\"%s\" does not look like a PCI device address\n", s);
            free(s);
            continue;
        }
        free(s);

        if (func)
            func(domain, bus, slot, fun);
    }
    free(path);
}

void shutdown_pcifront(struct pcifront_dev *dev)
{
    char* err = NULL;
    XenbusState state;

    char path[strlen(dev->backend) + 1 + 5 + 1];
    char nodename[strlen(dev->nodename) + 1 + 5 + 1];

    printk("close pci: backend at %s\n",dev->backend);

    snprintf(path, sizeof(path), "%s/state", dev->backend);
    snprintf(nodename, sizeof(nodename), "%s/state", dev->nodename);
    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateClosing)) != NULL) {
        printk("shutdown_pcifront: error changing state to %d: %s\n",
                XenbusStateClosing, err);
        goto close_pcifront;
    }
    state = xenbus_read_integer(path);
    while (err == NULL && state < XenbusStateClosing)
        err = xenbus_wait_for_state_change(path, &state, &dev->events);

    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateClosed)) != NULL) {
        printk("shutdown_pcifront: error changing state to %d: %s\n",
                XenbusStateClosed, err);
        goto close_pcifront;
    }
    state = xenbus_read_integer(path);
    if (state < XenbusStateClosed)
        xenbus_wait_for_state_change(path, &state, &dev->events);

    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateInitialising)) != NULL) {
        printk("shutdown_pcifront: error changing state to %d: %s\n",
                XenbusStateInitialising, err);
        goto close_pcifront;
    }
    err = NULL;
    state = xenbus_read_integer(path);
    while (err == NULL && (state < XenbusStateInitWait || state >= XenbusStateClosed))
        err = xenbus_wait_for_state_change(path, &state, &dev->events);

close_pcifront:
    xenbus_unwatch_path(XBT_NIL, path);

    snprintf(path, sizeof(path), "%s/info-ref", nodename);
    xenbus_rm(XBT_NIL, path);
    snprintf(path, sizeof(path), "%s/event-channel", nodename);
    xenbus_rm(XBT_NIL, path);

    free_pcifront(dev);
}

int pcifront_physical_to_virtual (struct pcifront_dev *dev,
                                  unsigned int *dom,
                                  unsigned int *bus,
                                  unsigned int *slot,
                                  unsigned long *fun)
{
    char path[strlen(dev->backend) + 1 + 5 + 10 + 1];
    int i, n;
    char *s, *msg = NULL;
    unsigned int dom1, bus1, slot1, fun1;

    if (!dev)
        dev = pcidev;

    snprintf(path, sizeof(path), "%s/num_devs", dev->backend);
    n = xenbus_read_integer(path);

    for (i = 0; i < n; i++) {
        snprintf(path, sizeof(path), "%s/dev-%d", dev->backend, i);
        msg = xenbus_read(XBT_NIL, path, &s);
        if (msg) {
            printk("Error %s when reading the PCI root name at %s\n", msg, path);
            continue;
        }

        if (sscanf(s, "%x:%x:%x.%x", &dom1, &bus1, &slot1, &fun1) != 4) {
            printk("\"%s\" does not look like a PCI device address\n", s);
            free(s);
            continue;
        }
        free(s);

        if (dom1 == *dom && bus1 == *bus && slot1 == *slot && fun1 == *fun) {
            snprintf(path, sizeof(path), "%s/vdev-%d", dev->backend, i);
            msg = xenbus_read(XBT_NIL, path, &s);
            if (msg) {
                printk("Error %s when reading the PCI root name at %s\n", msg, path);
                continue;
            }

            if (sscanf(s, "%x:%x:%x.%x", dom, bus, slot, fun) != 4) {
                printk("\"%s\" does not look like a PCI device address\n", s);
                free(s);
                continue;
            }
            free(s);

            return 0;
        }
    }
    return -1;
}

void pcifront_op(struct pcifront_dev *dev, struct xen_pci_op *op)
{
    if (!dev)
        dev = pcidev;
    dev->info->op = *op;
    /* Make sure info is written before the flag */
    wmb();
    set_bit(_XEN_PCIF_active, (void*) &dev->info->flags);
    notify_remote_via_evtchn(dev->evtchn);

    wait_event(pcifront_queue, !test_bit(_XEN_PCIF_active, (void*) &dev->info->flags));

    /* Make sure flag is read before info */
    rmb();
    *op = dev->info->op;
}

int pcifront_conf_read(struct pcifront_dev *dev,
                       unsigned int dom,
                       unsigned int bus, unsigned int slot, unsigned long fun,
                       unsigned int off, unsigned int size, unsigned int *val)
{
    struct xen_pci_op op;

    if (!dev)
        dev = pcidev;
    if (pcifront_physical_to_virtual(dev, &dom, &bus, &slot, &fun) < 0)
        return XEN_PCI_ERR_dev_not_found;
    memset(&op, 0, sizeof(op));

    op.cmd = XEN_PCI_OP_conf_read;
    op.domain = dom;
    op.bus = bus;
    op.devfn = PCI_DEVFN(slot, fun);
    op.offset = off;
    op.size = size;

    pcifront_op(dev, &op);

    if (op.err)
        return op.err;

    *val = op.value;

    return 0;
}

int pcifront_conf_write(struct pcifront_dev *dev,
                        unsigned int dom,
                        unsigned int bus, unsigned int slot, unsigned long fun,
                        unsigned int off, unsigned int size, unsigned int val)
{
    struct xen_pci_op op;

    if (!dev)
        dev = pcidev;
    if (pcifront_physical_to_virtual(dev, &dom, &bus, &slot, &fun) < 0)
        return XEN_PCI_ERR_dev_not_found;
    memset(&op, 0, sizeof(op));

    op.cmd = XEN_PCI_OP_conf_write;
    op.domain = dom;
    op.bus = bus;
    op.devfn = PCI_DEVFN(slot, fun);
    op.offset = off;
    op.size = size;

    op.value = val;

    pcifront_op(dev, &op);

    return op.err;
}

int pcifront_enable_msi(struct pcifront_dev *dev,
                        unsigned int dom,
                        unsigned int bus, unsigned int slot, unsigned long fun)
{
    struct xen_pci_op op;

    if (!dev)
        dev = pcidev;
    if (pcifront_physical_to_virtual(dev, &dom, &bus, &slot, &fun) < 0)
        return XEN_PCI_ERR_dev_not_found;
    memset(&op, 0, sizeof(op));

    op.cmd = XEN_PCI_OP_enable_msi;
    op.domain = dom;
    op.bus = bus;
    op.devfn = PCI_DEVFN(slot, fun);

    pcifront_op(dev, &op);
    
    if (op.err)
        return op.err;
    else
        return op.value;
}

int pcifront_disable_msi(struct pcifront_dev *dev,
                         unsigned int dom,
                         unsigned int bus, unsigned int slot, unsigned long fun)
{
    struct xen_pci_op op;

    if (!dev)
        dev = pcidev;
    if (pcifront_physical_to_virtual(dev, &dom, &bus, &slot, &fun) < 0)
        return XEN_PCI_ERR_dev_not_found;
    memset(&op, 0, sizeof(op));

    op.cmd = XEN_PCI_OP_disable_msi;
    op.domain = dom;
    op.bus = bus;
    op.devfn = PCI_DEVFN(slot, fun);

    pcifront_op(dev, &op);
    
    return op.err;
}

int pcifront_enable_msix(struct pcifront_dev *dev,
                         unsigned int dom,
                         unsigned int bus, unsigned int slot, unsigned long fun,
                         struct xen_msix_entry *entries, int n)
{
    struct xen_pci_op op;

    if (!dev)
        dev = pcidev;
    if (pcifront_physical_to_virtual(dev, &dom, &bus, &slot, &fun) < 0)
        return XEN_PCI_ERR_dev_not_found;
    if (n > SH_INFO_MAX_VEC)
        return XEN_PCI_ERR_op_failed;

    memset(&op, 0, sizeof(op));

    op.cmd = XEN_PCI_OP_enable_msix;
    op.domain = dom;
    op.bus = bus;
    op.devfn = PCI_DEVFN(slot, fun);
    op.value = n;

    memcpy(op.msix_entries, entries, n * sizeof(*entries));

    pcifront_op(dev, &op);
    
    if (op.err)
        return op.err;

    memcpy(entries, op.msix_entries, n * sizeof(*entries));

    return 0;
}


int pcifront_disable_msix(struct pcifront_dev *dev,
                          unsigned int dom,
                          unsigned int bus, unsigned int slot, unsigned long fun)
{
    struct xen_pci_op op;

    if (!dev)
        dev = pcidev;
    if (pcifront_physical_to_virtual(dev, &dom, &bus, &slot, &fun) < 0)
        return XEN_PCI_ERR_dev_not_found;
    memset(&op, 0, sizeof(op));

    op.cmd = XEN_PCI_OP_disable_msix;
    op.domain = dom;
    op.bus = bus;
    op.devfn = PCI_DEVFN(slot, fun);

    pcifront_op(dev, &op);
    
    return op.err;
}

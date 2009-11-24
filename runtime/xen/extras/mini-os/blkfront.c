/* Minimal block driver for Mini-OS. 
 * Copyright (c) 2007-2008 Samuel Thibault.
 * Based on netfront.c.
 */

#include <stdint.h>
#include <mini-os/os.h>
#include <mini-os/xenbus.h>
#include <mini-os/events.h>
#include <errno.h>
#include <xen/io/blkif.h>
#include <xen/io/protocols.h>
#include <mini-os/gnttab.h>
#include <mini-os/xmalloc.h>
#include <time.h>
#include <mini-os/blkfront.h>
#include <mini-os/lib.h>
#include <fcntl.h>

#ifndef HAVE_LIBC
#define strtoul simple_strtoul
#endif

/* Note: we generally don't need to disable IRQs since we hardly do anything in
 * the interrupt handler.  */

/* Note: we really suppose non-preemptive threads.  */

DECLARE_WAIT_QUEUE_HEAD(blkfront_queue);




#define BLK_RING_SIZE __RING_SIZE((struct blkif_sring *)0, PAGE_SIZE)
#define GRANT_INVALID_REF 0


struct blk_buffer {
    void* page;
    grant_ref_t gref;
};

struct blkfront_dev {
    domid_t dom;

    struct blkif_front_ring ring;
    grant_ref_t ring_ref;
    evtchn_port_t evtchn;
    blkif_vdev_t handle;

    char *nodename;
    char *backend;
    struct blkfront_info info;

    xenbus_event_queue events;

#ifdef HAVE_LIBC
    int fd;
#endif
};

void blkfront_handler(evtchn_port_t port, struct pt_regs *regs, void *data)
{
#ifdef HAVE_LIBC
    struct blkfront_dev *dev = data;
    int fd = dev->fd;

    if (fd != -1)
        files[fd].read = 1;
#endif
    wake_up(&blkfront_queue);
}

static void free_blkfront(struct blkfront_dev *dev)
{
    mask_evtchn(dev->evtchn);

    free(dev->backend);

    gnttab_end_access(dev->ring_ref);
    free_page(dev->ring.sring);

    unbind_evtchn(dev->evtchn);

    free(dev->nodename);
    free(dev);
}

struct blkfront_dev *init_blkfront(char *_nodename, struct blkfront_info *info)
{
    xenbus_transaction_t xbt;
    char* err;
    char* message=NULL;
    struct blkif_sring *s;
    int retry=0;
    char* msg;
    char* c;
    char* nodename = _nodename ? _nodename : "device/vbd/768";

    struct blkfront_dev *dev;

    char path[strlen(nodename) + 1 + 10 + 1];

    printk("******************* BLKFRONT for %s **********\n\n\n", nodename);

    dev = malloc(sizeof(*dev));
    memset(dev, 0, sizeof(*dev));
    dev->nodename = strdup(nodename);
#ifdef HAVE_LIBC
    dev->fd = -1;
#endif

    snprintf(path, sizeof(path), "%s/backend-id", nodename);
    dev->dom = xenbus_read_integer(path); 
    evtchn_alloc_unbound(dev->dom, blkfront_handler, dev, &dev->evtchn);

    s = (struct blkif_sring*) alloc_page();
    memset(s,0,PAGE_SIZE);


    SHARED_RING_INIT(s);
    FRONT_RING_INIT(&dev->ring, s, PAGE_SIZE);

    dev->ring_ref = gnttab_grant_access(dev->dom,virt_to_mfn(s),0);

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
                "event-channel", "%u", dev->evtchn);
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

    dev->handle = strtoul(strrchr(nodename, '/')+1, NULL, 0);

    {
        XenbusState state;
        char path[strlen(dev->backend) + 1 + 19 + 1];
        snprintf(path, sizeof(path), "%s/mode", dev->backend);
        msg = xenbus_read(XBT_NIL, path, &c);
        if (msg) {
            printk("Error %s when reading the mode\n", msg);
            goto error;
        }
        if (*c == 'w')
            dev->info.mode = O_RDWR;
        else
            dev->info.mode = O_RDONLY;
        free(c);

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

        snprintf(path, sizeof(path), "%s/info", dev->backend);
        dev->info.info = xenbus_read_integer(path);

        snprintf(path, sizeof(path), "%s/sectors", dev->backend);
        // FIXME: read_integer returns an int, so disk size limited to 1TB for now
        dev->info.sectors = xenbus_read_integer(path);

        snprintf(path, sizeof(path), "%s/sector-size", dev->backend);
        dev->info.sector_size = xenbus_read_integer(path);

        snprintf(path, sizeof(path), "%s/feature-barrier", dev->backend);
        dev->info.barrier = xenbus_read_integer(path);

        snprintf(path, sizeof(path), "%s/feature-flush-cache", dev->backend);
        dev->info.flush = xenbus_read_integer(path);

        *info = dev->info;
    }
    unmask_evtchn(dev->evtchn);

    printk("%u sectors of %u bytes\n", dev->info.sectors, dev->info.sector_size);
    printk("**************************\n");

    return dev;

error:
    free_blkfront(dev);
    return NULL;
}

void shutdown_blkfront(struct blkfront_dev *dev)
{
    char* err = NULL;
    XenbusState state;

    char path[strlen(dev->backend) + 1 + 5 + 1];
    char nodename[strlen(dev->nodename) + 1 + 5 + 1];

    blkfront_sync(dev);

    printk("close blk: backend=%s node=%s\n", dev->backend, dev->nodename);

    snprintf(path, sizeof(path), "%s/state", dev->backend);
    snprintf(nodename, sizeof(nodename), "%s/state", dev->nodename);

    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateClosing)) != NULL) {
        printk("shutdown_blkfront: error changing state to %d: %s\n",
                XenbusStateClosing, err);
        goto close;
    }
    state = xenbus_read_integer(path);
    while (err == NULL && state < XenbusStateClosing)
        err = xenbus_wait_for_state_change(path, &state, &dev->events);

    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateClosed)) != NULL) {
        printk("shutdown_blkfront: error changing state to %d: %s\n",
                XenbusStateClosed, err);
        goto close;
    }
    state = xenbus_read_integer(path);
    if (state < XenbusStateClosed)
        xenbus_wait_for_state_change(path, &state, &dev->events);

    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateInitialising)) != NULL) {
        printk("shutdown_blkfront: error changing state to %d: %s\n",
                XenbusStateInitialising, err);
        goto close;
    }
    err = NULL;
    state = xenbus_read_integer(path);
    while (err == NULL && (state < XenbusStateInitWait || state >= XenbusStateClosed))
        err = xenbus_wait_for_state_change(path, &state, &dev->events);

close:
    xenbus_unwatch_path(XBT_NIL, path);

    snprintf(path, sizeof(path), "%s/ring-ref", nodename);
    xenbus_rm(XBT_NIL, path);
    snprintf(path, sizeof(path), "%s/event-channel", nodename);
    xenbus_rm(XBT_NIL, path);

    free_blkfront(dev);
}

static void blkfront_wait_slot(struct blkfront_dev *dev)
{
    /* Wait for a slot */
    if (RING_FULL(&dev->ring)) {
	unsigned long flags;
	DEFINE_WAIT(w);
	local_irq_save(flags);
	while (1) {
	    blkfront_aio_poll(dev);
	    if (!RING_FULL(&dev->ring))
		break;
	    /* Really no slot, go to sleep. */
	    add_waiter(w, blkfront_queue);
	    local_irq_restore(flags);
	    schedule();
	    local_irq_save(flags);
	}
	remove_waiter(w);
	local_irq_restore(flags);
    }
}

/* Issue an aio */
void blkfront_aio(struct blkfront_aiocb *aiocbp, int write)
{
    struct blkfront_dev *dev = aiocbp->aio_dev;
    struct blkif_request *req;
    RING_IDX i;
    int notify;
    int n, j;
    uintptr_t start, end;

    // Can't io at non-sector-aligned location
    ASSERT(!(aiocbp->aio_offset & (dev->info.sector_size-1)));
    // Can't io non-sector-sized amounts
    ASSERT(!(aiocbp->aio_nbytes & (dev->info.sector_size-1)));
    // Can't io non-sector-aligned buffer
    ASSERT(!((uintptr_t) aiocbp->aio_buf & (dev->info.sector_size-1)));

    start = (uintptr_t)aiocbp->aio_buf & PAGE_MASK;
    end = ((uintptr_t)aiocbp->aio_buf + aiocbp->aio_nbytes + PAGE_SIZE - 1) & PAGE_MASK;
    aiocbp->n = n = (end - start) / PAGE_SIZE;

    /* qemu's IDE max multsect is 16 (8KB) and SCSI max DMA was set to 32KB,
     * so max 44KB can't happen */
    ASSERT(n <= BLKIF_MAX_SEGMENTS_PER_REQUEST);

    blkfront_wait_slot(dev);
    i = dev->ring.req_prod_pvt;
    req = RING_GET_REQUEST(&dev->ring, i);

    req->operation = write ? BLKIF_OP_WRITE : BLKIF_OP_READ;
    req->nr_segments = n;
    req->handle = dev->handle;
    req->id = (uintptr_t) aiocbp;
    req->sector_number = aiocbp->aio_offset / 512;

    for (j = 0; j < n; j++) {
        req->seg[j].first_sect = 0;
        req->seg[j].last_sect = PAGE_SIZE / 512 - 1;
    }
    req->seg[0].first_sect = ((uintptr_t)aiocbp->aio_buf & ~PAGE_MASK) / 512;
    req->seg[n-1].last_sect = (((uintptr_t)aiocbp->aio_buf + aiocbp->aio_nbytes - 1) & ~PAGE_MASK) / 512;
    for (j = 0; j < n; j++) {
	uintptr_t data = start + j * PAGE_SIZE;
        if (!write) {
            /* Trigger CoW if needed */
            *(char*)(data + (req->seg[j].first_sect << 9)) = 0;
            barrier();
        }
	aiocbp->gref[j] = req->seg[j].gref =
            gnttab_grant_access(dev->dom, virtual_to_mfn(data), write);
    }

    dev->ring.req_prod_pvt = i + 1;

    wmb();
    RING_PUSH_REQUESTS_AND_CHECK_NOTIFY(&dev->ring, notify);

    if(notify) notify_remote_via_evtchn(dev->evtchn);
}

static void blkfront_aio_cb(struct blkfront_aiocb *aiocbp, int ret)
{
    aiocbp->data = (void*) 1;
}

void blkfront_io(struct blkfront_aiocb *aiocbp, int write)
{
    unsigned long flags;
    DEFINE_WAIT(w);

    ASSERT(!aiocbp->aio_cb);
    aiocbp->aio_cb = blkfront_aio_cb;
    blkfront_aio(aiocbp, write);
    aiocbp->data = NULL;

    local_irq_save(flags);
    while (1) {
	blkfront_aio_poll(aiocbp->aio_dev);
	if (aiocbp->data)
	    break;

	add_waiter(w, blkfront_queue);
	local_irq_restore(flags);
	schedule();
	local_irq_save(flags);
    }
    remove_waiter(w);
    local_irq_restore(flags);
}

static void blkfront_push_operation(struct blkfront_dev *dev, uint8_t op, uint64_t id)
{
    int i;
    struct blkif_request *req;
    int notify;

    blkfront_wait_slot(dev);
    i = dev->ring.req_prod_pvt;
    req = RING_GET_REQUEST(&dev->ring, i);
    req->operation = op;
    req->nr_segments = 0;
    req->handle = dev->handle;
    req->id = id;
    /* Not needed anyway, but the backend will check it */
    req->sector_number = 0;
    dev->ring.req_prod_pvt = i + 1;
    wmb();
    RING_PUSH_REQUESTS_AND_CHECK_NOTIFY(&dev->ring, notify);
    if (notify) notify_remote_via_evtchn(dev->evtchn);
}

void blkfront_aio_push_operation(struct blkfront_aiocb *aiocbp, uint8_t op)
{
    struct blkfront_dev *dev = aiocbp->aio_dev;
    blkfront_push_operation(dev, op, (uintptr_t) aiocbp);
}

void blkfront_sync(struct blkfront_dev *dev)
{
    unsigned long flags;
    DEFINE_WAIT(w);

    if (dev->info.mode == O_RDWR) {
        if (dev->info.barrier == 1)
            blkfront_push_operation(dev, BLKIF_OP_WRITE_BARRIER, 0);

        if (dev->info.flush == 1)
            blkfront_push_operation(dev, BLKIF_OP_FLUSH_DISKCACHE, 0);
    }

    /* Note: This won't finish if another thread enqueues requests.  */
    local_irq_save(flags);
    while (1) {
	blkfront_aio_poll(dev);
	if (RING_FREE_REQUESTS(&dev->ring) == RING_SIZE(&dev->ring))
	    break;

	add_waiter(w, blkfront_queue);
	local_irq_restore(flags);
	schedule();
	local_irq_save(flags);
    }
    remove_waiter(w);
    local_irq_restore(flags);
}

int blkfront_aio_poll(struct blkfront_dev *dev)
{
    RING_IDX rp, cons;
    struct blkif_response *rsp;
    int more;
    int nr_consumed;

moretodo:
#ifdef HAVE_LIBC
    if (dev->fd != -1) {
        files[dev->fd].read = 0;
        mb(); /* Make sure to let the handler set read to 1 before we start looking at the ring */
    }
#endif

    rp = dev->ring.sring->rsp_prod;
    rmb(); /* Ensure we see queued responses up to 'rp'. */
    cons = dev->ring.rsp_cons;

    nr_consumed = 0;
    while ((cons != rp))
    {
        struct blkfront_aiocb *aiocbp;
        int status;

	rsp = RING_GET_RESPONSE(&dev->ring, cons);
	nr_consumed++;

        aiocbp = (void*) (uintptr_t) rsp->id;
        status = rsp->status;

        if (status != BLKIF_RSP_OKAY)
            printk("block error %d for op %d\n", status, rsp->operation);

        switch (rsp->operation) {
        case BLKIF_OP_READ:
        case BLKIF_OP_WRITE:
        {
            int j;

            for (j = 0; j < aiocbp->n; j++)
                gnttab_end_access(aiocbp->gref[j]);

            break;
        }

        case BLKIF_OP_WRITE_BARRIER:
        case BLKIF_OP_FLUSH_DISKCACHE:
            break;

        default:
            printk("unrecognized block operation %d response\n", rsp->operation);
        }

        dev->ring.rsp_cons = ++cons;
        /* Nota: callback frees aiocbp itself */
        if (aiocbp && aiocbp->aio_cb)
            aiocbp->aio_cb(aiocbp, status ? -EIO : 0);
        if (dev->ring.rsp_cons != cons)
            /* We reentered, we must not continue here */
            break;
    }

    RING_FINAL_CHECK_FOR_RESPONSES(&dev->ring, more);
    if (more) goto moretodo;

    return nr_consumed;
}

#ifdef HAVE_LIBC
int blkfront_open(struct blkfront_dev *dev)
{
    dev->fd = alloc_fd(FTYPE_BLK);
    printk("blk_open(%s) -> %d\n", dev->nodename, dev->fd);
    files[dev->fd].blk.dev = dev;
    return dev->fd;
}
#endif

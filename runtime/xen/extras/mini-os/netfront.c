/* Minimal network driver for Mini-OS. 
 * Copyright (c) 2006-2007 Jacob Gorm Hansen, University of Copenhagen.
 * Based on netfront.c from Xen Linux.
 *
 * Does not handle fragments or extras.
 */

#include <mini-os/os.h>
#include <mini-os/xenbus.h>
#include <mini-os/events.h>
#include <errno.h>
#include <xen/io/netif.h>
#include <mini-os/gnttab.h>
#include <mini-os/xmalloc.h>
#include <mini-os/time.h>
#include <mini-os/netfront.h>
#include <mini-os/lib.h>
#include <mini-os/semaphore.h>

DECLARE_WAIT_QUEUE_HEAD(netfront_queue);

#ifdef HAVE_LIBC
#define NETIF_SELECT_RX ((void*)-1)
#endif



#define NET_TX_RING_SIZE __RING_SIZE((struct netif_tx_sring *)0, PAGE_SIZE)
#define NET_RX_RING_SIZE __RING_SIZE((struct netif_rx_sring *)0, PAGE_SIZE)
#define GRANT_INVALID_REF 0


struct net_buffer {
    void* page;
    grant_ref_t gref;
};

struct netfront_dev {
    domid_t dom;

    unsigned short tx_freelist[NET_TX_RING_SIZE + 1];
    struct semaphore tx_sem;

    struct net_buffer rx_buffers[NET_RX_RING_SIZE];
    struct net_buffer tx_buffers[NET_TX_RING_SIZE];

    struct netif_tx_front_ring tx;
    struct netif_rx_front_ring rx;
    grant_ref_t tx_ring_ref;
    grant_ref_t rx_ring_ref;
    evtchn_port_t evtchn;

    char *nodename;
    char *backend;
    char *mac;

    xenbus_event_queue events;

#ifdef HAVE_LIBC
    int fd;
    unsigned char *data;
    size_t len;
    size_t rlen;
#endif

    void (*netif_rx)(unsigned char* data, int len);
};

void init_rx_buffers(struct netfront_dev *dev);

static inline void add_id_to_freelist(unsigned int id,unsigned short* freelist)
{
    freelist[id + 1] = freelist[0];
    freelist[0]  = id;
}

static inline unsigned short get_id_from_freelist(unsigned short* freelist)
{
    unsigned int id = freelist[0];
    freelist[0] = freelist[id + 1];
    return id;
}

__attribute__((weak)) void netif_rx(unsigned char* data,int len)
{
    printk("%d bytes incoming at %p\n",len,data);
}

__attribute__((weak)) void net_app_main(void*si,unsigned char*mac) {}

static inline int xennet_rxidx(RING_IDX idx)
{
    return idx & (NET_RX_RING_SIZE - 1);
}

void network_rx(struct netfront_dev *dev)
{
    RING_IDX rp,cons,req_prod;
    struct netif_rx_response *rx;
    int nr_consumed, some, more, i, notify;


moretodo:
    rp = dev->rx.sring->rsp_prod;
    rmb(); /* Ensure we see queued responses up to 'rp'. */
    cons = dev->rx.rsp_cons;

    nr_consumed = 0;
    some = 0;
    while ((cons != rp) && !some)
    {
        struct net_buffer* buf;
        unsigned char* page;
        int id;

        rx = RING_GET_RESPONSE(&dev->rx, cons);

        if (rx->flags & NETRXF_extra_info)
        {
            printk("+++++++++++++++++++++ we have extras!\n");
            continue;
        }


        if (rx->status == NETIF_RSP_NULL) continue;

        id = rx->id;
        BUG_ON(id >= NET_TX_RING_SIZE);

        buf = &dev->rx_buffers[id];
        page = (unsigned char*)buf->page;
        gnttab_end_access(buf->gref);

        if(rx->status>0)
        {
#ifdef HAVE_LIBC
	    if (dev->netif_rx == NETIF_SELECT_RX) {
		int len = rx->status;
		ASSERT(current == main_thread);
		if (len > dev->len)
		    len = dev->len;
		memcpy(dev->data, page+rx->offset, len);
		dev->rlen = len;
		some = 1;
	    } else
#endif
		dev->netif_rx(page+rx->offset,rx->status);
        }

        nr_consumed++;

        ++cons;
    }
    dev->rx.rsp_cons=cons;

    RING_FINAL_CHECK_FOR_RESPONSES(&dev->rx,more);
    if(more && !some) goto moretodo;

    req_prod = dev->rx.req_prod_pvt;

    for(i=0; i<nr_consumed; i++)
    {
        int id = xennet_rxidx(req_prod + i);
        netif_rx_request_t *req = RING_GET_REQUEST(&dev->rx, req_prod + i);
        struct net_buffer* buf = &dev->rx_buffers[id];
        void* page = buf->page;

        /* We are sure to have free gnttab entries since they got released above */
        buf->gref = req->gref = 
            gnttab_grant_access(dev->dom,virt_to_mfn(page),0);

        req->id = id;
    }

    wmb();

    dev->rx.req_prod_pvt = req_prod + i;
    
    RING_PUSH_REQUESTS_AND_CHECK_NOTIFY(&dev->rx, notify);
    if (notify)
        notify_remote_via_evtchn(dev->evtchn);

}

void network_tx_buf_gc(struct netfront_dev *dev)
{


    RING_IDX cons, prod;
    unsigned short id;

    do {
        prod = dev->tx.sring->rsp_prod;
        rmb(); /* Ensure we see responses up to 'rp'. */

        for (cons = dev->tx.rsp_cons; cons != prod; cons++) 
        {
            struct netif_tx_response *txrsp;
            struct net_buffer *buf;

            txrsp = RING_GET_RESPONSE(&dev->tx, cons);
            if (txrsp->status == NETIF_RSP_NULL)
                continue;

            if (txrsp->status == NETIF_RSP_ERROR)
                printk("packet error\n");

            id  = txrsp->id;
            BUG_ON(id >= NET_TX_RING_SIZE);
            buf = &dev->tx_buffers[id];
            gnttab_end_access(buf->gref);
            buf->gref=GRANT_INVALID_REF;

	    add_id_to_freelist(id,dev->tx_freelist);
	    up(&dev->tx_sem);
        }

        dev->tx.rsp_cons = prod;

        /*
         * Set a new event, then check for race with update of tx_cons.
         * Note that it is essential to schedule a callback, no matter
         * how few tx_buffers are pending. Even if there is space in the
         * transmit ring, higher layers may be blocked because too much
         * data is outstanding: in such cases notification from Xen is
         * likely to be the only kick that we'll get.
         */
        dev->tx.sring->rsp_event =
            prod + ((dev->tx.sring->req_prod - prod) >> 1) + 1;
        mb();
    } while ((cons == prod) && (prod != dev->tx.sring->rsp_prod));


}

void netfront_handler(evtchn_port_t port, struct pt_regs *regs, void *data)
{
    int flags;
    struct netfront_dev *dev = data;

    local_irq_save(flags);

    network_tx_buf_gc(dev);
    network_rx(dev);

    local_irq_restore(flags);
}

#ifdef HAVE_LIBC
void netfront_select_handler(evtchn_port_t port, struct pt_regs *regs, void *data)
{
    int flags;
    struct netfront_dev *dev = data;
    int fd = dev->fd;

    local_irq_save(flags);
    network_tx_buf_gc(dev);
    local_irq_restore(flags);

    if (fd != -1)
        files[fd].read = 1;
    wake_up(&netfront_queue);
}
#endif

static void free_netfront(struct netfront_dev *dev)
{
    int i;

    for(i=0;i<NET_TX_RING_SIZE;i++)
	down(&dev->tx_sem);

    mask_evtchn(dev->evtchn);

    free(dev->mac);
    free(dev->backend);

    gnttab_end_access(dev->rx_ring_ref);
    gnttab_end_access(dev->tx_ring_ref);

    free_page(dev->rx.sring);
    free_page(dev->tx.sring);

    unbind_evtchn(dev->evtchn);

    for(i=0;i<NET_RX_RING_SIZE;i++) {
	gnttab_end_access(dev->rx_buffers[i].gref);
	free_page(dev->rx_buffers[i].page);
    }

    for(i=0;i<NET_TX_RING_SIZE;i++)
	if (dev->tx_buffers[i].page)
	    free_page(dev->tx_buffers[i].page);

    free(dev->nodename);
    free(dev);
}

struct netfront_dev *init_netfront(char *_nodename, void (*thenetif_rx)(unsigned char* data, int len), unsigned char rawmac[6], char **ip)
{
    xenbus_transaction_t xbt;
    char* err;
    char* message=NULL;
    struct netif_tx_sring *txs;
    struct netif_rx_sring *rxs;
    int retry=0;
    int i;
    char* msg;
    char nodename[256];
    char path[256];
    struct netfront_dev *dev;
    static int netfrontends = 0;

    if (!_nodename)
        snprintf(nodename, sizeof(nodename), "device/vif/%d", netfrontends);
    else
        strncpy(nodename, _nodename, strlen(nodename));
    netfrontends++;

    if (!thenetif_rx)
	thenetif_rx = netif_rx;

    printk("************************ NETFRONT for %s **********\n\n\n", nodename);

    dev = malloc(sizeof(*dev));
    memset(dev, 0, sizeof(*dev));
    dev->nodename = strdup(nodename);
#ifdef HAVE_LIBC
    dev->fd = -1;
#endif

    printk("net TX ring size %d\n", NET_TX_RING_SIZE);
    printk("net RX ring size %d\n", NET_RX_RING_SIZE);
    init_SEMAPHORE(&dev->tx_sem, NET_TX_RING_SIZE);
    for(i=0;i<NET_TX_RING_SIZE;i++)
    {
	add_id_to_freelist(i,dev->tx_freelist);
        dev->tx_buffers[i].page = NULL;
    }

    for(i=0;i<NET_RX_RING_SIZE;i++)
    {
	/* TODO: that's a lot of memory */
        dev->rx_buffers[i].page = (char*)alloc_page();
    }

    snprintf(path, sizeof(path), "%s/backend-id", nodename);
    dev->dom = xenbus_read_integer(path);
#ifdef HAVE_LIBC
    if (thenetif_rx == NETIF_SELECT_RX)
        evtchn_alloc_unbound(dev->dom, netfront_select_handler, dev, &dev->evtchn);
    else
#endif
        evtchn_alloc_unbound(dev->dom, netfront_handler, dev, &dev->evtchn);

    txs = (struct netif_tx_sring *) alloc_page();
    rxs = (struct netif_rx_sring *) alloc_page();
    memset(txs,0,PAGE_SIZE);
    memset(rxs,0,PAGE_SIZE);


    SHARED_RING_INIT(txs);
    SHARED_RING_INIT(rxs);
    FRONT_RING_INIT(&dev->tx, txs, PAGE_SIZE);
    FRONT_RING_INIT(&dev->rx, rxs, PAGE_SIZE);

    dev->tx_ring_ref = gnttab_grant_access(dev->dom,virt_to_mfn(txs),0);
    dev->rx_ring_ref = gnttab_grant_access(dev->dom,virt_to_mfn(rxs),0);

    init_rx_buffers(dev);

    dev->netif_rx = thenetif_rx;

    dev->events = NULL;

again:
    err = xenbus_transaction_start(&xbt);
    if (err) {
        printk("starting transaction\n");
    }

    err = xenbus_printf(xbt, nodename, "tx-ring-ref","%u",
                dev->tx_ring_ref);
    if (err) {
        message = "writing tx ring-ref";
        goto abort_transaction;
    }
    err = xenbus_printf(xbt, nodename, "rx-ring-ref","%u",
                dev->rx_ring_ref);
    if (err) {
        message = "writing rx ring-ref";
        goto abort_transaction;
    }
    err = xenbus_printf(xbt, nodename,
                "event-channel", "%u", dev->evtchn);
    if (err) {
        message = "writing event-channel";
        goto abort_transaction;
    }

    err = xenbus_printf(xbt, nodename, "request-rx-copy", "%u", 1);

    if (err) {
        message = "writing request-rx-copy";
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
    snprintf(path, sizeof(path), "%s/mac", nodename);
    msg = xenbus_read(XBT_NIL, path, &dev->mac);

    if ((dev->backend == NULL) || (dev->mac == NULL)) {
        printk("%s: backend/mac failed\n", __func__);
        goto error;
    }

    printk("backend at %s\n",dev->backend);
    printk("mac is %s\n",dev->mac);

    {
        XenbusState state;
        char path[strlen(dev->backend) + 1 + 5 + 1];
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

        if (ip) {
            snprintf(path, sizeof(path), "%s/ip", dev->backend);
            xenbus_read(XBT_NIL, path, ip);
        }
    }

    printk("**************************\n");

    unmask_evtchn(dev->evtchn);

        /* Special conversion specifier 'hh' needed for __ia64__. Without
           this mini-os panics with 'Unaligned reference'. */
    if (rawmac)
	sscanf(dev->mac,"%hhx:%hhx:%hhx:%hhx:%hhx:%hhx",
            &rawmac[0],
            &rawmac[1],
            &rawmac[2],
            &rawmac[3],
            &rawmac[4],
            &rawmac[5]);

    return dev;
error:
    free_netfront(dev);
    return NULL;
}

#ifdef HAVE_LIBC
int netfront_tap_open(char *nodename) {
    struct netfront_dev *dev;

    dev = init_netfront(nodename, NETIF_SELECT_RX, NULL, NULL);
    if (!dev) {
	printk("TAP open failed\n");
	errno = EIO;
	return -1;
    }
    dev->fd = alloc_fd(FTYPE_TAP);
    printk("tap_open(%s) -> %d\n", nodename, dev->fd);
    files[dev->fd].tap.dev = dev;
    return dev->fd;
}
#endif

void shutdown_netfront(struct netfront_dev *dev)
{
    char* err = NULL;
    XenbusState state;

    char path[strlen(dev->backend) + 1 + 5 + 1];
    char nodename[strlen(dev->nodename) + 1 + 5 + 1];

    printk("close network: backend at %s\n",dev->backend);

    snprintf(path, sizeof(path), "%s/state", dev->backend);
    snprintf(nodename, sizeof(nodename), "%s/state", dev->nodename);

    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateClosing)) != NULL) {
        printk("shutdown_netfront: error changing state to %d: %s\n",
                XenbusStateClosing, err);
        goto close;
    }
    state = xenbus_read_integer(path);
    while (err == NULL && state < XenbusStateClosing)
        err = xenbus_wait_for_state_change(path, &state, &dev->events);

    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateClosed)) != NULL) {
        printk("shutdown_netfront: error changing state to %d: %s\n",
                XenbusStateClosed, err);
        goto close;
    }
    state = xenbus_read_integer(path);
    if (state < XenbusStateClosed)
        xenbus_wait_for_state_change(path, &state, &dev->events);

    if ((err = xenbus_switch_state(XBT_NIL, nodename, XenbusStateInitialising)) != NULL) {
        printk("shutdown_netfront: error changing state to %d: %s\n",
                XenbusStateInitialising, err);
        goto close;
    }
    err = NULL;
    state = xenbus_read_integer(path);
    while (err == NULL && (state < XenbusStateInitWait || state >= XenbusStateClosed))
        err = xenbus_wait_for_state_change(path, &state, &dev->events);

close:
    xenbus_unwatch_path(XBT_NIL, path);

    snprintf(path, sizeof(path), "%s/tx-ring-ref", nodename);
    xenbus_rm(XBT_NIL, path);
    snprintf(path, sizeof(path), "%s/rx-ring-ref", nodename);
    xenbus_rm(XBT_NIL, path);
    snprintf(path, sizeof(path), "%s/event-channel", nodename);
    xenbus_rm(XBT_NIL, path);
    snprintf(path, sizeof(path), "%s/request-rx-copy", nodename);
    xenbus_rm(XBT_NIL, path);

    free_netfront(dev);
}


void init_rx_buffers(struct netfront_dev *dev)
{
    int i, requeue_idx;
    netif_rx_request_t *req;
    int notify;

    /* Rebuild the RX buffer freelist and the RX ring itself. */
    for (requeue_idx = 0, i = 0; i < NET_RX_RING_SIZE; i++) 
    {
        struct net_buffer* buf = &dev->rx_buffers[requeue_idx];
        req = RING_GET_REQUEST(&dev->rx, requeue_idx);

        buf->gref = req->gref = 
            gnttab_grant_access(dev->dom,virt_to_mfn(buf->page),0);

        req->id = requeue_idx;

        requeue_idx++;
    }

    dev->rx.req_prod_pvt = requeue_idx;

    RING_PUSH_REQUESTS_AND_CHECK_NOTIFY(&dev->rx, notify);

    if (notify) 
        notify_remote_via_evtchn(dev->evtchn);

    dev->rx.sring->rsp_event = dev->rx.rsp_cons + 1;
}


void netfront_xmit(struct netfront_dev *dev, unsigned char* data,int len)
{
    int flags;
    struct netif_tx_request *tx;
    RING_IDX i;
    int notify;
    unsigned short id;
    struct net_buffer* buf;
    void* page;

    BUG_ON(len > PAGE_SIZE);

    down(&dev->tx_sem);

    local_irq_save(flags);
    id = get_id_from_freelist(dev->tx_freelist);
    local_irq_restore(flags);

    buf = &dev->tx_buffers[id];
    page = buf->page;
    if (!page)
	page = buf->page = (char*) alloc_page();

    i = dev->tx.req_prod_pvt;
    tx = RING_GET_REQUEST(&dev->tx, i);

    memcpy(page,data,len);

    buf->gref = 
        tx->gref = gnttab_grant_access(dev->dom,virt_to_mfn(page),1);

    tx->offset=0;
    tx->size = len;
    tx->flags=0;
    tx->id = id;
    dev->tx.req_prod_pvt = i + 1;

    wmb();

    RING_PUSH_REQUESTS_AND_CHECK_NOTIFY(&dev->tx, notify);

    if(notify) notify_remote_via_evtchn(dev->evtchn);

    local_irq_save(flags);
    network_tx_buf_gc(dev);
    local_irq_restore(flags);
}

#ifdef HAVE_LIBC
ssize_t netfront_receive(struct netfront_dev *dev, unsigned char *data, size_t len)
{
    unsigned long flags;
    int fd = dev->fd;
    ASSERT(current == main_thread);

    dev->rlen = 0;
    dev->data = data;
    dev->len = len;

    local_irq_save(flags);
    network_rx(dev);
    if (!dev->rlen && fd != -1)
	/* No data for us, make select stop returning */
	files[fd].read = 0;
    /* Before re-enabling the interrupts, in case a packet just arrived in the
     * meanwhile. */
    local_irq_restore(flags);

    dev->data = NULL;
    dev->len = 0;

    return dev->rlen;
}
#endif

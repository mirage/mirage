/*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <mini-os/x86/os.h>
#include <xen/io/netif.h>
#include <mini-os/events.h>
#include <mini-os/netfront.h>
#include <mini-os/gnttab.h>

#define NETFRONT_STUBS_DEBUG   
#ifdef NETFRONT_STUBS_DEBUG
#define NETFRONT_STUB_DPRINTF(x) fprintf(stderr, "CAML: %s\n", (x))
#define NETFRONT_STUB_DPRINTF1(x,y) fprintf(stderr, ("CAML: " x "\n"), (y))
#else 
#define NETFRONT_STUB_DPRINTF1(x,y)
#define NETFRONT_STUB_DPRINTF(x)
#endif

#define NET_TX_RING_SIZE __RING_SIZE((struct netif_tx_sring *)0, PAGE_SIZE)
#define NET_RX_RING_SIZE __RING_SIZE((struct netif_rx_sring *)0, PAGE_SIZE)
#define GRANT_INVALID_REF 0

typedef struct netfront_wrap {
    struct netif_tx_front_ring tx;
    struct netif_rx_front_ring rx;
} netfront_wrap;

#define Netfront_wrap_val(x) (*((netfront_wrap **)(Data_custom_val(x))))

struct netfront_wrap *
netfront_wrap_alloc(domid_t domid, gnttab_wrap *tx_gw, gnttab_wrap *rx_gw)
{
    netfront_wrap *nfw = caml_stat_alloc(sizeof(netfront_wrap));
    struct netif_tx_sring *txs;
    struct netif_rx_sring *rxs;

    NETFRONT_STUB_DPRINTF("netfront_wrap_alloc");
    if (!tx_gw->page) tx_gw->page = (void *)alloc_page();
    if (!rx_gw->page) rx_gw->page = (void *)alloc_page();
    txs = (struct netif_tx_sring *) tx_gw->page;
    rxs = (struct netif_rx_sring *) rx_gw->page;
    memset(txs, 0, PAGE_SIZE);
    memset(rxs, 0, PAGE_SIZE);
    SHARED_RING_INIT(txs);
    SHARED_RING_INIT(rxs);
    FRONT_RING_INIT(&nfw->tx, txs, PAGE_SIZE);
    FRONT_RING_INIT(&nfw->rx, rxs, PAGE_SIZE);
    return nfw;
}

static void
netfront_wrap_finalize(value v_nfw)
{
    NETFRONT_STUB_DPRINTF("netfront_wrap_finalize: TODO");
}

CAMLprim value
caml_netfront_init(value v_domid, value v_tx_gw, value v_rx_gw)
{
    CAMLparam3(v_domid, v_tx_gw, v_rx_gw);
    CAMLlocal1(v_nfw);
    netfront_wrap *nfw;
    NETFRONT_STUB_DPRINTF("caml_netfront_init");
    v_nfw = caml_alloc_final(2, netfront_wrap_finalize, 1, 100);
    Netfront_wrap_val(v_nfw) = NULL;
    nfw = netfront_wrap_alloc (Int_val(v_domid), Gnttab_wrap_val(v_tx_gw), Gnttab_wrap_val(v_rx_gw));
    Netfront_wrap_val(v_nfw) = nfw;
    CAMLreturn(v_nfw);
}

CAMLprim value
caml_netfront_tx_ring_size(value v_nfw)
{
    CAMLparam1(v_nfw);
    CAMLreturn(Val_int(NET_TX_RING_SIZE));
}

CAMLprim value
caml_netfront_rx_ring_size(value v_nfw)
{
    CAMLparam1(v_nfw);
    CAMLreturn(Val_int(NET_RX_RING_SIZE));
}

#define Netfront_req_wrap(x) Field(x,0)
CAMLprim value
caml_nf_rx_req_get(value v_nfw, value v_id)
{
    CAMLparam2(v_nfw, v_id);
    CAMLlocal1(v_wrap);
    netfront_wrap *nfw = Netfront_wrap_val(v_nfw);
    netif_rx_request_t *req;
    req = RING_GET_REQUEST(&nfw->rx, Int_val(v_id));
    v_wrap = caml_alloc(sizeof(req), Abstract_tag);
    Netfront_req_wrap(v_wrap) = (value)req;
    CAMLreturn(v_wrap);
}

CAMLprim value
caml_nf_rx_req_set_gnt(value v_wrap, value v_gw)
{
    CAMLparam2(v_wrap, v_gw);
    netif_rx_request_t *req = (netif_rx_request_t *)Netfront_req_wrap(v_wrap);
    req->gref = Gnttab_wrap_val(v_gw)->ref;
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_nf_rx_req_set_id(value v_wrap, value v_id)
{
    CAMLparam2(v_wrap, v_id);
    netif_rx_request_t *req = (netif_rx_request_t *)Netfront_req_wrap(v_wrap);
    req->id = Int_val(v_id);
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_nf_rx_req_prod_set(value v_nfw, value v_evtchn, value v_id)
{
    CAMLparam3(v_nfw, v_evtchn, v_id);
    int notify;
    netfront_wrap *nfw = Netfront_wrap_val(v_nfw);
    nfw->rx.req_prod_pvt = Int_val(v_id);
    RING_PUSH_REQUESTS_AND_CHECK_NOTIFY(&nfw->rx, notify);
    if (notify)
        notify_remote_via_evtchn(Int_val(v_evtchn));
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_nf_rx_req_prod_get(value v_nfw)
{
    CAMLparam1(v_nfw);
    netfront_wrap *nfw = Netfront_wrap_val(v_nfw);
    CAMLreturn(Val_int(nfw->rx.req_prod_pvt));
}

/* Read a response off the netfront ring */
CAMLprim value
caml_nf_receive(value v_nfw)
{
    CAMLparam1(v_nfw);
    CAMLlocal1(v_ret);
    struct netif_rx_response *rx;
    netfront_wrap *nfw = Netfront_wrap_val(v_nfw);
    RING_IDX rp, cons;
    rp = nfw->rx.sring->rsp_prod;
    rmb(); /* Ensure we see queued responses up to 'rp' */
    cons = nfw->rx.rsp_cons;

    BUG_ON(cons == rp); /* TODO */
    rx = RING_GET_RESPONSE(&nfw->rx, cons);
    printk("rx status=%d flags=%d\n", rx->status, rx->flags);
    v_ret = caml_alloc_tuple(4);
    Store_field(v_ret, 0, Val_int(rx->id));
    Store_field(v_ret, 1, Val_int(rx->offset));
    Store_field(v_ret, 2, Val_int(rx->flags));
    Store_field(v_ret, 3, Val_int(rx->status));
    CAMLreturn(v_ret);
}

/* Ack the response and advance ring by one.
   Returns true if there are more responses pending */
CAMLprim value
caml_nf_receive_ack(value v_nfw)
{
    CAMLparam1(v_nfw);
    int more;
    netfront_wrap *nfw = Netfront_wrap_val(v_nfw);
    nfw->rx.rsp_cons++;
    RING_FINAL_CHECK_FOR_RESPONSES(&nfw->rx, more);
    CAMLreturn(Val_bool(more ? 1 : 0));
}

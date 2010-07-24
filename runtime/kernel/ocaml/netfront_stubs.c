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


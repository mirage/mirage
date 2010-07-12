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

#include <lwip/init.h>
#include <lwip/debug.h>
#include <lwip/mem.h>
#include <lwip/memp.h>
#include <lwip/sys.h>
#include <lwip/stats.h>
#include <lwip/ip.h>
#include <lwip/ip_frag.h>
#include <lwip/udp.h>
#include <lwip/tcp.h>
#include <netif/etharp.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/signals.h>
#include <caml/callback.h>

#include <netfront.h>

#define LWIP_STUBS_DEBUG
#ifdef LWIP_STUBS_DEBUG
#include <stdio.h>
#define LWIP_STUB_DPRINTF(x) fprintf(stderr, "%s\n", (x))
#define LWIP_STUB_DPRINTF1(x,y) fprintf(stderr, (x "\n"), (y))
#else
#define LWIP_STUB_DPRINTF1(x,y)
#define LWIP_STUB_DPRINTF(x)
#endif

/* XXX: these are just for lib_test, need to be
   abstracted out for MirageOS */
err_t netif_netfront_init(struct netif *);

enum tcp_states
{
   TCP_NONE = 0,
   TCP_LISTEN,
   TCP_ACCEPTED,
   TCP_CLOSING
};

typedef struct pbuf_list {
   struct pbuf *p;
   struct pbuf_list *next;
} pbuf_list;

typedef struct tcp_desc {
   u8_t state;        /* TCP state */
   u8_t retries;      /* */
   pbuf_list *rx;   /* pbuf receive queue */
} tcp_desc;

typedef struct tcp_wrap {
    struct tcp_pcb *pcb;
    value v;          /* either accept callback or state record */
    tcp_desc *desc;
} tcp_wrap;

#define Tcp_wrap_val(x) (*((tcp_wrap **)(Data_custom_val(x))))

static value *Lwip_Connection_closed = NULL;

static pbuf_list *
pbuf_list_alloc(struct pbuf *p)
{
    pbuf_list *pl;
    pl = caml_stat_alloc(sizeof(pbuf_list));
    pl->next = NULL;
    pl->p = p;
    return pl;
}

static void
pbuf_list_append(pbuf_list *hd, struct pbuf *p)
{
    pbuf_list *tl = hd;
    while (tl->next) tl=tl->next;
    tl->next = pbuf_list_alloc(p);
}

static void
pbuf_list_free(pbuf_list *pl)
{
    struct pbuf_list *pl2;
    do {
        pbuf_free(pl->p);
        pl2 = pl->next;
        caml_stat_free(pl);
        pl = pl2;
    } while (pl != NULL);
}

static unsigned int
pbuf_list_length(pbuf_list *pl)
{
    unsigned int len = 0;
    struct pbuf_list *pliter = pl;
    do {
        len += pliter->p->tot_len;
        pliter = pliter->next;
    } while (pliter);
    return len;
}

static tcp_wrap *
tcp_wrap_alloc(struct tcp_pcb *pcb)
{
    tcp_wrap *tw = caml_stat_alloc(sizeof(tcp_wrap));
    LWIP_STUB_DPRINTF("tcp_wrap_alloc");
    tw->pcb = pcb;
    tw->v = 0;
    tw->desc = caml_stat_alloc(sizeof(tcp_desc));
    tw->desc->state = TCP_NONE;
    tw->desc->rx = NULL;
    tw->desc->retries = 0;
    return tw;
}

static void
tcp_wrap_finalize(value v_tw)
{
    tcp_wrap *tw = Tcp_wrap_val(v_tw);
    LWIP_STUB_DPRINTF("tcp_wrap_finalize");
    if (tw->pcb) {
        if (tcp_close(tw->pcb) != ERR_OK)
            tcp_abort(tw->pcb);
        tw->pcb = NULL;
    }
    if (tw->desc->rx)
        pbuf_list_free(tw->desc->rx);
    if (tw->desc)
        free(tw->desc);
    if (tw->v)
        caml_remove_generational_global_root(&tw->v);
    free(tw);
}

static inline tcp_wrap *
tcp_wrap_of_value(value v_tw)
{
    struct tcp_wrap *tw = Tcp_wrap_val(v_tw);
    if (tw->pcb == NULL) {
        LWIP_STUB_DPRINTF("tcp_wrap_finalize: CLOSED");
        caml_raise(*Lwip_Connection_closed);
    }
    LWIP_STUB_DPRINTF("tcp_wrap_finalize: ok");
    return tw;
}

CAMLprim value
caml_tcp_new(value v_unit)
{
    CAMLparam1(v_unit);
    CAMLlocal1(v_tw);
    tcp_wrap *tw;
    struct tcp_pcb *pcb = tcp_new();
    LWIP_STUB_DPRINTF("tcp_new");
    if (pcb == NULL)
        caml_failwith("tcp_new: unable to alloc pcb");
    v_tw = caml_alloc_final(2, tcp_wrap_finalize, 1, 100);
    Tcp_wrap_val(v_tw) = NULL;
    tw = tcp_wrap_alloc(pcb);
    Tcp_wrap_val(v_tw) = tw;
    CAMLreturn(v_tw);
}

CAMLprim value
caml_tcp_bind(value v_tw, value v_ip, value v_port)
{
    CAMLparam3(v_tw, v_ip, v_port);
    struct ip_addr ip;
    u16_t port = Int_val(v_port);
    err_t e;
    tcp_wrap *tw = tcp_wrap_of_value(v_tw);
    LWIP_STUB_DPRINTF("cam_tcp_bind");
    IP4_ADDR(&ip, Int_val(Field(v_ip, 0)), Int_val(Field(v_ip, 1)), 
        Int_val(Field(v_ip, 2)), Int_val(Field(v_ip,3)));
    e = tcp_bind(tw->pcb, &ip, port);
    if (e != ERR_OK)
        caml_failwith("tcp_bind: unable to bind");
    CAMLreturn(Val_unit);
}

err_t
tcp_recv_cb(void *arg, struct tcp_pcb *pcb, struct pbuf *p, err_t err)
{
    tcp_wrap *tw = (tcp_wrap *)arg;
    value v_unit;
    err_t ret_err;
    if (p == NULL || err != ERR_OK) {
        LWIP_STUB_DPRINTF("tcp_recv_cb: p==NULL || err!=ERR_OK state->CLOSING");
        tw->desc->state = TCP_CLOSING;
        /* Wake up any listeners, which will get a read error once the
           pending receive queue has been handled by the application */
        v_unit = caml_callback(Field(tw->v, 0), Val_unit);
        if (p) pbuf_free(p);
        ret_err = ERR_OK;
    } else {
        if (tw->desc->rx == NULL) {
            LWIP_STUB_DPRINTF("tcp_recv_cb: rx first packet");
            tw->desc->rx = pbuf_list_alloc(p);
            v_unit = caml_callback(Field(tw->v, 0), Val_unit);
            ret_err = ERR_OK;
        } else if (tw->desc->state == TCP_ACCEPTED) {
            /* Should be no need to wake up listeners here as nothing
               can sleep if there are already pending packets in rx queue */
            LWIP_STUB_DPRINTF("tcp_recv_cb: rx chaining packet");
            pbuf_list_append(tw->desc->rx, p);
            ret_err = ERR_OK;
        } else if (tw->desc->state == TCP_CLOSING) {
            /* Remote side closing twice, trash the data */
            tcp_recved(pcb, p->tot_len);
            pbuf_free(p);
            ret_err = ERR_OK;
        } else {
            LWIP_STUB_DPRINTF1("tcp_recv_cb: rx unknown else; state=%d", tw->desc->state);
            tcp_recved(pcb, p->tot_len);
            pbuf_free(p);
            ret_err = ERR_OK;
        }
    }
    return ret_err;
}

err_t
tcp_sent_cb(void *arg, struct tcp_pcb *pcb, u16_t len)
{
    CAMLparam0();
    CAMLlocal1(v_unit);
    tcp_wrap *tw = (tcp_wrap *)arg;
    err_t ret_err;

    if (len > 0) {
        LWIP_STUB_DPRINTF1("tcp_sent_cb: ack len=%d", len);
        /* No error, so just notify the application that the send
           succeeded and wake up any blocked listeners */
        v_unit = caml_callback(Field(tw->v, 1), Val_unit);
        ret_err = ERR_OK;
    } else {
        /* XXX write error. do something interesting */
        LWIP_STUB_DPRINTF("tcp_sent_cb: write error");
        ret_err = ERR_MEM;
    }
    CAMLreturnT(err_t, ret_err);
}

err_t 
tcp_accept_cb(void *arg, struct tcp_pcb *newpcb, err_t err)
{
    CAMLparam0();
    err_t ret_err;
    tcp_wrap *tw;
    value *cb = (value *)arg;
    value v_state, v_tw;

    tcp_setprio(newpcb, TCP_PRIO_MIN);   

    v_tw = caml_alloc_final(2, tcp_wrap_finalize, 1, 100);
    Tcp_wrap_val(v_tw) = NULL;
    tw = tcp_wrap_alloc(newpcb);
    tw->desc->state = TCP_ACCEPTED;
    Tcp_wrap_val(v_tw) = tw;
    tcp_arg(tw->pcb, tw);
    tcp_recv(newpcb, tcp_recv_cb);
    tcp_sent(newpcb, tcp_sent_cb);

    v_state = caml_callback(*cb, v_tw);
    ret_err = ERR_OK; /* TODO: use callback return to accept or reject */
    CAMLreturnT(err_t, ret_err);
}

CAMLprim value
caml_tcp_set_state(value v_tw, value v_arg)
{
    CAMLparam2(v_tw, v_arg);
    tcp_wrap *tw = tcp_wrap_of_value(v_tw);
    if (tw->v)
        failwith("caml_tcp_set_state: cannot change tw->v");
    tw->v = v_arg;
    caml_register_generational_global_root(&tw->v);
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_tcp_get_state(value v_tw)
{
    CAMLparam1(v_tw);
    tcp_wrap *tw = tcp_wrap_of_value(v_tw);
    if (!tw->v)
        failwith("caml_tcp_get_state: null\n");
    CAMLreturn(tw->v);
}

CAMLprim value
caml_tcp_listen(value v_tw, value v_accept_cb)
{
    CAMLparam2(v_tw, v_accept_cb);
    tcp_wrap *tw = tcp_wrap_of_value(v_tw);
    struct tcp_pcb *new_pcb;
    LWIP_STUB_DPRINTF("caml_tcp_listen");
    new_pcb = tcp_listen(tw->pcb);
    if (new_pcb == NULL)
        caml_failwith("tcp_listen: unable to listen");
    /* XXX realloc a new tcp pcb wrapper so we can construct tcp_listen_pcb in ocaml */
    tw->pcb = new_pcb;  /* tcp_listen will deallocate the old pcb */
    tw->v = v_accept_cb;
    caml_register_generational_global_root(&tw->v);
    tcp_arg(tw->pcb, &tw->v);
    tw->desc->state = TCP_LISTEN;
    tcp_accept(tw->pcb, tcp_accept_cb);
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_tcp_accepted(value v_tw)
{
    CAMLparam1(v_tw);
    tcp_wrap *tw = tcp_wrap_of_value(v_tw);
    LWIP_STUB_DPRINTF("caml_tcp_accepted");
    tw->desc->state = TCP_ACCEPTED;
    tcp_accepted(tw->pcb);
    CAMLreturn(Val_unit);
}

/* NetIF support */

#define Netif_wrap_val(x) (*((struct netif **)(Data_custom_val(x))))
static void
netif_finalize(value v_netif)
{
    struct netif *netif = Netif_wrap_val(v_netif);
    LWIP_STUB_DPRINTF("netif_finalize");
    free(netif);
}

CAMLprim value
caml_netif_new(value v_ip, value v_netmask, value v_gw)
{
    CAMLparam3(v_ip, v_netmask, v_gw);
    CAMLlocal1(v_netif);
    struct ip_addr ip, netmask, gw;
    struct netif *netif;

    unsigned char rawmac[6];
    static struct netfront_dev *dev;

    LWIP_STUB_DPRINTF("caml_netif_new");

    IP4_ADDR(&ip, Int_val(Field(v_ip, 0)), Int_val(Field(v_ip, 1)), 
        Int_val(Field(v_ip, 2)), Int_val(Field(v_ip,3)));
    IP4_ADDR(&netmask, Int_val(Field(v_netmask, 0)), Int_val(Field(v_netmask, 1)), 
        Int_val(Field(v_netmask, 2)), Int_val(Field(v_netmask,3)));
    IP4_ADDR(&gw, Int_val(Field(v_gw, 0)), Int_val(Field(v_gw, 1)), 
        Int_val(Field(v_gw, 2)), Int_val(Field(v_gw,3)));

    /* XXX TODO need a netif_wrap to store dev to close the netfront later */
    dev = init_netfront(NULL, NULL, rawmac, NULL);
    netif = caml_stat_alloc(sizeof(struct netif));
    netif_add(netif, &ip, &netmask, &gw, rawmac, netif_netfront_init, ethernet_input);
    v_netif = caml_alloc_final(2, netif_finalize, 1, 100);
    Netif_wrap_val(v_netif) = netif;
    
    CAMLreturn(v_netif);
}

/* Copy out all the pbufs in a chain into a string, and ack/free pbuf.
 * @return 0: nothing, -1: closed connection, +n: bytes read
 */
CAMLprim value
caml_tcp_read(value v_tw)
{
    CAMLparam1(v_tw);
    CAMLlocal1(v_str);
    /* Not using tcp_wrap_of_value as we need to clear out the remaining
       RX queue before raising the Connection_closed exception. Check that
       tw->pcb is set for the rest of the function before using it. */
    tcp_wrap *tw = Tcp_wrap_val(v_tw);
    struct pbuf_list *pl = tw->desc->rx;
    unsigned int tot_len;
    char *s;

    LWIP_STUB_DPRINTF("caml_tcp_rx_read");
    if (!pl) {
        v_str = caml_alloc_string(0);
        CAMLreturn(v_str);
    }

    tot_len = pbuf_list_length(pl);
    v_str = caml_alloc_string(tot_len);
    s = String_val(v_str);
    do {
        pbuf_copy_partial(pl->p, s, pl->p->tot_len, 0);
        s += pl->p->tot_len;
    } while ((pl = pl->next));
    if (tw->pcb)
        tcp_recved(tw->pcb, tot_len);
    pbuf_list_free(tw->desc->rx);
    tw->desc->rx = NULL;
    CAMLreturn(v_str);   
}

CAMLprim value
caml_tcp_read_len(value v_tw)
{
    CAMLparam1(v_tw);
    tcp_wrap *tw = tcp_wrap_of_value(v_tw);
    if (tw->desc->rx)
        CAMLreturn(Val_int(pbuf_list_length(tw->desc->rx)));
    else {
        if (tw->desc->state == TCP_CLOSING)
            CAMLreturn(Val_int(-1));
        else
            CAMLreturn(Val_int(0));
    }
}

CAMLprim value
caml_tcp_recved(value v_tw, value v_len)
{
    CAMLparam2(v_tw, v_len);
    tcp_wrap *tw = tcp_wrap_of_value(v_tw);
    LWIP_STUB_DPRINTF1("caml_tcp_recved: %d", Int_val(v_len));
    tcp_recved(tw->pcb, Int_val(v_len));
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_tcp_write(value v_tw, value v_buf, value v_off, value v_len)
{
    CAMLparam4(v_tw, v_buf, v_off, v_len);
    tcp_wrap *tw = tcp_wrap_of_value(v_tw);
    err_t err;
    /* XXX no bounds checks on off, len */
    err = tcp_write(tw->pcb, String_val(v_buf)+Int_val(v_off), Int_val(v_len), 1);
    LWIP_STUB_DPRINTF1("tcp_write: err=%d", err);
    if (err == ERR_OK)
       CAMLreturn(v_len);
    else
       CAMLreturn(Val_int(-1));
}

CAMLprim value
caml_tcp_sndbuf(value v_tw)
{
    CAMLparam1(v_tw);
    tcp_wrap *tw = tcp_wrap_of_value(v_tw);
    CAMLreturn(Val_int(tw->pcb->snd_buf));
}

CAMLprim value
caml_tcp_close(value v_tw)
{
    CAMLparam1(v_tw);
    tcp_wrap *tw = tcp_wrap_of_value(v_tw);
    err_t ret;
    ret = tcp_close(tw->pcb);
    if (ret == ERR_OK) {
        tw->pcb = NULL;
        tw->desc->state = TCP_CLOSING;
        CAMLreturn(Val_bool(1));
    }
    CAMLreturn(Val_bool(0));
}

CAMLprim value
caml_tcp_abort(value v_tw)
{
    CAMLparam1(v_tw);
    tcp_wrap *tw = tcp_wrap_of_value(v_tw);
    tcp_abort(tw->pcb);
    tw->pcb = NULL;
    tw->desc->state = TCP_CLOSING;
    CAMLreturn(Val_unit);
}

/* Netif */

CAMLprim value
caml_netif_set_default(value v_netif)
{
    CAMLparam1(v_netif);
    netif_set_default( Netif_wrap_val(v_netif) );
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_netif_set_up(value v_netif)
{
    CAMLparam1(v_netif);
    netif_set_up( Netif_wrap_val(v_netif) );
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_netif_select(value v_netif)
{
    CAMLparam1(v_netif);
    CAMLreturn(Val_int(0));
}

/* Timers */

CAMLprim value
caml_timer_tcp(value v_unit)
{
    CAMLparam1(v_unit);
    tcp_tmr();
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_timer_ip_reass(value v_unit)
{
    CAMLparam1(v_unit);
    ip_reass_tmr();
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_timer_etharp(value v_unit)
{
    CAMLparam1(v_unit);
    etharp_tmr();
    CAMLreturn(Val_unit);
}

/* LWIP core */

CAMLprim value
caml_lwip_init(value v_unit)
{
    CAMLparam1(v_unit);
    Lwip_Connection_closed = caml_named_value("TCP.Connection_closed");
    lwip_init ();
    CAMLreturn(Val_unit);
}


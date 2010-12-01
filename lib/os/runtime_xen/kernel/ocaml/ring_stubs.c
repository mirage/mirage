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
#include <mini-os/gnttab.h>
#include <mini-os/events.h>
#include <xen/io/netif.h>
#include <xen/io/console.h>
#include <xen/io/xs_wire.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>

/* The DEFINE_TYPED_RING_OPS macro defines OCaml functions to initialise and
   perform common ring operations on a specified type that has been
   previously declared using the DEFINE_RING_TYPES macro. This must be
   done using separate functions since the RING_* macros need to know
   the type of the ring at compile-time */

/* Note that this is 64-bit safe only, as the indices for producer
   and consumer must be at least 32-bit wide (as they are incremented
   until they wrap, and so a 31-bit native int is not enough. However,
   to avoid allocation and since Mirage is 64-bit only, we use Val_int
   here without problem, but beware if you want to run on x86_32 */

#define DEFINE_TYPED_RING_OPS(xtype) \
CAMLprim value \
caml_##xtype##_ring_init(value v_gw) \
{ \
   gnttab_wrap *gw = Gnttab_wrap_val(v_gw); \
   if (gw->page == NULL) gw->page = (void *)alloc_page(); \
   struct xtype##_sring *r; \
   struct xtype##_front_ring *fr = caml_stat_alloc(sizeof(struct xtype##_front_ring)); \
   r = (struct xtype##_sring *) gw->page; \
   memset(r, 0, PAGE_SIZE); \
   SHARED_RING_INIT(r); \
   FRONT_RING_INIT(fr, r, PAGE_SIZE); \
   return (value)fr; \
} \
\
CAMLprim value \
caml_##xtype##_ring_req_get(value v_ring, value v_idx) \
{ \
   struct xtype##_front_ring *r = (struct xtype##_front_ring *)v_ring; \
   return (value)RING_GET_REQUEST(r, Int_val(v_idx)); \
} \
\
CAMLprim value \
caml_##xtype##_ring_res_get(value v_ring, value v_idx) \
{ \
   struct xtype##_front_ring *r = (struct xtype##_front_ring *)v_ring; \
   return (value)RING_GET_RESPONSE(r, Int_val(v_idx)); \
} \
\
CAMLprim value \
caml_##xtype##_ring_req_push(value v_ring, value v_num, value v_evtchn) \
{ \
   struct xtype##_front_ring *r = (struct xtype##_front_ring *)v_ring; \
   int notify; \
   r->req_prod_pvt += Int_val(v_num); \
   wmb (); \
   RING_PUSH_REQUESTS_AND_CHECK_NOTIFY(r, notify); \
   if (notify) notify_remote_via_evtchn(Int_val(v_evtchn)); \
   return Val_unit; \
} \
\
CAMLprim value \
caml_##xtype##_ring_res_waiting(value v_ring) \
{ \
   struct xtype##_front_ring *r = (struct xtype##_front_ring *)v_ring; \
   return Val_int(RING_HAS_UNCONSUMED_RESPONSES(r)); \
} \
\
CAMLprim value \
caml_##xtype##_ring_res_ack(value v_ring, value v_num) \
{ \
   struct xtype##_front_ring *r = (struct xtype##_front_ring *)v_ring; \
   int more; \
   r->rsp_cons += Int_val(v_num); \
   RING_FINAL_CHECK_FOR_RESPONSES(r, more); \
   return Val_bool(more ? 1 : 0); \
} \
\
CAMLprim value \
caml_##xtype##_ring_size(value v_unit) \
{ \
   return Val_int(__RING_SIZE((struct xtype##_sring *)0, PAGE_SIZE)); \
} \
\
CAMLprim value \
caml_##xtype##_ring_res_get_cons(value v_ring) \
{ \
   struct xtype##_front_ring *r = (struct xtype##_front_ring *)v_ring; \
   return Val_int(r->rsp_cons); \
} \
CAMLprim value \
caml_##xtype##_ring_req_get_prod(value v_ring) \
{ \
   struct xtype##_front_ring *r = (struct xtype##_front_ring *)v_ring; \
   return Val_int(r->req_prod_pvt); \
} \

DEFINE_TYPED_RING_OPS(netif_tx);
DEFINE_TYPED_RING_OPS(netif_rx);

#define DEFINE_RAW_RING_OPS(xname,xtype,xin,xout) \
CAMLprim value \
caml_##xname##_ring_init(value v_gw) \
{ \
   gnttab_wrap *gw = Gnttab_wrap_val(v_gw); \
   if (gw->page == NULL) gw->page = (void *)alloc_page(); \
   memset(gw->page, 0, PAGE_SIZE); \
   return (value)gw->page; \
} \
CAMLprim value \
caml_##xname##_ring_write(value v_ring, value v_str, value v_len) \
{ \
   struct xtype *intf = (struct xtype *)v_ring; \
   int can_write = 0, len = Int_val(v_len); \
   XENCONS_RING_IDX cons, prod, cons_mask, prod_mask; \
   cons = intf->xout##_cons; \
   prod = intf->xout##_prod; \
   cons_mask = cons & (sizeof(intf->xout) - 1); \
   prod_mask = prod & (sizeof(intf->xout) - 1); \
   mb(); \
   if ( (prod-cons) >= sizeof(intf->xout) ) \
     return(Val_int(0)); \
   if (prod_mask >= cons_mask) \
     can_write = sizeof(intf->xout) - prod_mask; \
   else \
     can_write = cons_mask - prod_mask; \
   if (can_write < len) \
     len = can_write; \
   memcpy(intf->xout + prod_mask, String_val(v_str), len); \
   mb (); \
   intf->xout##_prod += len; \
   return Val_int(len); \
} \
CAMLprim value \
caml_##xname##_ring_read(value v_ring, value v_str, value v_len) \
{ \
   struct xtype *intf = (struct xtype *)v_ring; \
   int to_read, len = Int_val(v_len); \
   XENCONS_RING_IDX cons, prod, cons_mask, prod_mask; \
   mb (); \
   cons = intf->xin##_cons; \
   prod = intf->xin##_prod; \
   cons_mask = cons & (sizeof(intf->xin) - 1); \
   prod_mask = prod & (sizeof(intf->xin) - 1); \
   if (prod == cons) \
     return (Val_int(0)); \
   if (prod_mask > cons_mask) \
     to_read = prod - cons; \
   else \
     to_read = sizeof(intf->xin) - cons_mask; \
   if (to_read < len) \
     len = to_read; \
   memcpy(String_val(v_str), intf->xin + cons_mask, len); \
   mb (); \
   intf->xin##_cons += len; \
   return Val_int(len); \
}

DEFINE_RAW_RING_OPS(console,xencons_interface,in,out);
DEFINE_RAW_RING_OPS(xenstore,xenstore_domain_interface,rsp,req);

CAMLprim value
caml_console_start_ring_init(value v_gw)
{
    gnttab_wrap *gw = Gnttab_wrap_val(v_gw);
    ASSERT(gw->page == NULL);
    gw->page = mfn_to_virt(start_info.console.domU.mfn);
    return (value)gw->page;
}

CAMLprim value
caml_xenstore_start_ring_init(value v_gw)
{
    gnttab_wrap *gw = Gnttab_wrap_val(v_gw);
    ASSERT(gw->page == NULL);
    gw->page = mfn_to_virt(start_info.store_mfn);
    return (value)gw->page;
}

/* Manually fill in functions to set parameters in requests */

CAMLprim value
caml_netif_rx_ring_req_set(value v_req, value v_id, value v_gw)
{
    netif_rx_request_t *r = (netif_rx_request_t *)v_req;
    r->id = Int_val(v_id);
    r->gref = Gnttab_wrap_val(v_gw)->ref;
    return Val_unit;
}

CAMLprim value
caml_netif_tx_ring_req_set(value v_req, value v_off, value v_flags, value v_id, value v_size)
{
    netif_tx_request_t *r = (netif_tx_request_t *)v_req;
    r->offset = Int_val(v_off);
    r->flags = Int_val(v_flags);
    r->id = Int_val(v_id);
    r->size = Int_val(v_size);
    return Val_unit;
}

CAMLprim value
caml_netif_tx_ring_req_set_gnt(value v_req, value v_gw)
{
    netif_tx_request_t *r = (netif_tx_request_t *)v_req;
    r->gref = Gnttab_wrap_val(v_gw)->ref;
    return Val_unit;
}

/* These macros define direct accessor functions from OCaml
   to access individual structures in the response pointers */

#define DEFINE_RING_RESP_GET_INT(xtype, xfield) \
CAMLprim value \
caml_##xtype##_ring_res_get_##xfield(value v_resp) \
{ \
    xtype##_response_t *r = (xtype##_response_t *)v_resp; \
    return Val_int(r->xfield); \
}

DEFINE_RING_RESP_GET_INT(netif_rx, id);
DEFINE_RING_RESP_GET_INT(netif_rx, offset);
DEFINE_RING_RESP_GET_INT(netif_rx, flags);
DEFINE_RING_RESP_GET_INT(netif_rx, status);


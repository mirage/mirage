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
#include <istring.h>

/* netif_rx_response { id:int; off: int; flags: int; status: int } */
value
netif_rx_alloc_response(struct netif_rx_response *response)
{
  value v = alloc_small(4,0);
  Store_field(v, 0, Val_int(response->id));
  Store_field(v, 1, Val_int(response->offset));
  Store_field(v, 2, Val_int(response->flags));
  Store_field(v, 3, Val_int(response->status));
  printk("netif_rx_alloc_response: id=%d off=%d flags=%d st=%d\n",
    response->id, response->offset, response->flags, response->status);
  return v;
}

/* netif_rx_request { id: int; gref: int32; } */
static void
netif_rx_set_request(value v_req, struct netif_rx_request *req)
{
  req->id = Int_val(Field(v_req, 0));
  req->gref = Int32_val(Field(v_req, 1));
}

/* netif_tx_response { id: int; status: int } */
value
netif_tx_alloc_response(struct netif_tx_response *response)
{
  value v = alloc_small(2,0);
  Store_field(v, 0, Val_int(response->id));
  Store_field(v, 1, Val_int(response->status));
  printk("netif_tx_alloc_response: id=%d status=%d\n", 
    response->id, response->status);
  return v;
}

/* netif_tx_request:
   type extra = 
     | GSO of { size: int; type: int; features: int }
     | Mcast_add of string
     | Mcast_del of string
   type req = 
     | Req of { gref: int32; offset: int; flags: int; id: int; size: int }
     | Extra of { ty: int; more: bool }
 */
static void
netif_tx_set_request(value v_req, struct netif_tx_request *req)
{
  value v = Field(v_req, 0);
  netif_extra_info_t *ex;
  switch (Tag_val(v_req)) {
    case 0: /* Request */
      req->gref = Int32_val(Field(v, 0));
      req->offset = Int_val(Field(v, 1));
      req->flags = Int_val(Field(v, 2));
      req->id = Int_val(Field(v, 3));
      req->size = Int_val(Field(v, 4));
      printk("tx_set_req: gref=%lu off=%d fl=%d id=%d size=%d\n", req->gref, req->offset, req->flags, req->id, req->size);
      break;
    case 1: /* Extra */
      ex = (netif_extra_info_t *)req;
      switch (Tag_val(v)) {
        case 0: /* GSO */
          v = Field(v, 0);
          ex->u.gso.size = Int_val(Field(v, 0));
          ex->u.gso.type = Int_val(Field(v, 1));
          ex->u.gso.features = Int_val(Field(v, 2));
          break;
        case 1: /* Mcast_add */
          memcpy(ex->u.mcast.addr, String_val(Field(v,0)), 6);
          break;
        case 2: /* Mcast_del */
          memcpy(ex->u.mcast.addr, String_val(Field(v,0)), 6);
          break;
        default:
          BUG_ON("netif_tx_set_request: unknown Tag_val extra");
      }
      break;
    default:
      BUG_ON("netif_tx_set_request: unknown Tag_val");
  }
}

value
caml_netif_rx_response(value v_ring)
{
  CAMLparam1(v_ring);
  CAMLlocal2(v_responses, v_cons);
  RING_IDX rp, cons;
  struct netif_rx_front_ring *fring = (struct netif_rx_front_ring *)v_ring;
  struct netif_rx_response *response;
  int nr_responses = 0, more=1;
 
  rp = fring->sring->rsp_prod;
  rmb(); /* Ensure we see queued responses up to rp */
  cons = fring->rsp_cons;

  /* Allocate an OCaml list for the responses
     (so remember they will be returned in reverse order!) */
  v_responses = Val_emptylist;
  printk("nr_responses=%d\n", nr_responses);

  while (more) {
    /* Walk through the outstanding responses and add to list */
    for (; cons != rp; cons++) {
      response = RING_GET_RESPONSE(fring, cons);
      /* Append response to the OCaml response list */ 
      v_cons = caml_alloc(2, 0);
      Store_field(v_cons, 0, netif_rx_alloc_response(response)); /* head */
      Store_field(v_cons, 1, v_responses); /* tail */
      v_responses = v_cons;
    }
    /* Mark responses as consumed */
    fring->rsp_cons = cons;
    RING_FINAL_CHECK_FOR_RESPONSES(fring, more);
  }
  CAMLreturn(v_responses);
}

/* ring -> req list -> int (if notify required to evtchn) */
CAMLprim value
caml_netif_rx_request(value v_ring, value v_reqs)
{
  CAMLparam1(v_ring);
  CAMLlocal1(v_req); /* Head of reqs list */
  struct netif_rx_front_ring *fring = (struct netif_rx_front_ring *)v_ring;
  netif_rx_request_t *req;
  RING_IDX req_prod;
  int notify;

  req_prod = fring->req_prod_pvt;
  while (v_reqs != Val_emptylist) {
    v_req = Field(v_reqs, 0);
    req = RING_GET_REQUEST(fring, req_prod++);
    netif_rx_set_request(v_req, req);
    v_reqs = Field(v_reqs, 1);
  }
  wmb();
  fring->req_prod_pvt = req_prod;
  RING_PUSH_REQUESTS_AND_CHECK_NOTIFY(fring, notify);
  CAMLreturn(Val_int(notify));
}

value
caml_netif_rx_free_requests(value v_ring)
{
  return Val_int(RING_FREE_REQUESTS((struct netif_rx_front_ring *)v_ring));
}

value
caml_netif_rx_max_requests(value v_ring)
{
  return Val_int(RING_SIZE((struct netif_rx_front_ring *)v_ring)-1);
}





value
caml_netif_tx_response(value v_ring)
{
  CAMLparam1(v_ring);
  CAMLlocal2(v_responses, v_cons);
  RING_IDX rp, cons;
  struct netif_tx_front_ring *fring = (struct netif_tx_front_ring *)v_ring;
  struct netif_tx_response *response;
  int nr_responses = 0, more=1;
 
  rp = fring->sring->rsp_prod;
  rmb(); /* Ensure we see queued responses up to rp */
  cons = fring->rsp_cons;

  /* Allocate an OCaml list for the responses
     (so remember they will be returned in reverse order!) */
  v_responses = Val_emptylist;
  printk("nr_responses=%d\n", nr_responses);

  while (more) {
    /* Walk through the outstanding responses and add to list */
    for (; cons != rp; cons++) {
      response = RING_GET_RESPONSE(fring, cons);
      /* Append response to the OCaml response list */ 
      v_cons = caml_alloc(2, 0);
      Store_field(v_cons, 0, netif_tx_alloc_response(response)); /* head */
      Store_field(v_cons, 1, v_responses); /* tail */
      v_responses = v_cons;
    }
    /* Mark responses as consumed */
    fring->rsp_cons = cons;
    RING_FINAL_CHECK_FOR_RESPONSES(fring, more);
  }
  CAMLreturn(v_responses);
}

/* ring -> req list -> int (if notify required to evtchn) */
CAMLprim value
caml_netif_tx_request(value v_ring, value v_reqs)
{
  CAMLparam1(v_ring);
  CAMLlocal1(v_req); /* Head of reqs list */
  struct netif_tx_front_ring *fring = (struct netif_tx_front_ring *)v_ring;
  netif_tx_request_t *req;
  RING_IDX req_prod;
  int notify;

  req_prod = fring->req_prod_pvt;
  while (v_reqs != Val_emptylist) {
    v_req = Field(v_reqs, 0);
    req = RING_GET_REQUEST(fring, req_prod++);
    netif_tx_set_request(v_req, req);
    v_reqs = Field(v_reqs, 1);
  }
  wmb();
  fring->req_prod_pvt = req_prod;
  RING_PUSH_REQUESTS_AND_CHECK_NOTIFY(fring, notify);
  CAMLreturn(Val_int(notify));
}

value
caml_netif_tx_free_requests(value v_ring)
{
  return Val_int(RING_FREE_REQUESTS((struct netif_tx_front_ring *)v_ring));
}

value
caml_netif_tx_max_requests(value v_ring)
{
  return Val_int(RING_SIZE((struct netif_tx_front_ring *)v_ring)-1);
}


value
caml_netif_rx_init(value v_istr)
{
  CAMLparam1(v_istr);
  struct netif_rx_front_ring *fring;
  struct netif_rx_sring *sring;
  sring = (struct netif_rx_sring *)(Istring_val(v_istr)->buf);
  SHARED_RING_INIT(sring);
  fring = caml_stat_alloc(sizeof (struct netif_rx_front_ring));
  FRONT_RING_INIT(fring, sring, PAGE_SIZE);
  printk("netif_rx_init: sring=%p fring=%p\n", sring, fring);
  CAMLreturn((value)fring);
}
 
value
caml_netif_tx_init(value v_istr)
{
  CAMLparam1(v_istr);
  struct netif_tx_front_ring *fring;
  struct netif_tx_sring *sring;
  sring = (struct netif_tx_sring *)(Istring_val(v_istr)->buf);
  SHARED_RING_INIT(sring);
  fring = caml_stat_alloc(sizeof (struct netif_tx_front_ring));
  FRONT_RING_INIT(fring, sring, PAGE_SIZE);
  printk("netif_tx_init: sring=%p fring=%p\n", sring, fring);
  CAMLreturn((value)fring);
} 


/* Raw ring operations
   These have no request/response structs, just byte strings
 */

#define DEFINE_RAW_RING_OPS(xname,xtype,xin,xout) \
CAMLprim value \
caml_##xname##_ring_init(value v_istr) \
{ \
   memset(Istring_val(v_istr)->buf, 0, PAGE_SIZE); \
   return Val_unit; \
} \
CAMLprim value \
caml_##xname##_ring_write(value v_istr, value v_str, value v_len) \
{ \
   struct xtype *intf = (struct xtype *)(Istring_val(v_istr)->buf); \
   int sent = 0, len = Int_val(v_len); \
   char *data = String_val(v_str); \
   XENCONS_RING_IDX cons, prod; \
   cons = intf->xout##_cons; \
   prod = intf->xout##_prod; \
   mb(); \
   BUG_ON((prod - cons) > sizeof(intf->xout)); \
   while ((sent < len) && ((prod - cons) < sizeof(intf->xout))) \
     intf->xout[MASK_XENCONS_IDX(prod++, intf->xout)] = data[sent++]; \
   wmb(); \
   intf->xout##_prod = prod; \
   return Val_int(len); \
} \
CAMLprim value \
caml_##xname##_ring_read(value v_istr, value v_str, value v_len) \
{ \
   struct xtype *intf = (struct xtype *)(Istring_val(v_istr)->buf); \
   int pos=0, len = Int_val(v_len); \
   char *data = String_val(v_str); \
   XENCONS_RING_IDX cons, prod; \
   cons = intf->xin##_cons; \
   prod = intf->xin##_prod; \
   mb(); \
   BUG_ON((prod - cons) > sizeof(intf->xin)); \
   while (cons != prod && pos < len) \
     data[pos++] = intf->xin[MASK_XENCONS_IDX(cons++, intf->xin)]; \
   mb(); \
   intf->xin##_cons = cons; \
   return Val_int(pos); \
}

DEFINE_RAW_RING_OPS(console,xencons_interface,in,out);
DEFINE_RAW_RING_OPS(xenstore,xenstore_domain_interface,rsp,req);

CAMLprim value
caml_console_start_page(value v_unit)
{
  CAMLparam1(v_unit);
  CAMLlocal1(v_ret);
  unsigned char *page = mfn_to_virt(start_info.console.domU.mfn);
  v_ret = istring_alloc(page, 4096);
  CAMLreturn(v_ret);
}

CAMLprim value
caml_xenstore_start_page(value v_unit)
{
  CAMLparam1(v_unit);
  CAMLlocal1(v_ret);
  unsigned char *page = mfn_to_virt(start_info.store_mfn);
  v_ret = istring_alloc(page, 4096);
  CAMLreturn(v_ret);
}


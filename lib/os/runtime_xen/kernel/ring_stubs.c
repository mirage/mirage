/*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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
#include <xen/io/blkif.h>
#include <xen/io/console.h>
#include <xen/io/xs_wire.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>


/* Raw ring operations
   These have no request/response structs, just byte strings
 */

#define DEFINE_RAW_RING_OPS(xname,xtype,xin,xout) \
CAMLprim value \
caml_##xname##_ring_init(value v_ptr) \
{ \
   memset((void *)v_ptr, 0, PAGE_SIZE); \
   return Val_unit; \
} \
CAMLprim value \
caml_##xname##_ring_write(value v_ptr, value v_str, value v_len) \
{ \
   struct xtype *intf = (struct xtype *)v_ptr; \
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
caml_##xname##_ring_read(value v_ptr, value v_str, value v_len) \
{ \
   struct xtype *intf = (struct xtype *)v_ptr; \
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
  v_ret = (value)page;
  CAMLreturn(v_ret);
}

CAMLprim value
caml_xenstore_start_page(value v_unit)
{
  CAMLparam1(v_unit);
  CAMLlocal1(v_ret);
  unsigned char *page = mfn_to_virt(start_info.store_mfn);
  v_ret = (value)page;
  CAMLreturn(v_ret);
}

/* Shared ring with request/response structs */

struct sring {
  RING_IDX req_prod, req_event;
  RING_IDX rsp_prod, rsp_event;
  uint8_t  netfront_smartpoll_active;
  uint8_t  pad[47];
};

struct front_ring {
  RING_IDX req_prod_pvt;
  RING_IDX rsp_cons;
  unsigned int nr_ents;
  struct sring *sring;
};

struct back_ring {
  RING_IDX rsp_prod_pvt;
  RING_IDX req_cons;
  unsigned int nr_ents;
  struct sring *sring;
};

#define SRING_VAL(x) ((struct sring *)(String_val(Field((x),0))+Int_val(Field((x),1)/8)))
CAMLprim value
caml_sring_rsp_prod(value v_sring)
{
  return Val_int(SRING_VAL(v_sring)->rsp_prod);
}

CAMLprim value
caml_sring_req_prod(value v_sring)
{
  return Val_int(SRING_VAL(v_sring)->req_prod);
}

CAMLprim value
caml_sring_req_event(value v_sring)
{
  xen_mb ();
  return Val_int(SRING_VAL(v_sring)->req_event);
}

CAMLprim value
caml_sring_rsp_event(value v_sring)
{
  xen_mb ();
  return Val_int(SRING_VAL(v_sring)->rsp_event);
}

CAMLprim value
caml_sring_push_requests(value v_sring, value v_req_prod_pvt)
{
  struct sring *sring = SRING_VAL(v_sring);
  xen_wmb(); /* ensure requests are seen before the index is updated */
  sring->req_prod = Int_val(v_req_prod_pvt);
  return Val_unit;
}

CAMLprim value
caml_sring_push_responses(value v_sring, value v_rsp_prod_pvt)
{
  struct sring *sring = SRING_VAL(v_sring);
  xen_wmb(); /* ensure requests are seen before the index is updated */
  sring->rsp_prod = Int_val(v_rsp_prod_pvt);
  return Val_unit;
}

CAMLprim value
caml_sring_set_rsp_event(value v_sring, value v_rsp_cons)
{
  struct sring *sring = SRING_VAL(v_sring);
  sring->rsp_event = Int_val(v_rsp_cons);
  xen_mb();
  return Val_unit;
}

CAMLprim value
caml_sring_set_req_event(value v_sring, value v_req_cons)
{
  struct sring *sring = SRING_VAL(v_sring);
  sring->req_event = Int_val(v_req_cons);
  xen_mb();
  return Val_unit;
}


/*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
 * Copyright (C) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 */

#include <mini-os/x86/os.h>
#include <mini-os/time.h>
#include <mini-os/events.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/bigarray.h>

#define NR_EVENTS 16 /* same as events.c XXX */
static uint8_t ev_callback_ml[NR_EVENTS];

/* Called with interrupts enabled to mark an event channel as being
   active. Safe to call multiple times... */
static void
caml_evtchn_handler(evtchn_port_t port, struct pt_regs *regs, void *ign)
{
    ASSERT(port < NR_EVENTS);
    ev_callback_ml[port] = 1;
}

/* Initialise the events Bigarray and bind the predefined ports */
CAMLprim value
caml_evtchn_init(value v_unit)
{
    CAMLparam1(v_unit);
    CAMLlocal1(v_arr);
    int rc;
    rc = bind_evtchn(start_info.store_evtchn, caml_evtchn_handler, NULL);
    rc = bind_evtchn(start_info.console.domU.evtchn, caml_evtchn_handler, NULL);
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_nr_events(value v_unit)
{
   return Val_int(NR_EVENTS);
}

CAMLprim value
caml_evtchn_test_and_clear(value v_idx)
{
   int idx = Int_val(v_idx) % NR_EVENTS;
   if (ev_callback_ml[idx] > 0) {
      ev_callback_ml[idx] = 0;
      return Val_int(1);
   } else
      return Val_int(0);
}

CAMLprim value
stub_evtchn_alloc_unbound(value v_domid)
{
    CAMLparam1(v_domid);
    domid_t domid = Int_val(v_domid);
    int rc;
    evtchn_port_t port;

    rc = evtchn_alloc_unbound(domid, caml_evtchn_handler, NULL, &port);
    if (rc)
       CAMLreturn(Val_int(-1));
    else
       CAMLreturn(Val_int(port)); 
}

CAMLprim value
stub_evtchn_unmask(value v_port)
{
    CAMLparam1(v_port);
    unmask_evtchn(Int_val(v_port));
    CAMLreturn(Val_unit);
}

CAMLprim value
stub_evtchn_notify(value v_port)
{
        CAMLparam1(v_port);
        notify_remote_via_evtchn(Int_val(v_port));
        CAMLreturn(Val_unit);
}

CAMLprim value
stub_xenstore_evtchn_port(value unit)
{
        CAMLparam1(unit);
        CAMLreturn(Val_int(start_info.store_evtchn));
}

CAMLprim value
stub_console_evtchn_port(value unit)
{
	CAMLparam1(unit);
	CAMLreturn(Val_int(start_info.console.domU.evtchn));
}

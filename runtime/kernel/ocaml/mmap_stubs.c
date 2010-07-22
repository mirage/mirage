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

#include <unistd.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <string.h>
#include "mmap_stubs.h"

#include <xen/xen.h>
#include <mini-os/hypervisor.h>
#include <mini-os/events.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/callback.h>

#define GET_C_STRUCT(a) ((struct mmap_interface *) a)

#define NR_EVENTS 16 /* same as events.c XXX */
static uint8_t ev_callback_ml[NR_EVENTS];

/* Called by mirage_block_domain after interrupts are reenabled
   to run any activations, before handing control back to the
   LWT main loop */
void
post_event_callbacks(void)
{
    static value *closure_f = NULL;
    if (closure_f == NULL)
        closure_f = caml_named_value("Activations.activate");
    for (int i=0; i<NR_EVENTS; i++)
       if (ev_callback_ml[i] == 1) {
         ev_callback_ml[i] = 0;
         caml_callback(*closure_f, Val_int(i));
       }
}

/* Called with interrupts enabled to mark an event channel as being
   active. Safe to call multiple times... */
static void
caml_evtchn_handler(evtchn_port_t port, struct pt_regs *regs, void *ign)
{
    ASSERT(port < NR_EVENTS);
    ev_callback_ml[port] = 1;
}

CAMLprim value
stub_evtchn_alloc_unbound(value v_domid)
{
    CAMLparam1(v_domid);
    domid_t domid = Int_val(v_domid);
    int rc, port;

    rc = evtchn_alloc_unbound(domid, caml_evtchn_handler, NULL, &port);
    if (rc)
       CAMLreturn(Val_int(-1));
    else
       CAMLreturn(Val_int(port)); 
}

/* At start of day, get a pointer to Xenstore, and also bind an 
   event channel */
CAMLprim value
stub_xenstore_init(value unit)
{
	CAMLparam1(unit);
	CAMLlocal1(result);
        int err;

	result = caml_alloc(sizeof(struct mmap_interface), Abstract_tag);

        GET_C_STRUCT(result)->len = 4096;
        GET_C_STRUCT(result)->addr = mfn_to_virt(start_info.store_mfn);

        err = bind_evtchn(start_info.store_evtchn, caml_evtchn_handler, NULL);
        unmask_evtchn(start_info.store_evtchn);
	CAMLreturn(result);
}

CAMLprim value
stub_xenstore_evtchn_port(value unit)
{
        CAMLparam1(unit);
        CAMLreturn(Val_int(start_info.store_evtchn));
}

CAMLprim value
stub_xenstore_evtchn_notify(value unit)
{
        CAMLparam1(unit);
        notify_remote_via_evtchn(start_info.store_evtchn);
        CAMLreturn(Val_unit);
}

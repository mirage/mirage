/*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
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
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <os.h>

#define __XEN_TOOLS__

//#include <xenctrl.h>
#define u32 uint32_t
#include <xen/io/xs_wire.h>
#include <xen/io/ring.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/callback.h>

#include "mmap_stubs.h"

#define GET_C_STRUCT(a) ((struct mmap_interface *) a)

static int xs_ring_read(struct mmap_interface *interface,
                             char *buffer, int len)
{
	struct xenstore_domain_interface *intf = (void *)interface->addr;
	XENSTORE_RING_IDX cons, prod;
	int to_read;

	cons = intf->rsp_cons;
	prod = intf->rsp_prod;
	mb();
	if (prod == cons)
		return 0;
        printk("xs_ring_read: start\n");
	if (MASK_XENSTORE_IDX(prod) > MASK_XENSTORE_IDX(cons)) 
		to_read = prod - cons;
	else
		to_read = XENSTORE_RING_SIZE - MASK_XENSTORE_IDX(cons);
	if (to_read < len)
		len = to_read;
	memcpy(buffer, intf->rsp + MASK_XENSTORE_IDX(cons), len);
	mb();
	intf->rsp_cons += len;
        printk("xs_ring_read: done %d\n", len);
	return len;
}

static int xs_ring_write(struct mmap_interface *interface,
                              char *buffer, int len)
{
	struct xenstore_domain_interface *intf = interface->addr;
	XENSTORE_RING_IDX cons, prod;
	int can_write;

	cons = intf->req_cons;
	prod = intf->req_prod;
	mb();
	if ( (prod - cons) >= XENSTORE_RING_SIZE )
		return 0;
        printk("xs_ring_write\n");
	if (MASK_XENSTORE_IDX(prod) >= MASK_XENSTORE_IDX(cons))
		can_write = XENSTORE_RING_SIZE - MASK_XENSTORE_IDX(prod);
	else 
		can_write = MASK_XENSTORE_IDX(cons) - MASK_XENSTORE_IDX(prod);
	if (can_write < len)
		len = can_write;
	memcpy(intf->req + MASK_XENSTORE_IDX(prod), buffer, len);
	mb();
	intf->req_prod += len;
        printk("xs_ring_write: len=%d done\n", len);
	return len;
}

CAMLprim value ml_interface_read(value interface, value buffer, value len)
{
	CAMLparam3(interface, buffer, len);
	CAMLlocal1(result);
	int res;

	res = xs_ring_read(GET_C_STRUCT(interface),
	                   String_val(buffer), Int_val(len));
	if (res == -1)
		caml_failwith("huh");
	result = Val_int(res);
	CAMLreturn(result);
}

CAMLprim value ml_interface_write(value interface, value buffer, value len)
{
	CAMLparam3(interface, buffer, len);
	CAMLlocal1(result);
	int res;

	res = xs_ring_write(GET_C_STRUCT(interface),
	                    String_val(buffer), Int_val(len));
	result = Val_int(res);
	CAMLreturn(result);
}

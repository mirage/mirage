/*
 * Copyright (C) Citrix Systems Inc.
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

#include <caml/mlvalues.h>
#include <caml/memory.h>

static unsigned int reasons[] = {
  SHUTDOWN_poweroff,
  SHUTDOWN_reboot,
  SHUTDOWN_suspend,
  SHUTDOWN_crash
};

CAMLprim value
stub_sched_shutdown(value v_reason)
{
    CAMLparam1(v_reason);
    struct sched_shutdown sched_shutdown = { .reason = reasons[Int_val(v_reason)] };
    HYPERVISOR_sched_op(SCHEDOP_shutdown, &sched_shutdown);
    CAMLreturn(Val_unit);
}


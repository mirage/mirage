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

shared_info_t *map_shared_info(unsigned long pa);
void unmap_shared_info();
void init_time();
void arch_rebuild_p2m();
void setup_xen_features(void);
void init_events(void);

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

CAMLprim value
stub_hypervisor_suspend(value unit)
{
  CAMLparam0();
  int cancelled;

  /* Turn the store and console mfns to pfns - required because xc_domain_restore uses these values */
  xen_info->store_mfn = mfn_to_pfn(xen_info->store_mfn);
  xen_info->console.domU.mfn = mfn_to_pfn(xen_info->console.domU.mfn);

  /* canonicalize_pagetables can't cope with pagetable entries that are outside of the guest's mfns,
     so we must unmap anything outside of our space */
  unmap_shared_info();

  /* Actually do the suspend. When this function returns 0, we've been resumed */
  cancelled = HYPERVISOR_suspend(virt_to_mfn(xen_info));

  if(cancelled) {
    xen_info->store_mfn = pfn_to_mfn(xen_info->store_mfn);
    xen_info->console.domU.mfn = pfn_to_mfn(xen_info->console.domU.mfn);
  }

  /* Reinitialise several things */
  trap_init();
  init_events();
  setup_xen_features();
  HYPERVISOR_shared_info = map_shared_info(start_info.shared_info);
  init_time();
  arch_rebuild_p2m();

  CAMLreturn(Val_int(cancelled));
}

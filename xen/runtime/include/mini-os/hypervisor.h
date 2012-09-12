/******************************************************************************
 * hypervisor.h
 * 
 * Hypervisor handling.
 * 
 *
 * Copyright (c) 2002, K A Fraser
 * Copyright (c) 2005, Grzegorz Milos
 * Updates: Aravindh Puthiyaparambil <aravindh.puthiyaparambil@unisys.com>
 * Updates: Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com> for ia64
 */

#ifndef _HYPERVISOR_H_
#define _HYPERVISOR_H_

#include <mini-os/types.h>
#include <xen/xen.h>
#include <mini-os/x86/hypercall-x86_64.h>
#include <mini-os/x86/traps.h>

extern start_info_t *xen_info;
#define start_info (*xen_info)

/* hypervisor.c */
void force_evtchn_callback(void);
void do_hypervisor_callback(struct pt_regs *regs);
void mask_evtchn(uint32_t port);
void unmask_evtchn(uint32_t port);
void clear_evtchn(uint32_t port);

extern int in_callback;

#endif /* __HYPERVISOR_H__ */

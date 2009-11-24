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
#if defined(__i386__)
#include <hypercall-x86_32.h>
#elif defined(__x86_64__)
#include <hypercall-x86_64.h>
#elif defined(__ia64__)
#include <hypercall-ia64.h>
#else
#error "Unsupported architecture"
#endif
#include <mini-os/traps.h>

/*
 * a placeholder for the start of day information passed up from the hypervisor
 */
union start_info_union
{
    start_info_t start_info;
    char padding[512];
};
extern union start_info_union start_info_union;
#define start_info (start_info_union.start_info)

/* hypervisor.c */
void force_evtchn_callback(void);
void do_hypervisor_callback(struct pt_regs *regs);
void mask_evtchn(uint32_t port);
void unmask_evtchn(uint32_t port);
void clear_evtchn(uint32_t port);

extern int in_callback;

#endif /* __HYPERVISOR_H__ */

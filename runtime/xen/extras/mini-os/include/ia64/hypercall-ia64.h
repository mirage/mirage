/******************************************************************************
 * hypercall.h
 * 
 * Mini-OS-specific hypervisor handling for ia64.
 * 
 * Copyright (c) 2002-2004, K A Fraser
 * Changes: Dietmar Hahn <dietmar.hahn@fujiti-siemens.com>
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 2
 * as published by the Free Software Foundation; or, when distributed
 * separately from the Linux kernel or incorporated into other
 * software packages, subject to the following license:
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this source file (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

#ifndef __HYPERCALL_H__
#define __HYPERCALL_H__

#include <xen/event_channel.h>
#include <xen/sched.h>
#include <xen/version.h>

#ifndef _HYPERVISOR_H_
# error "please don't include this file directly"
#endif

// See linux/compiler.h
#define likely(x)       __builtin_expect(!!(x), 1)
#define unlikely(x)     __builtin_expect(!!(x), 0)

extern unsigned long __hypercall(unsigned long a1, unsigned long a2,
                                 unsigned long a3, unsigned long a4,
                                 unsigned long a5, unsigned long cmd);
/*
 * Assembler stubs for hyper-calls.
 */

#define _hypercall0(type, name)					\
({								\
	long __res;						\
	__res = __hypercall(0, 0, 0, 0, 0,			\
			    __HYPERVISOR_##name);		\
	(type)__res;						\
})

#define _hypercall1(type, name, a1)				\
({								\
	long __res;						\
	__res = __hypercall((unsigned long)a1,			\
			    0, 0, 0, 0, __HYPERVISOR_##name);	\
	(type)__res;						\
})

#define _hypercall2(type, name, a1, a2)				\
({								\
	long __res;						\
	__res = __hypercall((unsigned long)a1,			\
			    (unsigned long)a2,			\
			    0, 0, 0, __HYPERVISOR_##name);	\
	(type)__res;						\
})

#define _hypercall3(type, name, a1, a2, a3)			\
({								\
	long __res;						\
	__res = __hypercall((unsigned long)a1,			\
			    (unsigned long)a2,			\
			    (unsigned long)a3,			\
			    0, 0, __HYPERVISOR_##name);		\
	(type)__res;						\
})

#define _hypercall4(type, name, a1, a2, a3, a4)			\
({								\
	long __res;						\
	__res = __hypercall((unsigned long)a1,			\
			    (unsigned long)a2,			\
			    (unsigned long)a3,			\
			    (unsigned long)a4,			\
			    0, __HYPERVISOR_##name);		\
	(type)__res;						\
})

#define _hypercall5(type, name, a1, a2, a3, a4, a5)		\
({								\
	long __res;						\
	__res = __hypercall((unsigned long)a1,			\
			    (unsigned long)a2,			\
			    (unsigned long)a3,			\
			    (unsigned long)a4,			\
			    (unsigned long)a5,			\
			    __HYPERVISOR_##name);		\
	(type)__res;						\
})


int HYPERVISOR_event_channel_op(int cmd, void *arg);

int HYPERVISOR_xen_version(int cmd, void *arg);

int HYPERVISOR_console_io(int cmd, int count, char *str);

int HYPERVISOR_sched_op_compat(int cmd, unsigned long arg);

int HYPERVISOR_sched_op(int cmd, void *arg);

int HYPERVISOR_callback_op(int cmd, void *arg);

int HYPERVISOR_grant_table_op(unsigned int cmd, void *uop, unsigned int count);

int HYPERVISOR_opt_feature(void *arg);

int HYPERVISOR_suspend(unsigned long srec);

int HYPERVISOR_shutdown(unsigned int reason);

#endif /* __HYPERCALL_H__ */

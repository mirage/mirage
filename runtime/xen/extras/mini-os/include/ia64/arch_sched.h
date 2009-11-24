/*
 * Copyright (c) 2006 Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 * All rights reserved.
 *
 * The file contains ia64 specific scheduler declarations.
 *
 ****************************************************************************
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 * DEALINGS IN THE SOFTWARE.
 */

#ifndef __ARCH_SCHED_H__
#define __ARCH_SCHED_H__

#include "os.h"

struct thread;				/* Only declaration */

struct thread_regs
{
	unsigned long	unat_b;		/* NaT before spilling */
	unsigned long	sp;
	unsigned long	rp;
	unsigned long	pr;
	unsigned long	bsp;
	unsigned long	pfs;
	unsigned long	rnat;
	unsigned long	lc;

	unsigned long	unat_a;		/* NaT after spilling. */
	unsigned long	r4;
	unsigned long	r5;
	unsigned long	r6;
	unsigned long	r7;

	unsigned long	b1;
	unsigned long	b2;
	unsigned long	b3;
	unsigned long	b4;
	unsigned long	b5;

	ia64_fpreg_t	f2;
	ia64_fpreg_t	f3;
	ia64_fpreg_t	f4;
	ia64_fpreg_t	f5;
	ia64_fpreg_t	f16;
	ia64_fpreg_t	f17;
	ia64_fpreg_t	f18;
	ia64_fpreg_t	f19;
	ia64_fpreg_t	f20;
	ia64_fpreg_t	f21;
	ia64_fpreg_t	f22;
	ia64_fpreg_t	f23;
	ia64_fpreg_t	f24;
	ia64_fpreg_t	f25;
	ia64_fpreg_t	f26;
	ia64_fpreg_t	f27;
	ia64_fpreg_t	f28;
	ia64_fpreg_t	f29;
	ia64_fpreg_t	f30;
	ia64_fpreg_t	f31;
};

typedef struct thread_regs thread_regs_t;

void arch_switch_threads(struct thread* prev, struct thread* next);

static inline struct thread* get_current(void)
{
	register struct thread *current asm("r13");
	return current;
}


#endif /* __ARCH_SCHED_H__ */

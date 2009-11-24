/* 
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com
 *
 * Description: ia64 specific part of the scheduler for mini-os
 *
 ****************************************************************************
 *
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


#include <mini-os/types.h>
#include <mini-os/sched.h>
#include <mini-os/lib.h>
#include <mini-os/xmalloc.h>
#include <mini-os/mm.h>

/* The function is implemented in fw.S */
extern void thread_starter(void);

void stack_walk(void)
{
    /* TODO */
}

struct thread*
arch_create_thread(char *name, void (*function)(void *), void *data)
{
	struct thread* _thread;

	_thread = (struct thread*)_xmalloc(sizeof(struct thread), 16);
	/* Allocate pages for stack, stack will be aligned */
	_thread->stack = (char *)alloc_pages(STACK_SIZE_PAGE_ORDER);
	_thread->name = name;
	memset((void*)&(_thread->regs), 0, sizeof(_thread->regs));
	_thread->regs.sp = ((uint64_t)_thread->stack) + STACK_SIZE - 16;
	_thread->regs.bsp = ((uint64_t)_thread->stack) + 0x10;
	_thread->regs.rp = FDESC_FUNC(thread_starter);
	_thread->regs.pfs = 0x82;
	_thread->regs.r4 = FDESC_FUNC(function);
	_thread->regs.r6 = (uint64_t)data;
	return _thread;
}

extern void restore_context(struct thread*);
extern int switch_context(struct thread*, struct thread*);

void
arch_switch_threads(struct thread* prev, struct thread* next)
{
	ia64_set_r13((uint64_t)next);
	switch_context(prev, next);
}

/* Everything initialised, start idle thread */
void
run_idle_thread(void)
{
	//do_busy_loop();
	ia64_set_r13((uint64_t)idle_thread);
	restore_context(idle_thread);
	printk("%s: restore_context() returned - bad!\n", __func__);
}

/* 
 ****************************************************************************
 * (C) 2005 - Grzegorz Milos - Intel Research Cambridge
 ****************************************************************************
 *
 *        File: sched.c
 *      Author: Grzegorz Milos
 *     Changes: Robert Kaiser
 *              
 *        Date: Aug 2005
 * 
 * Environment: Xen Minimal OS
 * Description: simple scheduler for Mini-Os
 *
 * The scheduler is non-preemptive (cooperative), and schedules according 
 * to Round Robin algorithm.
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

#include <mini-os/os.h>
#include <mini-os/hypervisor.h>
#include <mini-os/time.h>
#include <mini-os/mm.h>
#include <mini-os/types.h>
#include <mini-os/lib.h>
#include <mini-os/xmalloc.h>
#include <mini-os/list.h>
#include <mini-os/sched.h>
#include <mini-os/semaphore.h>


#ifdef SCHED_DEBUG
#define DEBUG(_f, _a...) \
    printk("MINI_OS(file=sched.c, line=%d) " _f "\n", __LINE__, ## _a)
#else
#define DEBUG(_f, _a...)    ((void)0)
#endif

struct thread *idle_thread = NULL;
MINIOS_LIST_HEAD(exited_threads);
static int threads_started;

struct thread *main_thread;

void inline print_runqueue(void)
{
    struct minios_list_head *it;
    struct thread *th;
    minios_list_for_each(it, &idle_thread->thread_list)
    {
        th = minios_list_entry(it, struct thread, thread_list);
        printk("   Thread \"%s\", runnable=%d\n", th->name, is_runnable(th));
    }
    printk("\n");
}

void schedule(void)
{
    struct thread *prev, *next, *thread;
    struct minios_list_head *iterator, *next_iterator;
    unsigned long flags;

    prev = current;
    local_irq_save(flags); 

    if (in_callback) {
        printk("Must not call schedule() from a callback\n");
        BUG();
    }
    if (flags) {
        printk("Must not call schedule() with IRQs disabled\n");
        BUG();
    }

    do {
        /* Examine all threads.
           Find a runnable thread, but also wake up expired ones and find the
           time when the next timeout expires, else use 10 seconds. */
        s_time_t now = NOW();
        s_time_t min_wakeup_time = now + SECONDS(10);
        next = NULL;   
        minios_list_for_each_safe(iterator, next_iterator, &idle_thread->thread_list)
        {
            thread = minios_list_entry(iterator, struct thread, thread_list);
            if (!is_runnable(thread) && thread->wakeup_time != 0LL)
            {
                if (thread->wakeup_time <= now)
                    wake(thread);
                else if (thread->wakeup_time < min_wakeup_time)
                    min_wakeup_time = thread->wakeup_time;
            }
            if(is_runnable(thread)) 
            {
                next = thread;
                /* Put this thread on the end of the list */
                minios_list_del(&thread->thread_list);
                minios_list_add_tail(&thread->thread_list, &idle_thread->thread_list);
                break;
            }
        }
        if (next)
            break;
        /* block until the next timeout expires, or for 10 secs, whichever comes first */
        block_domain(min_wakeup_time);
        /* handle pending events if any */
        force_evtchn_callback();
    } while(1);
    local_irq_restore(flags);
    /* Interrupting the switch is equivalent to having the next thread
       inturrupted at the return instruction. And therefore at safe point. */
    if(prev != next) switch_threads(prev, next);

    minios_list_for_each_safe(iterator, next_iterator, &exited_threads)
    {
        thread = minios_list_entry(iterator, struct thread, thread_list);
        if(thread != prev)
        {
            minios_list_del(&thread->thread_list);
            free_pages(thread->stack, STACK_SIZE_PAGE_ORDER);
            xfree(thread);
        }
    }
}

struct thread* create_thread(char *name, void (*function)(void *), void *data)
{
    struct thread *thread;
    unsigned long flags;
    /* Call architecture specific setup. */
    thread = arch_create_thread(name, function, data);
    /* Not runable, not exited, not sleeping */
    thread->flags = 0;
    thread->wakeup_time = 0LL;
#ifdef HAVE_LIBC
    _REENT_INIT_PTR((&thread->reent))
#endif
    set_runnable(thread);
    local_irq_save(flags);
    if(idle_thread != NULL) {
        minios_list_add_tail(&thread->thread_list, &idle_thread->thread_list); 
    } else if(function != idle_thread_fn)
    {
        printk("BUG: Not allowed to create thread before initialising scheduler.\n");
        BUG();
    }
    local_irq_restore(flags);
    return thread;
}

#ifdef HAVE_LIBC
static struct _reent callback_reent;
struct _reent *__getreent(void)
{
    struct _reent *_reent;

    if (!threads_started)
	_reent = _impure_ptr;
    else if (in_callback)
	_reent = &callback_reent;
    else
	_reent = &get_current()->reent;

#ifndef NDEBUG
#if defined(__x86_64__) || defined(__x86__)
    {
#ifdef __x86_64__
	register unsigned long sp asm ("rsp");
#else
	register unsigned long sp asm ("esp");
#endif
	if ((sp & (STACK_SIZE-1)) < STACK_SIZE / 16) {
	    static int overflowing;
	    if (!overflowing) {
		overflowing = 1;
		printk("stack overflow\n");
		BUG();
	    }
	}
    }
#endif
#endif
    return _reent;
}
#endif

void exit_thread(void)
{
    unsigned long flags;
    struct thread *thread = current;
    printk("Thread \"%s\" exited.\n", thread->name);
    local_irq_save(flags);
    /* Remove from the thread list */
    minios_list_del(&thread->thread_list);
    clear_runnable(thread);
    /* Put onto exited list */
    minios_list_add(&thread->thread_list, &exited_threads);
    local_irq_restore(flags);
    /* Schedule will free the resources */
    while(1)
    {
        schedule();
        printk("schedule() returned!  Trying again\n");
    }
}

void block(struct thread *thread)
{
    thread->wakeup_time = 0LL;
    clear_runnable(thread);
}

void msleep(uint32_t millisecs)
{
    struct thread *thread = get_current();
    thread->wakeup_time = NOW()  + MILLISECS(millisecs);
    clear_runnable(thread);
    schedule();
}

void wake(struct thread *thread)
{
    thread->wakeup_time = 0LL;
    set_runnable(thread);
}

void idle_thread_fn(void *unused)
{
    threads_started = 1;
    while (1) {
        block(current);
        schedule();
    }
}

DECLARE_MUTEX(mutex);

void th_f1(void *data)
{
    struct timeval tv1, tv2;

    for(;;)
    {
        down(&mutex);
        printk("Thread \"%s\" got semaphore, runnable %d\n", current->name, is_runnable(current));
        schedule();
        printk("Thread \"%s\" releases the semaphore\n", current->name);
        up(&mutex);
        
        
        gettimeofday(&tv1, NULL);
        for(;;)
        {
            gettimeofday(&tv2, NULL);
            if(tv2.tv_sec - tv1.tv_sec > 2) break;
        }
                
        
        schedule(); 
    }
}

void th_f2(void *data)
{
    for(;;)
    {
        printk("Thread OTHER executing, data 0x%lx\n", data);
        schedule();
    }
}



void init_sched(void)
{
    printk("Initialising scheduler\n");

#ifdef HAVE_LIBC
    _REENT_INIT_PTR((&callback_reent))
#endif
    idle_thread = create_thread("Idle", idle_thread_fn, NULL);
    MINIOS_INIT_LIST_HEAD(&idle_thread->thread_list);
}


#ifndef __SCHED_H__
#define __SCHED_H__

#include <mini-os/list.h>
#include <mini-os/time.h>
#include <mini-os/arch_sched.h>
#ifdef HAVE_LIBC
#include <sys/reent.h>
#endif

struct thread
{
    char *name;
    char *stack;
#if !defined(__ia64__)
    /* keep in that order */
    unsigned long sp;  /* Stack pointer */
    unsigned long ip;  /* Instruction pointer */
#else /* !defined(__ia64__) */
    thread_regs_t regs;
#endif /* !defined(__ia64__) */
    struct minios_list_head thread_list;
    uint32_t flags;
    s_time_t wakeup_time;
#ifdef HAVE_LIBC
    struct _reent reent;
#endif
};

extern struct thread *idle_thread;
void idle_thread_fn(void *unused);

#define RUNNABLE_FLAG   0x00000001

#define is_runnable(_thread)    (_thread->flags & RUNNABLE_FLAG)
#define set_runnable(_thread)   (_thread->flags |= RUNNABLE_FLAG)
#define clear_runnable(_thread) (_thread->flags &= ~RUNNABLE_FLAG)

#define switch_threads(prev, next) arch_switch_threads(prev, next)
 
    /* Architecture specific setup of thread creation. */
struct thread* arch_create_thread(char *name, void (*function)(void *),
                                  void *data);

void init_sched(void);
void run_idle_thread(void);
struct thread* create_thread(char *name, void (*function)(void *), void *data);
void exit_thread(void) __attribute__((noreturn));
void schedule(void);

#ifdef __INSIDE_MINIOS__
#define current get_current()
#endif

void wake(struct thread *thread);
void block(struct thread *thread);
void msleep(uint32_t millisecs);

#endif /* __SCHED_H__ */

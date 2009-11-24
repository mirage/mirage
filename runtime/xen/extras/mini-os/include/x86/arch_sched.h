
#ifndef __ARCH_SCHED_H__
#define __ARCH_SCHED_H__

#include "arch_limits.h"

static inline struct thread* get_current(void)
{
    struct thread **current;
#ifdef __i386__    
    register unsigned long sp asm("esp");
#else
    register unsigned long sp asm("rsp");
#endif 
    current = (void *)(unsigned long)(sp & ~(__STACK_SIZE-1));
    return *current;
}

extern void __arch_switch_threads(unsigned long *prevctx, unsigned long *nextctx);

#define arch_switch_threads(prev,next) __arch_switch_threads(&(prev)->sp, &(next)->sp)


          
#endif /* __ARCH_SCHED_H__ */

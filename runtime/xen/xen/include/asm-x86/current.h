/******************************************************************************
 * current.h
 * 
 * Information structure that lives at the bottom of the per-cpu Xen stack.
 */

#ifndef __X86_CURRENT_H__
#define __X86_CURRENT_H__

#include <xen/config.h>
#include <xen/percpu.h>
#include <public/xen.h>
#include <asm/page.h>

struct vcpu;

struct cpu_info {
    struct cpu_user_regs guest_cpu_user_regs;
    unsigned int         processor_id;
    struct vcpu         *current_vcpu;
};

static inline struct cpu_info *get_cpu_info(void)
{
    struct cpu_info *cpu_info;
    __asm__ ( "and %%"__OP"sp,%0; or %2,%0"
              : "=r" (cpu_info)
              : "0" (~(STACK_SIZE-1)), "i" (STACK_SIZE-sizeof(struct cpu_info))
        );
    return cpu_info;
}

#define get_current()         (get_cpu_info()->current_vcpu)
#define set_current(vcpu)     (get_cpu_info()->current_vcpu = (vcpu))
#define current               (get_current())

#define get_processor_id()    (get_cpu_info()->processor_id)
#define set_processor_id(id)  (get_cpu_info()->processor_id = (id))

#define guest_cpu_user_regs() (&get_cpu_info()->guest_cpu_user_regs)

/*
 * Get the bottom-of-stack, as stored in the per-CPU TSS. This actually points
 * into the middle of cpu_info.guest_cpu_user_regs, at the section that
 * precisely corresponds to a CPU trap frame.
 */
#define get_stack_bottom()                      \
    ((unsigned long)&get_cpu_info()->guest_cpu_user_regs.es)

#define reset_stack_and_jump(__fn)              \
    __asm__ __volatile__ (                      \
        "mov %0,%%"__OP"sp; jmp "STR(__fn)      \
        : : "r" (guest_cpu_user_regs()) : "memory" )

#define schedule_tail(vcpu) (((vcpu)->arch.schedule_tail)(vcpu))

/*
 * Which VCPU's state is currently running on each CPU?
 * This is not necesasrily the same as 'current' as a CPU may be
 * executing a lazy state switch.
 */
DECLARE_PER_CPU(struct vcpu *, curr_vcpu);

#endif /* __X86_CURRENT_H__ */

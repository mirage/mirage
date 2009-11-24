/******************************************************************************
 * asm/debugger.h
 * 
 * Generic hooks into arch-dependent Xen.
 * 
 * Each debugger should define two functions here:
 * 
 * 1. debugger_trap_entry(): 
 *  Called at start of any synchronous fault or trap, before any other work
 *  is done. The idea is that if your debugger deliberately caused the trap
 *  (e.g. to implement breakpoints or data watchpoints) then you can take
 *  appropriate action and return a non-zero value to cause early exit from
 *  the trap function.
 * 
 * 2. debugger_trap_fatal():
 *  Called when Xen is about to give up and crash. Typically you will use this
 *  hook to drop into a debug session. It can also be used to hook off
 *  deliberately caused traps (which you then handle and return non-zero)
 *  but really these should be hooked off 'debugger_trap_entry'.
 */

#ifndef __ASM_DEBUGGER_H__
#define __ASM_DEBUGGER_H__

// this number is an arbitary number which is not used for any other purpose
// __builtin_trap() 0x0
// ski  0x80001, 0x80002
// kdb  0x80100, 0x80101
// kprobe 0x80200, jprobe 0x80300
// kgdb 0x6665
// gdb 0x99998 (#define IA64_BREAKPOINT 0x00003333300LL)
// ltrace 0x80001 (NOTE: this conflicts ski)

// cdb should handle 0 and CDB_BREAK_NUM.
#define CDB_BREAK_NUM	0x80800


#ifndef __ASSEMBLY__

#include <xen/sched.h>
#include <xen/softirq.h>
#include <xen/gdbstub.h>
#include <public/arch-ia64/debug_op.h>

void show_registers(struct cpu_user_regs *regs);
void dump_stack(void);

static inline void
show_execution_state(struct cpu_user_regs *regs)
{
    show_registers(regs);
}

// NOTE: on xen struct pt_regs = struct cpu_user_regs
//       see include/asm-ia64/linux-xen/asm/ptrace.h
#ifdef CRASH_DEBUG
// crash_debug=y

extern int __trap_to_cdb(struct cpu_user_regs *r);
static inline int debugger_trap_fatal(
    unsigned int vector, struct cpu_user_regs *regs)
{
	(void)__trap_to_gdb(regs, vector);
    return 0;
}

#define ____debugger_trap_immediate(b) __asm__ __volatile__ ("break.m "#b"\n")
#define __debugger_trap_immediate(b) ____debugger_trap_immediate(b)
#define debugger_trap_immediate() __debugger_trap_immediate(CDB_BREAK_NUM)

//XXX temporal work around
#ifndef CONFIG_SMP
#define smp_send_stop()	/* nothing */
#endif

#else
static inline int debugger_trap_fatal(
    unsigned int vector, struct cpu_user_regs *regs)
{
    return 0;
}

#define debugger_trap_immediate()		((void)0)
#endif

static inline int debugger_event(unsigned long event)
{
    struct vcpu *v = current;
    struct domain *d = v->domain;

    if (unlikely (d->debugger_attached && (d->arch.debug_flags & event))) {
        d->arch.debug_event = event;
        domain_pause_for_debugger();
        return 1;
    }
    return 0;
}

static inline int debugger_kernel_event(
    struct cpu_user_regs *regs, unsigned long event)
{
    struct vcpu *v = current;
    struct domain *d = v->domain;

    if (unlikely(d->debugger_attached && (d->arch.debug_flags & event)
                 && guest_kernel_mode(regs))) {
        d->arch.debug_event = event;
        domain_pause_for_debugger();
        return 1;
    }
    return 0;
}

#endif // __ASSEMBLLY__

#endif /* __ASM_DEBUGGER_H__ */

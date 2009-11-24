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
 *  deliberately caused traps (which you then handle and return non-zero).
 *
 * 3. debugger_trap_immediate():
 *  Called if we want to drop into a debugger now.  This is essentially the
 *  same as debugger_trap_fatal, except that we use the current register state
 *  rather than the state which was in effect when we took the trap.
 *  For example: if we're dying because of an unhandled exception, we call
 *  debugger_trap_fatal; if we're dying because of a panic() we call
 *  debugger_trap_immediate().
 */

#ifndef __X86_DEBUGGER_H__
#define __X86_DEBUGGER_H__

#include <xen/sched.h>
#include <asm/regs.h>
#include <asm/processor.h>

/* The main trap handlers use these helper macros which include early bail. */
#define DEBUGGER_trap_entry(_v, _r) \
    if ( debugger_trap_entry(_v, _r) ) return;
#define DEBUGGER_trap_fatal(_v, _r) \
    if ( debugger_trap_fatal(_v, _r) ) return;

#if defined(CRASH_DEBUG)

#include <xen/gdbstub.h>

static inline int debugger_trap_fatal(
    unsigned int vector, struct cpu_user_regs *regs)
{
    int rc = __trap_to_gdb(regs, vector);
    return ((rc == 0) || (vector == TRAP_int3));
}

/* Int3 is a trivial way to gather cpu_user_regs context. */
#define debugger_trap_immediate() __asm__ __volatile__ ( "int3" );

#else

#define debugger_trap_fatal(v, r) (0)
#define debugger_trap_immediate() ((void)0)

#endif

static inline int debugger_trap_entry(
    unsigned int vector, struct cpu_user_regs *regs)
{
    struct vcpu *v = current;

    if ( guest_kernel_mode(v, regs) && v->domain->debugger_attached &&
         ((vector == TRAP_int3) || (vector == TRAP_debug)) )
    {
#ifdef XEN_GDBSX_CONFIG
        if ( vector != TRAP_debug ) /* domain pause is good enough */
            current->arch.gdbsx_vcpu_event = vector;
#endif
        domain_pause_for_debugger();
        return 1;
    }

    return 0;
}

#endif /* __X86_DEBUGGER_H__ */

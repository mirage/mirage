#ifndef __XEN_STOP_MACHINE_H__
#define __XEN_STOP_MACHINE_H__

/**
 * stop_machine_run: freeze the machine on all CPUs and run this function
 * @fn: the function to run
 * @data: the data ptr for the @fn()
 * @cpu: the cpu to run @fn() on (or any, if @cpu == NR_CPUS).
 *
 * Description: This causes every other cpu to enter a safe point, with
 * each of which disables interrupts, and finally interrupts are disabled
 * on the current CPU.  The result is that none is holding a spinlock
 * or inside any other preempt-disabled region when @fn() runs.
 *
 * This can be thought of as a very heavy write lock, equivalent to
 * grabbing every spinlock in the kernel. */
int stop_machine_run(int (*fn)(void *), void *data, unsigned int cpu);

#endif /* __XEN_STOP_MACHINE_H__ */

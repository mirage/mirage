#ifndef __XEN_SMP_H__
#define __XEN_SMP_H__

#include <xen/config.h>
#include <asm/smp.h>

/*
 * stops all CPUs but the current one:
 */
extern void smp_send_stop(void);

extern void smp_send_event_check_mask(const cpumask_t *mask);
#define smp_send_event_check_cpu(cpu) \
    smp_send_event_check_mask(cpumask_of(cpu))

/*
 * Prepare machine for booting other CPUs.
 */
extern void smp_prepare_cpus(unsigned int max_cpus);

/*
 * Bring a CPU up
 */
extern int __cpu_up(unsigned int cpunum);

/*
 * Final polishing of CPUs
 */
extern void smp_cpus_done(unsigned int max_cpus);

/*
 * Call a function on all other processors
 */
extern int smp_call_function(
    void (*func) (void *info),
    void *info,
    int wait);

/* 
 * Call a function on a selection of processors
 */
extern int on_selected_cpus(
    const cpumask_t *selected,
    void (*func) (void *info),
    void *info,
    int wait);

/*
 * Mark the boot cpu "online" so that it can call console drivers in
 * printk() and can access its per-cpu storage.
 */
void smp_prepare_boot_cpu(void);

/*
 * Call a function on all processors
 */
static inline int on_each_cpu(
    void (*func) (void *info),
    void *info,
    int wait)
{
    return on_selected_cpus(&cpu_online_map, func, info, wait);
}

#define smp_processor_id() raw_smp_processor_id()

/* No Xen contexts can be preempted by CPU hotplug. */
#define lock_cpu_hotplug() ((void)0)
#define unlock_cpu_hotplug() ((void)0)

int alloc_cpu_id(void);

#endif /* __XEN_SMP_H__ */

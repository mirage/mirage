#ifndef __ASM_SMP_H
#define __ASM_SMP_H

/*
 * We need the APIC definitions automatically as part of 'smp.h'
 */
#ifndef __ASSEMBLY__
#include <xen/config.h>
#include <xen/kernel.h>
#include <xen/cpumask.h>
#include <asm/current.h>
#endif

#ifdef CONFIG_X86_LOCAL_APIC
#ifndef __ASSEMBLY__
#include <asm/bitops.h>
#include <asm/mpspec.h>
#ifdef CONFIG_X86_IO_APIC
#include <asm/io_apic.h>
#endif
#include <asm/apic.h>
#endif
#endif

#define BAD_APICID -1U
#ifdef CONFIG_SMP
#ifndef __ASSEMBLY__

/*
 * Private routines/data
 */
 
extern void smp_alloc_memory(void);
DECLARE_PER_CPU(cpumask_t, cpu_sibling_map);
DECLARE_PER_CPU(cpumask_t, cpu_core_map);

void smp_send_nmi_allbutself(void);

void  send_IPI_mask(const cpumask_t *mask, int vector);

extern void (*mtrr_hook) (void);

#ifdef CONFIG_X86_64
extern void zap_low_mappings(void);
#else
extern void zap_low_mappings(l2_pgentry_t *base);
#endif

#define MAX_APICID 256
extern u32 x86_cpu_to_apicid[];
extern u32 cpu_2_logical_apicid[];

#define cpu_physical_id(cpu)	x86_cpu_to_apicid[cpu]

/* State of each CPU. */
#define CPU_ONLINE	0x0002	/* CPU is up */
#define CPU_DEAD	0x0004	/* CPU is dead */
DECLARE_PER_CPU(int, cpu_state);
extern spinlock_t(cpu_add_remove_lock);

#define cpu_is_offline(cpu) unlikely(!cpu_online(cpu))
extern int cpu_down(unsigned int cpu);
extern int cpu_up(unsigned int cpu);
extern void cpu_exit_clear(void);
extern void cpu_uninit(void);
extern void disable_nonboot_cpus(void);
extern void enable_nonboot_cpus(void);
int cpu_add(uint32_t apic_id, uint32_t acpi_id, uint32_t pxm);

/*
 * This function is needed by all SMP systems. It must _always_ be valid
 * from the initial startup. We map APIC_BASE very early in page_setup(),
 * so this is correct in the x86 case.
 */
#define raw_smp_processor_id() (get_processor_id())

extern cpumask_t cpu_callout_map;
extern cpumask_t cpu_callin_map;
/* cpu_possible_map declared in <xen/cpumask.h> */

/* We don't mark CPUs online until __cpu_up(), so we need another measure */
static inline int num_booting_cpus(void)
{
	return cpus_weight(cpu_callout_map);
}

#ifdef CONFIG_X86_LOCAL_APIC

static inline int hard_smp_processor_id(void)
{
	/* we don't want to mark this access volatile - bad code generation */
	return get_apic_id();
}

static __inline int logical_smp_processor_id(void)
{
	/* we don't want to mark this access volatile - bad code generation */
	return get_logical_apic_id();
}

#endif

extern int __cpu_disable(void);
extern void __cpu_die(unsigned int cpu);
#endif /* !__ASSEMBLY__ */

#else /* CONFIG_SMP */

#define cpu_physical_id(cpu)		boot_cpu_physical_apicid

#define NO_PROC_ID		0xFF		/* No processor magic marker */

#endif
#endif

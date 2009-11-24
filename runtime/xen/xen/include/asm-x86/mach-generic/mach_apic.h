#ifndef __ASM_MACH_APIC_H
#define __ASM_MACH_APIC_H

#include <asm/genapic.h>
#include <asm/smp.h>

/* ESR was originally disabled in Linux for NUMA-Q. Do we really need to? */
#define esr_disable (0)

/* The following are dependent on APIC delivery mode (logical vs. physical). */
#define INT_DELIVERY_MODE (genapic->int_delivery_mode)
#define INT_DEST_MODE (genapic->int_dest_mode)
#define TARGET_CPUS	  (genapic->target_cpus())
#define init_apic_ldr (genapic->init_apic_ldr)
#define clustered_apic_check (genapic->clustered_apic_check) 
#define cpu_mask_to_apicid (genapic->cpu_mask_to_apicid)
#define vector_allocation_domain(cpu) (genapic->vector_allocation_domain(cpu))

static inline void enable_apic_mode(void)
{
	/* Not needed for modern ES7000 which boot in Virtual Wire mode. */
	/*es7000_sw_apic();*/
}

#define apicid_to_node(apicid) ((int)apicid_to_node[(u32)apicid])

extern u32 bios_cpu_apicid[];

static inline int mpc_apic_id(struct mpc_config_processor *m, 
			struct mpc_config_translation *translation_record)
{
	printk("Processor #%d %d:%d APIC version %d\n",
			m->mpc_apicid,
			(m->mpc_cpufeature & CPU_FAMILY_MASK) >> 8,
			(m->mpc_cpufeature & CPU_MODEL_MASK) >> 4,
			m->mpc_apicver);
	return (m->mpc_apicid);
}

static inline void setup_portio_remap(void)
{
}

static inline int multi_timer_check(int apic, int irq)
{
	return 0;
}

extern void generic_apic_probe(void);
extern void generic_bigsmp_probe(void);

/*
 * The following functions based around phys_cpu_present_map are disabled in
 * some i386 Linux subarchitectures, and in x86_64 'cluster' genapic mode. I'm
 * really not sure why, since all local APICs should have distinct physical
 * IDs, and we need to know what they are.
 */
static inline int apic_id_registered(void)
{
	return physid_isset(get_apic_id(),
			    phys_cpu_present_map);
}

static inline physid_mask_t ioapic_phys_id_map(physid_mask_t phys_map)
{
	return phys_map;
}

static inline unsigned long check_apicid_used(physid_mask_t bitmap, int apicid)
{
	return physid_isset(apicid, bitmap);
}

static inline unsigned long check_apicid_present(int apicid)
{
	return physid_isset(apicid, phys_cpu_present_map);
}

static inline int check_phys_apicid_present(int boot_cpu_physical_apicid)
{
	return physid_isset(boot_cpu_physical_apicid, phys_cpu_present_map);
}

static inline physid_mask_t apicid_to_cpu_present(int phys_apicid)
{
	return physid_mask_of_physid(phys_apicid);
}

#endif /* __ASM_MACH_APIC_H */

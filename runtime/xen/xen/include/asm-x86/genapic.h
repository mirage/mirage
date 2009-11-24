#ifndef _ASM_GENAPIC_H
#define _ASM_GENAPIC_H 1

/*
 * Generic APIC driver interface.
 *
 * An straight forward mapping of the APIC related parts of the
 * x86 subarchitecture interface to a dynamic object.
 *
 * This is used by the "generic" x86 subarchitecture.
 *
 * Copyright 2003 Andi Kleen, SuSE Labs.
 */

struct mpc_config_translation;
struct mpc_config_bus;
struct mp_config_table;
struct mpc_config_processor;

struct genapic { 
	const char *name;
	int (*probe)(void);

	/* When one of the next two hooks returns 1 the genapic
	   is switched to this. Essentially they are additional probe 
	   functions. */
	int (*mps_oem_check)(struct mp_config_table *mpc, char *oem, 
			      char *productid);
	int (*acpi_madt_oem_check)(char *oem_id, char *oem_table_id);

	/* Interrupt delivery parameters ('physical' vs. 'logical flat'). */
	int int_delivery_mode;
	int int_dest_mode;
	void (*init_apic_ldr)(void);
	void (*clustered_apic_check)(void);
	cpumask_t (*target_cpus)(void);
	cpumask_t (*vector_allocation_domain)(int cpu);
	unsigned int (*cpu_mask_to_apicid)(cpumask_t cpumask);
	void (*send_IPI_mask)(const cpumask_t *mask, int vector);
    void (*send_IPI_self)(int vector);
};

#define APICFUNC(x) .x = x

#define APIC_INIT(aname, aprobe) \
	.name = aname, \
	.probe = aprobe, \
	APICFUNC(mps_oem_check), \
	APICFUNC(acpi_madt_oem_check)

extern const struct genapic *genapic;
extern const struct genapic apic_x2apic_phys;
extern const struct genapic apic_x2apic_cluster;

void init_apic_ldr_flat(void);
void clustered_apic_check_flat(void);
cpumask_t target_cpus_flat(void);
unsigned int cpu_mask_to_apicid_flat(cpumask_t cpumask);
void send_IPI_mask_flat(const cpumask_t *mask, int vector);
void send_IPI_self_flat(int vector);
cpumask_t vector_allocation_domain_flat(int cpu);
#define GENAPIC_FLAT \
	.int_delivery_mode = dest_LowestPrio, \
	.int_dest_mode = 1 /* logical delivery */, \
	.init_apic_ldr = init_apic_ldr_flat, \
	.clustered_apic_check = clustered_apic_check_flat, \
	.target_cpus = target_cpus_flat, \
	.vector_allocation_domain = vector_allocation_domain_flat, \
	.cpu_mask_to_apicid = cpu_mask_to_apicid_flat, \
	.send_IPI_mask = send_IPI_mask_flat, \
	.send_IPI_self = send_IPI_self_flat

void init_apic_ldr_x2apic_phys(void);
void init_apic_ldr_x2apic_cluster(void);
void clustered_apic_check_x2apic(void);
cpumask_t target_cpus_x2apic(void);
unsigned int cpu_mask_to_apicid_x2apic_phys(cpumask_t cpumask);
unsigned int cpu_mask_to_apicid_x2apic_cluster(cpumask_t cpumask);
void send_IPI_mask_x2apic_phys(const cpumask_t *mask, int vector);
void send_IPI_mask_x2apic_cluster(const cpumask_t *mask, int vector);
void send_IPI_self_x2apic(int vector);
cpumask_t vector_allocation_domain_x2apic(int cpu);
#define GENAPIC_X2APIC_PHYS \
	.int_delivery_mode = dest_Fixed, \
	.int_dest_mode = 0 /* physical delivery */, \
	.init_apic_ldr = init_apic_ldr_x2apic_phys, \
	.clustered_apic_check = clustered_apic_check_x2apic, \
	.target_cpus = target_cpus_x2apic, \
	.vector_allocation_domain = vector_allocation_domain_x2apic, \
	.cpu_mask_to_apicid = cpu_mask_to_apicid_x2apic_phys, \
	.send_IPI_mask = send_IPI_mask_x2apic_phys,       \
	.send_IPI_self = send_IPI_self_x2apic

#define GENAPIC_X2APIC_CLUSTER \
    .int_delivery_mode = dest_LowestPrio, \
    .int_dest_mode = 1 /* logical delivery */, \
    .init_apic_ldr = init_apic_ldr_x2apic_cluster, \
    .clustered_apic_check = clustered_apic_check_x2apic, \
    .target_cpus = target_cpus_x2apic, \
    .vector_allocation_domain = vector_allocation_domain_x2apic, \
    .cpu_mask_to_apicid = cpu_mask_to_apicid_x2apic_cluster, \
    .send_IPI_mask = send_IPI_mask_x2apic_cluster,       \
    .send_IPI_self = send_IPI_self_x2apic

void init_apic_ldr_phys(void);
void clustered_apic_check_phys(void);
cpumask_t target_cpus_phys(void);
unsigned int cpu_mask_to_apicid_phys(cpumask_t cpumask);
void send_IPI_mask_phys(const cpumask_t *mask, int vector);
void send_IPI_self_phys(int vector);
cpumask_t vector_allocation_domain_phys(int cpu);
#define GENAPIC_PHYS \
	.int_delivery_mode = dest_Fixed, \
	.int_dest_mode = 0 /* physical delivery */, \
	.init_apic_ldr = init_apic_ldr_phys, \
	.clustered_apic_check = clustered_apic_check_phys, \
	.target_cpus = target_cpus_phys, \
	.vector_allocation_domain = vector_allocation_domain_phys, \
	.cpu_mask_to_apicid = cpu_mask_to_apicid_phys, \
	.send_IPI_mask = send_IPI_mask_phys, \
	.send_IPI_self = send_IPI_self_phys

#endif

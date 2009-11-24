/*
 * acpi.h - ACPI Interface
 *
 * Copyright (C) 2001 Paul Diefenbaugh <paul.s.diefenbaugh@intel.com>
 *
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */

#ifndef _LINUX_ACPI_H
#define _LINUX_ACPI_H

#ifndef _LINUX
#define _LINUX
#endif

#include <xen/list.h>

#include <acpi/acpi.h>
#include <acpi/acpi_bus.h>
#include <acpi/acpi_drivers.h>
#include <asm/acpi.h>

#ifdef CONFIG_ACPI_BOOT

enum acpi_irq_model_id {
	ACPI_IRQ_MODEL_PIC = 0,
	ACPI_IRQ_MODEL_IOAPIC,
	ACPI_IRQ_MODEL_IOSAPIC,
	ACPI_IRQ_MODEL_COUNT
};

extern enum acpi_irq_model_id	acpi_irq_model;

enum acpi_madt_entry_id {
	ACPI_MADT_LAPIC = 0,
	ACPI_MADT_IOAPIC,
	ACPI_MADT_INT_SRC_OVR,
	ACPI_MADT_NMI_SRC,
	ACPI_MADT_LAPIC_NMI,
	ACPI_MADT_LAPIC_ADDR_OVR,
	ACPI_MADT_IOSAPIC,
	ACPI_MADT_LSAPIC,
	ACPI_MADT_PLAT_INT_SRC,
	ACPI_MADT_ENTRY_COUNT
};

typedef struct {
	u16			polarity:2;
	u16			trigger:2;
	u16			reserved:12;
} __attribute__ ((packed)) acpi_interrupt_flags;

struct acpi_table_lapic {
	struct acpi_subtable_header	header;
	u8			acpi_id;
	u8			id;
	struct {
		u32			enabled:1;
		u32			reserved:31;
	}			flags;
} __attribute__ ((packed));

struct acpi_table_ioapic {
	struct acpi_subtable_header	header;
	u8			id;
	u8			reserved;
	u32			address;
	u32			global_irq_base;
} __attribute__ ((packed));

struct acpi_table_int_src_ovr {
	struct acpi_subtable_header	header;
	u8			bus;
	u8			bus_irq;
	u32			global_irq;
	acpi_interrupt_flags	flags;
} __attribute__ ((packed));

struct acpi_table_nmi_src {
	struct acpi_subtable_header	header;
	acpi_interrupt_flags	flags;
	u32			global_irq;
} __attribute__ ((packed));

struct acpi_table_lapic_nmi {
	struct acpi_subtable_header	header;
	u8			acpi_id;
	acpi_interrupt_flags	flags;
	u8			lint;
} __attribute__ ((packed));

struct acpi_table_lapic_addr_ovr {
	struct acpi_subtable_header	header;
	u8			reserved[2];
	u64			address;
} __attribute__ ((packed));

struct acpi_table_iosapic {
	struct acpi_subtable_header	header;
	u8			id;
	u8			reserved;
	u32			global_irq_base;
	u64			address;
} __attribute__ ((packed));

struct acpi_table_lsapic {
	struct acpi_subtable_header	header;
	u8			acpi_id;
	u8			id;
	u8			eid;
	u8			reserved[3];
	struct {
		u32			enabled:1;
		u32			reserved:31;
	}			flags;
} __attribute__ ((packed));

struct acpi_table_plat_int_src {
	struct acpi_subtable_header	header;
	acpi_interrupt_flags	flags;
	u8			type;	/* See acpi_interrupt_type */
	u8			id;
	u8			eid;
	u8			iosapic_vector;
	u32			global_irq;
	u32			reserved;
} __attribute__ ((packed));

enum acpi_interrupt_id {
	ACPI_INTERRUPT_PMI	= 1,
	ACPI_INTERRUPT_INIT,
	ACPI_INTERRUPT_CPEI,
	ACPI_INTERRUPT_COUNT
};

#define	ACPI_SPACE_MEM		0

/*
 * Simple Boot Flags
 * http://www.microsoft.com/whdc/hwdev/resources/specs/simp_bios.mspx
 */
struct acpi_table_sbf
{
	u8 sbf_signature[4];
	u32 sbf_len;
	u8 sbf_revision;
	u8 sbf_csum;
	u8 sbf_oemid[6];
	u8 sbf_oemtable[8];
	u8 sbf_revdata[4];
	u8 sbf_creator[4];
	u8 sbf_crearev[4];
	u8 sbf_cmos;
	u8 sbf_spare[3];
} __attribute__ ((packed));

enum acpi_srat_entry_id {
	ACPI_SRAT_PROCESSOR_AFFINITY = 0,
	ACPI_SRAT_MEMORY_AFFINITY,
	ACPI_SRAT_ENTRY_COUNT
};

enum acpi_address_range_id {
	ACPI_ADDRESS_RANGE_MEMORY = 1,
	ACPI_ADDRESS_RANGE_RESERVED = 2,
	ACPI_ADDRESS_RANGE_ACPI = 3,
	ACPI_ADDRESS_RANGE_NVS	= 4,
	ACPI_ADDRESS_RANGE_COUNT
};

/* DMA Remapping Reporting Table (DMAR) */

#define DMAR_FLAGS_INTR_REMAP 0x1       /* intr remap supported */

struct acpi_dmar_entry_header {
	u16	type;
	u16	length;
} __attribute__((packed));

enum acpi_dmar_entry_type {
	ACPI_DMAR_DRHD = 0,
	ACPI_DMAR_RMRR,
	ACPI_DMAR_ATSR,
	ACPI_DMAR_RHSA,
	ACPI_DMAR_ENTRY_COUNT
};

#define DRHD_FLAGS_INCLUDE_ALL	0x1       /* drhd remaps remaining devices */
struct acpi_table_drhd {
	struct	acpi_dmar_entry_header header;
	u8	flags;
	u8	reserved;
	u16	segment;
	u64	address; /* register base address for this drhd */
} __attribute__ ((packed));

struct acpi_table_rmrr {
	struct	acpi_dmar_entry_header header;
	u16	reserved;
       u16     segment;
	u64	base_address;
	u64	end_address;
} __attribute__ ((packed));

struct acpi_table_atsr {
        struct  acpi_dmar_entry_header header;
        u8      flags;
        u8      reserved;
        u16     segment;
} __attribute__ ((packed));

struct acpi_table_rhsa {
        struct  acpi_dmar_entry_header header;
        u32     proximity_domain;
        u64     address; /* register base address for this drhd */
} __attribute__ ((packed));

enum acpi_dev_scope_type {
	ACPI_DEV_ENDPOINT=0x01,	/* PCI Endpoing device */
	ACPI_DEV_P2PBRIDGE,	/* PCI-PCI Bridge */
	ACPI_DEV_IOAPIC,	/* IOAPIC device*/
	ACPI_DEV_MSI_HPET,	/* MSI capable HPET*/
	ACPI_DEV_ENTRY_COUNT
};

struct acpi_dev_scope {
	u8	dev_type;
	u8	length;
	u8	reserved[2];
	u8	enum_id;
	u8	start_bus;
} __attribute__((packed));

struct acpi_pci_path {
	u8	dev;
	u8	fn;
} __attribute__((packed));

typedef int (*acpi_madt_entry_handler) (struct acpi_subtable_header *header, const unsigned long end);

typedef int (*acpi_table_handler) (struct acpi_table_header *table);

typedef int (*acpi_table_entry_handler) (struct acpi_subtable_header *header, const unsigned long end);

unsigned int acpi_get_processor_id (unsigned int cpu);
char * __acpi_map_table (unsigned long phys_addr, unsigned long size);
int acpi_boot_init (void);
int acpi_boot_table_init (void);
int acpi_numa_init (void);

int acpi_table_init (void);
int acpi_table_parse(char *id, acpi_table_handler handler);
int acpi_table_parse_entries(char *id, unsigned long table_size,
	int entry_id, acpi_table_entry_handler handler, unsigned int max_entries);
int acpi_table_parse_madt(enum acpi_madt_type id, acpi_table_entry_handler handler, unsigned int max_entries);
int acpi_table_parse_srat(enum acpi_srat_entry_id id,
	acpi_madt_entry_handler handler, unsigned int max_entries);
int acpi_parse_srat(struct acpi_table_header *);
void acpi_table_print (struct acpi_table_header *header, unsigned long phys_addr);
void acpi_table_print_madt_entry (struct acpi_subtable_header *madt);
void acpi_table_print_srat_entry (struct acpi_subtable_header *srat);

/* the following four functions are architecture-dependent */
void acpi_numa_slit_init (struct acpi_table_slit *slit);
void acpi_numa_processor_affinity_init (struct acpi_srat_cpu_affinity *pa);
void acpi_numa_memory_affinity_init (struct acpi_srat_mem_affinity *ma);
void acpi_numa_arch_fixup(void);

#ifdef CONFIG_ACPI_HOTPLUG_CPU
/* Arch dependent functions for cpu hotplug support */
int acpi_map_lsapic(acpi_handle handle, int *pcpu);
int acpi_unmap_lsapic(int cpu);
#endif /* CONFIG_ACPI_HOTPLUG_CPU */

extern int acpi_mp_config;

extern u32 pci_mmcfg_base_addr;

extern int sbf_port ;

#else	/*!CONFIG_ACPI_BOOT*/

#define acpi_mp_config	0

static inline int acpi_boot_init(void)
{
	return 0;
}

static inline int acpi_boot_table_init(void)
{
	return 0;
}

#endif 	/*!CONFIG_ACPI_BOOT*/

unsigned int acpi_register_gsi (u32 gsi, int edge_level, int active_high_low);
int acpi_gsi_to_irq (u32 gsi, unsigned int *irq);

/*
 * This function undoes the effect of one call to acpi_register_gsi().
 * If this matches the last registration, any IRQ resources for gsi
 * are freed.
 */
#ifdef CONFIG_ACPI_DEALLOCATE_IRQ
void acpi_unregister_gsi (u32 gsi);
#endif

#ifdef CONFIG_ACPI_PCI

struct acpi_prt_entry {
	struct list_head	node;
	struct acpi_pci_id	id;
	u8			pin;
	struct {
		acpi_handle		handle;
		u32			index;
	}			link;
	u32			irq;
};

struct acpi_prt_list {
	int			count;
	struct list_head	entries;
};

extern struct acpi_prt_list	acpi_prt;

struct pci_dev;

int acpi_pci_irq_enable (struct pci_dev *dev);
void acpi_penalize_isa_irq(int irq);

#ifdef CONFIG_ACPI_DEALLOCATE_IRQ
void acpi_pci_irq_disable (struct pci_dev *dev);
#endif

struct acpi_pci_driver {
	struct acpi_pci_driver *next;
	int (*add)(acpi_handle handle);
	void (*remove)(acpi_handle handle);
};

int acpi_pci_register_driver(struct acpi_pci_driver *driver);
void acpi_pci_unregister_driver(struct acpi_pci_driver *driver);

#endif /*CONFIG_ACPI_PCI*/

#ifdef CONFIG_ACPI_EC

extern int ec_read(u8 addr, u8 *val);
extern int ec_write(u8 addr, u8 val);

#endif /*CONFIG_ACPI_EC*/

#ifdef CONFIG_ACPI_INTERPRETER

extern int acpi_blacklisted(void);
extern void acpi_bios_year(char *s);

#else /*!CONFIG_ACPI_INTERPRETER*/

static inline int acpi_blacklisted(void)
{
	return 0;
}

#endif /*!CONFIG_ACPI_INTERPRETER*/

#ifdef	CONFIG_ACPI_CSTATE
/*
 * Set highest legal C-state
 * 0: C0 okay, but not C1
 * 1: C1 okay, but not C2
 * 2: C2 okay, but not C3 etc.
 */

extern unsigned int max_cstate;

static inline unsigned int acpi_get_cstate_limit(void)
{
	return max_cstate;
}
static inline void acpi_set_cstate_limit(unsigned int new_limit)
{
	max_cstate = new_limit;
	return;
}
#else
static inline unsigned int acpi_get_cstate_limit(void) { return 0; }
static inline void acpi_set_cstate_limit(unsigned int new_limit) { return; }
#endif

#ifdef CONFIG_ACPI_NUMA
int acpi_get_pxm(acpi_handle handle);
#else
static inline int acpi_get_pxm(acpi_handle handle)
{
	return 0;
}
#endif

extern int pnpacpi_disabled;

void acpi_reboot(void);

#endif /*_LINUX_ACPI_H*/

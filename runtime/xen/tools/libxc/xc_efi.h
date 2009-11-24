#ifndef XC_EFI_H
#define XC_EFI_H

/* definitions from xen/include/asm-ia64/linux-xen/linux/efi.h */

/*
 * Extensible Firmware Interface
 * Based on 'Extensible Firmware Interface Specification' version 0.9, April 30, 1999
 *
 * Copyright (C) 1999 VA Linux Systems
 * Copyright (C) 1999 Walt Drummond <drummond@valinux.com>
 * Copyright (C) 1999, 2002-2003 Hewlett-Packard Co.
 *      David Mosberger-Tang <davidm@hpl.hp.com>
 *      Stephane Eranian <eranian@hpl.hp.com>
 */

typedef struct {
        uint8_t b[16];
} efi_guid_t;

#define EFI_GUID(a,b,c,d0,d1,d2,d3,d4,d5,d6,d7) \
((efi_guid_t) \
{{ (a) & 0xff, ((a) >> 8) & 0xff, ((a) >> 16) & 0xff, ((a) >> 24) & 0xff, \
  (b) & 0xff, ((b) >> 8) & 0xff, \
  (c) & 0xff, ((c) >> 8) & 0xff, \
  (d0), (d1), (d2), (d3), (d4), (d5), (d6), (d7) }})

/*
 * Generic EFI table header
 */
typedef struct {
	uint64_t signature;
	uint32_t revision;
	uint32_t headersize;
	uint32_t crc32;
	uint32_t reserved;
} efi_table_hdr_t;

/*
 * Memory map descriptor:
 */

/* Memory types: */
#define EFI_RESERVED_TYPE                0
#define EFI_LOADER_CODE                  1
#define EFI_LOADER_DATA                  2
#define EFI_BOOT_SERVICES_CODE           3
#define EFI_BOOT_SERVICES_DATA           4
#define EFI_RUNTIME_SERVICES_CODE        5
#define EFI_RUNTIME_SERVICES_DATA        6
#define EFI_CONVENTIONAL_MEMORY          7
#define EFI_UNUSABLE_MEMORY              8
#define EFI_ACPI_RECLAIM_MEMORY          9
#define EFI_ACPI_MEMORY_NVS             10
#define EFI_MEMORY_MAPPED_IO            11
#define EFI_MEMORY_MAPPED_IO_PORT_SPACE 12
#define EFI_PAL_CODE                    13
#define EFI_MAX_MEMORY_TYPE             14

/* Attribute values: */
#define EFI_MEMORY_UC           ((uint64_t)0x0000000000000001ULL)    /* uncached */
#define EFI_MEMORY_WC           ((uint64_t)0x0000000000000002ULL)    /* write-coalescing */
#define EFI_MEMORY_WT           ((uint64_t)0x0000000000000004ULL)    /* write-through */
#define EFI_MEMORY_WB           ((uint64_t)0x0000000000000008ULL)    /* write-back */
#define EFI_MEMORY_WP           ((uint64_t)0x0000000000001000ULL)    /* write-protect */
#define EFI_MEMORY_RP           ((uint64_t)0x0000000000002000ULL)    /* read-protect */
#define EFI_MEMORY_XP           ((uint64_t)0x0000000000004000ULL)    /* execute-protect */
#define EFI_MEMORY_RUNTIME      ((uint64_t)0x8000000000000000ULL)    /* range requires runtime mapping */
#define EFI_MEMORY_DESCRIPTOR_VERSION   1

#define EFI_PAGE_SHIFT          12

/*
 * For current x86 implementations of EFI, there is
 * additional padding in the mem descriptors.  This is not
 * the case in ia64.  Need to have this fixed in the f/w.
 */
typedef struct {
        uint32_t type;
        uint32_t pad;
        uint64_t phys_addr;
        uint64_t virt_addr;
        uint64_t num_pages;
        uint64_t attribute;
#if defined (__i386__)
        uint64_t pad1;
#endif
} efi_memory_desc_t;

/*
 * EFI Runtime Services table
 */
#define EFI_RUNTIME_SERVICES_SIGNATURE	((uint64_t)0x5652453544e5552ULL)
#define EFI_RUNTIME_SERVICES_REVISION	0x00010000

typedef struct {
	efi_table_hdr_t hdr;
	unsigned long get_time;
	unsigned long set_time;
	unsigned long get_wakeup_time;
	unsigned long set_wakeup_time;
	unsigned long set_virtual_address_map;
	unsigned long convert_pointer;
	unsigned long get_variable;
	unsigned long get_next_variable;
	unsigned long set_variable;
	unsigned long get_next_high_mono_count;
	unsigned long reset_system;
} efi_runtime_services_t;

/*
 *  EFI Configuration Table and GUID definitions
 */
#define NULL_GUID \
    EFI_GUID(  0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 )
#define ACPI_20_TABLE_GUID    \
    EFI_GUID(  0x8868e871, 0xe4f1, 0x11d3, 0xbc, 0x22, 0x0, 0x80, 0xc7, 0x3c, 0x88, 0x81 )
#define SAL_SYSTEM_TABLE_GUID    \
    EFI_GUID(  0xeb9d2d32, 0x2d88, 0x11d3, 0x9a, 0x16, 0x0, 0x90, 0x27, 0x3f, 0xc1, 0x4d )

typedef struct {
	efi_guid_t guid;
	unsigned long table;
} efi_config_table_t;

#define EFI_SYSTEM_TABLE_SIGNATURE ((uint64_t)0x5453595320494249ULL)
#define EFI_SYSTEM_TABLE_REVISION  ((1 << 16) | 00)

typedef struct {
	efi_table_hdr_t hdr;
	unsigned long fw_vendor;	/* physical addr of CHAR16 vendor string */
	uint32_t fw_revision;
	unsigned long con_in_handle;
	unsigned long con_in;
	unsigned long con_out_handle;
	unsigned long con_out;
	unsigned long stderr_handle;
	unsigned long stderr;
	efi_runtime_services_t *runtime;
	unsigned long boottime;
	unsigned long nr_tables;
	unsigned long tables;
} efi_system_table_t;

#endif /* XC_EFI_H */

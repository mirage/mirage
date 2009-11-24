/*
 * This is a short summary of declarations and definitions from different
 * efi header files of Intels' EFI_Toolkit_1.10.14.62 
 * used for the minimal implementation in mini-os.
 * Changes: Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 *
 ****************************************************************************
 * Copyright (C) 2001-2004, Intel Corporation.
 * THIS SPECIFICATION IS PROVIDED "AS IS" WITH NO WARRANTIES WHATSOEVER,
 * INCLUDING ANY WARRANTY OF MERCHANTABILITY, NONINFRINGEMENT, FITNESS FOR
 * ANY PARTICULAR PURPOSE, OR ANY WARRANTY OTHERWISE ARISING OUT OF ANY
 * PROPOSAL, SPECIFICATION OR SAMPLE. Except for a limited copyright license
 * to copy this specification for internal use only, no license, express or
 * implied, by estoppel or otherwise, to any intellectual property rights is
 * granted herein.  Intel disclaims all liability, including liability for
 * infringement of any proprietary rights, relating to implementation of
 * information in this specification. Intel does not warrant or represent
 * that such implementation(s) will not infringe such rights.  Designers must
 * not rely on the absence or characteristics of any features or instructions
 * marked "reserved" or "undefined." Intel reserves these for future
 * definition and shall have no responsibility whatsoever for conflicts or
 * incompatibilities arising from future changes to them.
 * This document is an intermediate draft for comment only and is subject to
 * change without notice. Readers should not design products based on this
 * document.
 * Intel, the Intel logo, and Itanium are trademarks or registered trademarks
 * of Intel Corporation or its subsidiaries in the United States and other
 * countries.
 * Other names and brands may be claimed as the property of others.
 */

#ifndef _EFI_H_
#define _EFI_H_

#include <mini-os/types.h>


#define EFIWARN(a)                      (a)
#define EFI_ERROR(a)                    (((int64_t) a) < 0)


#define EFI_SUCCESS                     0
#define EFI_LOAD_ERROR                  EFIERR(1)
#define EFI_INVALID_PARAMETER           EFIERR(2)
#define EFI_UNSUPPORTED                 EFIERR(3)
#define EFI_BAD_BUFFER_SIZE             EFIERR(4)
#define EFI_BUFFER_TOO_SMALL            EFIERR(5)
#define EFI_NOT_READY                   EFIERR(6)
#define EFI_DEVICE_ERROR                EFIERR(7)
#define EFI_WRITE_PROTECTED             EFIERR(8)
#define EFI_OUT_OF_RESOURCES            EFIERR(9)
#define EFI_VOLUME_CORRUPTED            EFIERR(10)
#define EFI_VOLUME_FULL                 EFIERR(11)
#define EFI_NO_MEDIA                    EFIERR(12)
#define EFI_MEDIA_CHANGED               EFIERR(13)
#define EFI_NOT_FOUND                   EFIERR(14)
#define EFI_ACCESS_DENIED               EFIERR(15)
#define EFI_NO_RESPONSE                 EFIERR(16)
#define EFI_NO_MAPPING                  EFIERR(17)
#define EFI_TIMEOUT                     EFIERR(18)
#define EFI_NOT_STARTED                 EFIERR(19)
#define EFI_ALREADY_STARTED             EFIERR(20)
#define EFI_ABORTED                     EFIERR(21)
#define EFI_ICMP_ERROR                  EFIERR(22)
#define EFI_TFTP_ERROR                  EFIERR(23)
#define EFI_PROTOCOL_ERROR              EFIERR(24)

#define EFI_WARN_UNKOWN_GLYPH           EFIWARN(1)
#define EFI_WARN_DELETE_FAILURE         EFIWARN(2)
#define EFI_WARN_WRITE_FAILURE          EFIWARN(3)
#define EFI_WARN_BUFFER_TOO_SMALL       EFIWARN(4)


typedef uint64_t	efi_status_t;
typedef void*		efi_handle_t;
typedef void*		efi_event_t;
typedef uint16_t	efi_char16_t;


/*
 * Standard EFI table header
 */

struct efi_table_header
{
	uint64_t	Signature;
	// Revision of EFI table specification,
	// upper 16 bit - major revision number
	// lower 16 bit - minor revision number
	uint32_t	Revision;
	uint32_t	HeaderSize;
	uint32_t	CRC32;
	uint32_t	Reserved;
};
typedef struct efi_table_header efi_table_header_t;

/*
 * EFI Time
 */
typedef struct
{          
	uint16_t	Year;       /* 1998 - 20XX */
	uint8_t		Month;      /* 1 - 12 */
	uint8_t		Day;        /* 1 - 31 */
	uint8_t		Hour;       /* 0 - 23 */
	uint8_t		Minute;     /* 0 - 59 */
	uint8_t		Second;     /* 0 - 59 */
	uint8_t		Pad1;
	uint32_t	Nanosecond; /* 0 - 999,999,999 */
	int16_t		TimeZone;   /* -1440 to 1440 or 2047 */
	uint8_t		Daylight;
	uint8_t		Pad2;
} efi_time_t;

/* Bit definitions for efi_time_t.Daylight */
#define EFI_TIME_ADJUST_DAYLIGHT    0x01
#define EFI_TIME_IN_DAYLIGHT        0x02

/* Value definition for efi_time_t.TimeZone */
#define EFI_UNSPECIFIED_TIMEZONE    0x07FF



typedef struct
{
	uint32_t	Resolution;     /* 1e-6 parts per million */
	uint32_t	Accuracy;       /* hertz */
	uint8_t		SetsToZero;     /* Set clears sub-second time */
} efi_time_capabilities_t;


typedef efi_status_t (*efi_get_time_t) (efi_time_t*, efi_time_capabilities_t*);
typedef efi_status_t (*efi_set_time_t) (efi_time_t*);
typedef efi_status_t (*efi_get_wakeup_time_t) (uint8_t*, uint8_t*, efi_time_t*);
typedef efi_status_t (*efi_set_wakeup_time_t) (uint8_t, efi_time_t*);

/*
 * Memory
 * Preseve the attr on any range supplied.
 * ConventialMemory must have WB,SR,SW when supplied.
 * When allocating from ConventialMemory always make it WB,SR,SW
 * When returning to ConventialMemory always make it WB,SR,SW
 * When getting the memory map, or on RT for runtime types
 */

typedef enum {
	EfiReservedMemoryType,		/* 0 */
	EfiLoaderCode,
	EfiLoaderData,
	EfiBootServicesCode,
	EfiBootServicesData,
	EfiRuntimeServicesCode,
	EfiRuntimeServicesData,		/* 6 */
	EfiConventionalMemory,		/* 7 */
	EfiUnusableMemory,
	EfiACPIReclaimMemory,		/* 9 */
	EfiACPIMemoryNVS,		/* 10, a */
	EfiMemoryMappedIO,
	EfiMemoryMappedIOPortSpace,	/* 12, c */
	EfiPalCode,			/* 13, d */
	EfiMaxMemoryType		/* 14, e */
} efi_memory_type_t;

/* possible caching types for the memory range */
#define EFI_MEMORY_UC		0x0000000000000001
#define EFI_MEMORY_WC		0x0000000000000002
#define EFI_MEMORY_WT		0x0000000000000004
#define EFI_MEMORY_WB		0x0000000000000008
#define EFI_MEMORY_UCE		0x0000000000000010  
/* physical memory protection on range */
#define EFI_MEMORY_WP		0x0000000000001000
#define EFI_MEMORY_RP		0x0000000000002000
#define EFI_MEMORY_XP		0x0000000000004000
/* range requires a runtime mapping */
#define EFI_MEMORY_RUNTIME	0x8000000000000000

#define EFI_MEMORY_DESCRIPTOR_VERSION  1

typedef uint64_t efi_phys_addr_t;
typedef uint64_t efi_virt_addr_t;

typedef struct
{
	uint32_t	Type;           /* 32 bit padding */
	efi_phys_addr_t	PhysicalStart;
	efi_virt_addr_t	VirtualStart;
	uint64_t	NumberOfPages;
	uint64_t	Attribute;
} efi_memory_descriptor_t;

#define NextMemoryDescriptor(Ptr,Size)  ((efi_memory_descriptor_t*) (((uint8_t*) Ptr) + Size))


typedef efi_status_t (*efi_set_virtual_address_map_t)
	(
		uint64_t MemoryMapSize,
		uint64_t DescriptorSize,
		uint32_t DescriptorVersion,
		efi_memory_descriptor_t* VirtualMap
	);

typedef efi_status_t (*efi_convert_pointer_t)
	(
		uint64_t DebugDisposition,
		void** Address
	);

/*
 * A GUID
 */

typedef struct
{          
	uint32_t	Data1;
	uint16_t	Data2;
	uint16_t	Data3;
	uint8_t		Data4[8]; 
} efi_guid_t;

/*
 * EFI Configuration Table and GUID definitions
 */

#define MPS_TABLE_GUID			\
	{ 0xeb9d2d2f, 0x2d88, 0x11d3,	\
		{ 0x9a, 0x16, 0x0, 0x90, 0x27, 0x3f, 0xc1, 0x4d } }

#define ACPI_TABLE_GUID			\
	{ 0xeb9d2d30, 0x2d88, 0x11d3,	\
		{ 0x9a, 0x16, 0x0, 0x90, 0x27, 0x3f, 0xc1, 0x4d } }

#define ACPI_20_TABLE_GUID  \
	{ 0x8868e871, 0xe4f1, 0x11d3,	\
		{ 0xbc, 0x22, 0x0, 0x80, 0xc7, 0x3c, 0x88, 0x81 } }

#define SMBIOS_TABLE_GUID    \
	{ 0xeb9d2d31, 0x2d88, 0x11d3,	\
		{ 0x9a, 0x16, 0x0, 0x90, 0x27, 0x3f, 0xc1, 0x4d } }

#define SAL_SYSTEM_TABLE_GUID    \
	{ 0xeb9d2d32, 0x2d88, 0x11d3,	\
		{ 0x9a, 0x16, 0x0, 0x90, 0x27, 0x3f, 0xc1, 0x4d } }

/* DIG64 Headless Console & Debug Port Table. */
#define	HCDP_TABLE_GUID		\
	{0xf951938d, 0x620b, 0x42ef,	\
		{0x82, 0x79, 0xa8, 0x4b, 0x79, 0x61, 0x78, 0x98 } }


typedef struct efi_configuration_table
{
	efi_guid_t	VendorGuid;
	void*		VendorTable;
} efi_configuration_table_t;


/*
 * EFI platform variables
 */

#define EFI_GLOBAL_VARIABLE     \
    {	0x8BE4DF61, 0x93CA, 0x11d2, 0xAA, 0x0D, 0x00,	\
	0xE0, 0x98, 0x03, 0x2B, 0x8C }

/* Variable attributes */
#define EFI_VARIABLE_NON_VOLATILE           0x00000001
#define EFI_VARIABLE_BOOTSERVICE_ACCESS     0x00000002
#define EFI_VARIABLE_RUNTIME_ACCESS         0x00000004

/* Variable size limitation */
#define EFI_MAXIMUM_VARIABLE_SIZE           1024

typedef efi_status_t (*efi_get_variable_t)
	(
		efi_char16_t*	VariableName,
		efi_guid_t	*VendorGuid,
		uint32_t*	Attributes,
		uint64_t*	DataSize,
		void*		Data
	);

typedef
efi_status_t (*efi_get_next_variable_name_t)
	(
		uint64_t*	VariableNameSize,
		efi_char16_t*	VariableName,
		efi_guid_t*	VendorGuid
	);

typedef efi_status_t (*efi_set_variable_t)
	(
		efi_char16_t*	VariableName,
		efi_guid_t*	VendorGuid,
		uint32_t	Attributes,
		uint64_t	DataSize,
		void*		Data
	);

/*
 * Misc
 */

typedef enum
{
	EfiResetCold,
	EfiResetWarm,
	EfiResetShutdown
} efi_reset_type_t;


typedef efi_status_t (*efi_reset_system_t)
	(
		efi_reset_type_t	ResetType,
		efi_status_t		ResetStatus,
		uint64_t		DataSize,
		efi_char16_t*		ResetData
	);

typedef efi_status_t (*efi_get_next_high_mono_count_t) (uint32_t* HighCount);


/*
 * EFI Runtime Serivces Table
 */

#define EFI_RUNTIME_SERVICES_SIGNATURE  0x5652453544e5552ULL
#define EFI_RUNTIME_SERVICES_REVISION ((EFI_SPECIFICATION_MAJOR_REVISION<<16) \
					| (EFI_SPECIFICATION_MINOR_REVISION))

typedef struct
{
	efi_table_header_t		Hdr;
	/* Time services */
	efi_get_time_t			GetTime;
	efi_set_time_t			SetTime;
	efi_get_wakeup_time_t		GetWakeupTime;
	efi_set_wakeup_time_t		SetWakeupTime;
	/* Virtual memory services */
	efi_set_virtual_address_map_t	SetVirtualAddressMap;
	efi_convert_pointer_t		ConvertPointer;
	/* Variable serviers */
	efi_get_variable_t		GetVariable;
	efi_get_next_variable_name_t	GetNextVariableName;
	efi_set_variable_t		SetVariable;
	/* Misc */
	efi_get_next_high_mono_count_t	GetNextHighMonotonicCount;
	efi_reset_system_t		ResetSystem;

} efi_runtime_services_t;


#define EFI_SPECIFICATION_MAJOR_REVISION 1
#define EFI_SYSTEM_TABLE_SIGNATURE      0x5453595320494249
#define EFI_SYSTEM_TABLE_REVISION  ((EFI_SPECIFICATION_MAJOR_REVISION<<16) \
					| (EFI_SPECIFICATION_MINOR_REVISION))

struct efi_system_table
{
	efi_table_header_t	Hdr;

	uint64_t	FirmwareVendor;		// phys addr of CHAR16
	uint32_t	FirmwareRevision;	// Firmware vendor specific

	efi_handle_t	ConsoleInHandle;
	uint64_t	ConIn;

	efi_handle_t	ConsoleOutHandle;
	uint64_t	ConOut;

	efi_handle_t	StandardErrorHandle;
	uint64_t	StdErr;

	uint64_t	RuntimeServices;	// phys addr
	uint64_t	BootServices;		// phys addr

	uint64_t	NumberOfTableEntries;	// Number of entries in Config
	uint64_t	ConfigurationTable;	// phys addr of ConfigTable
};

typedef struct efi_system_table efi_system_table_t;


#define EFI_PAGE_SIZE   4096
#define EFI_PAGE_MASK   0xFFF
#define EFI_PAGE_SHIFT  12

#define EFI_SIZE_TO_PAGES(a)  \
    ( ((a) >> EFI_PAGE_SHIFT) + ((a) & EFI_PAGE_MASK ? 1 : 0) )


void init_efi(void);
int efi_get_time(efi_time_t* tmP);
efi_status_t ia64_call_efi_physical(void *, ...);


#endif /* _EFI_H_ */

/*
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 * The code is mostly taken from FreeBSD.
 *
 ****************************************************************************
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */


/*
 * The SAL System Table starts with a header which is described in
 * sal_system_table_t.
 * Table header will be followed by a variable number of variable length
 * entries. The first byte of each entry will identify the entry type and
 * the entries shall be in ascending order by the entry type. Each entry
 * type will have a known fixed length. The total length of this table
 * depends upon the configuration of the system. Operating system software
 * must step through each entry until it reaches the ENTRY_COUNT. The entries
 * are sorted on entry type in ascending order.
 * Unless otherwise stated, there is one entry per entry type.
 */

#ifndef _SAL_H_
#define _SAL_H_

typedef uint64_t u_int64_t;
typedef uint32_t u_int32_t;
typedef uint16_t u_int16_t;
typedef uint8_t u_int8_t;

struct sal_system_table {
	char		sal_signature[4];
#define	SAL_SIGNATURE	"SST_"
	uint32_t	sal_length;
	uint8_t		sal_rev[2];	/* Byte 8 - Minor, Byte 0 - Major */
	uint16_t	sal_entry_count;	// num entries in var part
	uint8_t		sal_checksum;
	uint8_t		sal_reserved1[7];
	uint8_t		sal_a_version[2];	// like sal_rev
	uint8_t		sal_b_version[2];	// like sal_rev
	char		sal_oem_id[32];		// Ascii - manufacturer of HW
	char		sal_product_id[32];	// ascii - identification
	uint8_t		sal_reserved2[8];
};

typedef struct sal_system_table sal_system_table_t;

#define SAL_DESC_ENTRYPOINT		0
#define SAL_DESC_ENTRYPOINT_LENGTH	48
#define SAL_DESC_MEMORY			1
#define SAL_DESC_MEMORY_LENGTH		32
#define SAL_DESC_PLATFORM		2
#define SAL_DESC_PLATFORM_LENGT		16
#define SAL_DESC_TR_REG			3
#define SAL_DESC_TR_REG_LENGTH		32
#define SAL_DESC_PURGE_TR_CACHE		4
#define SAL_DESC_PURGE_TR_CACHE_LENGTH	16
#define SAL_DESC_AP_WAKEUP		5
#define SAL_DESC_AP_WAKEUP_LENGTH	16


struct sal_entrypoint_descriptor
{
	uint8_t		sale_type;		/* == 0 */
	uint8_t		sale_reserved1[7];
	uint64_t	sale_pal_proc;		/* PAL_PROC entry point */
	uint64_t	sale_sal_proc;		/* SAL_PROC entry point */
	uint64_t	sale_sal_gp;		/* gp for SAL_PROC, PAL_PROC */
	uint8_t		sale_reserved2[16];
};

struct sal_memory_descriptor
{
	uint8_t		sale_type;	/* == 1 */
	uint8_t		sale_need_virtual;
	uint8_t		sale_current_attribute;
	uint8_t		sale_access_rights;
	uint8_t		sale_supported_attributes;
	uint8_t		sale_reserved1;
	uint8_t		sale_memory_type[2];
	uint64_t	sale_physical_address;
	uint32_t	sale_length;
	uint8_t		sale_reserved2[12];
};

struct sal_platform_descriptor
{
	uint8_t		sale_type;	/* == 2 */
	uint8_t		sale_features;
	uint8_t		sale_reserved[14];
};

struct sal_tr_descriptor
{
	u_int8_t	sale_type;	/* == 3 */
	u_int8_t	sale_register_type;
	u_int8_t	sale_register_number;
	u_int8_t	sale_reserved1[5];
	u_int64_t	sale_virtual_address;
	u_int64_t	sale_page_size;
	u_int8_t	sale_reserved2[8];
};

struct sal_ptc_cache_descriptor
{
	uint8_t		sale_type;	/* == 4 */
	uint8_t		sale_reserved[3];
	uint32_t	sale_domains;
	uint64_t	sale_address;
};

struct sal_ap_wakeup_descriptor
{
	uint8_t		sale_type;	/* == 5 */
	uint8_t		sale_mechanism;
	uint8_t		sale_reserved[6];
	uint64_t	sale_vector;
};

/*
 * SAL Procedure numbers.
 */

#define SAL_SET_VECTORS			0x01000000
#define SAL_GET_STATE_INFO		0x01000001
#define SAL_GET_STATE_INFO_SIZE		0x01000002
#define SAL_CLEAR_STATE_INFO		0x01000003
#define SAL_MC_RENDEZ			0x01000004
#define SAL_MC_SET_PARAMS		0x01000005
#define SAL_REGISTER_PHYSICAL_ADDR	0x01000006
#define SAL_CACHE_FLUSH			0x01000008
#define SAL_CACHE_INIT			0x01000009
#define SAL_PCI_CONFIG_READ		0x01000010
#define SAL_PCI_CONFIG_WRITE		0x01000011
#define SAL_FREQ_BASE			0x01000012
#define SAL_UPDATE_PAL			0x01000020

/* SAL_SET_VECTORS event handler types */
#define	SAL_OS_MCA		0
#define	SAL_OS_INIT		1
#define	SAL_OS_BOOT_RENDEZ	2

/* SAL_GET_STATE_INFO, SAL_GET_STATE_INFO_SIZE types */
#define	SAL_INFO_MCA		0
#define	SAL_INFO_INIT		1
#define	SAL_INFO_CMC		2
#define	SAL_INFO_CPE		3
#define	SAL_INFO_TYPES		4	/* number of types we know about */

struct ia64_sal_result
{
	int64_t		sal_status;
	uint64_t	sal_result[3];
};
typedef struct ia64_sal_result ia64_sal_result_t;

typedef ia64_sal_result_t sal_entry_t
	(	uint64_t, uint64_t, uint64_t, uint64_t,
	 	uint64_t, uint64_t, uint64_t, uint64_t
	);

extern ia64_sal_result_t ia64_sal_call(uint64_t, uint64_t, uint64_t, uint64_t,
	 				uint64_t, uint64_t, uint64_t, uint64_t);

extern void ia64_sal_init(sal_system_table_t *saltab);

#endif /* _SAL_H_ */

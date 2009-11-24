#ifndef XC_IA64_SAL_H
#define XC_IA64_SAL_H

/*
 * definitions from
 * xen/include/asm-ia64/linux/asm/sal.h
 */

/*
 * The SAL system table is followed by a variable number of variable
 * length descriptors.  The structure of these descriptors follows
 * below.
 * The defininition follows SAL specs from July 2000
 */
struct ia64_sal_systab {
	uint8_t signature[4];	/* should be "SST_" */
	uint32_t size;		/* size of this table in bytes */
	uint8_t sal_rev_minor;
	uint8_t sal_rev_major;
	uint16_t entry_count;	/* # of entries in variable portion */
	uint8_t checksum;
	uint8_t reserved1[7];
	uint8_t sal_a_rev_minor;
	uint8_t sal_a_rev_major;
	uint8_t sal_b_rev_minor;
	uint8_t sal_b_rev_major;
	/* oem_id & product_id: terminating NUL is missing if string is exactly 32 bytes long. */
	uint8_t oem_id[32];
	uint8_t product_id[32];	/* ASCII product id  */
	uint8_t reserved2[8];
};

enum sal_systab_entry_type {
	SAL_DESC_ENTRY_POINT = 0,
	SAL_DESC_MEMORY = 1,
	SAL_DESC_PLATFORM_FEATURE = 2,
	SAL_DESC_TR = 3,
	SAL_DESC_PTC = 4,
	SAL_DESC_AP_WAKEUP = 5
};

typedef struct ia64_sal_desc_entry_point {
	uint8_t type;
	uint8_t reserved1[7];
	uint64_t pal_proc;
	uint64_t sal_proc;
	uint64_t gp;
	uint8_t reserved2[16];
}ia64_sal_desc_entry_point_t;

#define IA64_SAL_AP_EXTERNAL_INT 0

typedef struct ia64_sal_desc_ap_wakeup {
	uint8_t type;
	uint8_t mechanism;		/* 0 == external interrupt */
	uint8_t reserved1[6];
	uint64_t vector;		/* interrupt vector in range 0x10-0xff */
} ia64_sal_desc_ap_wakeup_t ;

//XXX should move xen_sal_data to arch-ia64.h?
/* These are data in domain memory for SAL emulator.  */
struct xen_sal_data {
    /* OS boot rendez vous.  */
    unsigned long boot_rdv_ip;
    unsigned long boot_rdv_r1;

    /* There are these for EFI_SET_VIRTUAL_ADDRESS_MAP emulation. */
    int efi_virt_mode;          /* phys : 0 , virt : 1 */
};

#endif /* XC_IA64_SAL_H */

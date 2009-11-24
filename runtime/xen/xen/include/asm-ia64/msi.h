#ifndef __ASM_MSI_H
#define __ASM_MSI_H

/*
 * MSI Defined Data Structures
 */
#define MSI_ADDRESS_HEADER		0xfee
#define MSI_ADDRESS_HEADER_SHIFT	12
#define MSI_ADDRESS_HEADER_MASK		0xfff000
#define MSI_ADDRESS_DEST_ID_MASK	0xfff0000f
#define MSI_TARGET_CPU_MASK		0xff
#define MSI_TARGET_CPU_SHIFT		4
#define MSI_DELIVERY_MODE		0
#define MSI_LEVEL_MODE			1	/* Edge always assert */
#define MSI_TRIGGER_MODE		0	/* MSI is edge sensitive */
#define MSI_PHYSICAL_MODE		0
#define MSI_LOGICAL_MODE		1
#define MSI_REDIRECTION_HINT_MODE	0

#define MSI_DATA_VECTOR_SHIFT		0
#define  MSI_DATA_VECTOR_MASK		0x000000ff
#define	 MSI_DATA_VECTOR(v)		(((v) << MSI_DATA_VECTOR_SHIFT) & MSI_DATA_VECTOR_MASK)

struct msi_msg {
	u32	address_lo;	/* low 32 bits of msi message address */
	u32	address_hi;	/* high 32 bits of msi message address */
	u32	data;		/* 16 bits of msi message data */
};

#endif /* __ASM_MSI_H */

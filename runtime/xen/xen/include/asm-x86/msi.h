#ifndef __ASM_MSI_H
#define __ASM_MSI_H

#include <xen/cpumask.h>
/*
 * Constants for Intel APIC based MSI messages.
 */

/*
 * Shifts for MSI data
 */

#define MSI_DATA_VECTOR_SHIFT		0
#define  MSI_DATA_VECTOR_MASK		0x000000ff
#define	 MSI_DATA_VECTOR(v)		(((v) << MSI_DATA_VECTOR_SHIFT) & MSI_DATA_VECTOR_MASK)

#define MSI_DATA_DELIVERY_MODE_SHIFT	8
#define  MSI_DATA_DELIVERY_FIXED	(0 << MSI_DATA_DELIVERY_MODE_SHIFT)
#define  MSI_DATA_DELIVERY_LOWPRI	(1 << MSI_DATA_DELIVERY_MODE_SHIFT)

#define MSI_DATA_LEVEL_SHIFT		14
#define	 MSI_DATA_LEVEL_DEASSERT	(0 << MSI_DATA_LEVEL_SHIFT)
#define	 MSI_DATA_LEVEL_ASSERT		(1 << MSI_DATA_LEVEL_SHIFT)

#define MSI_DATA_TRIGGER_SHIFT		15
#define  MSI_DATA_TRIGGER_EDGE		(0 << MSI_DATA_TRIGGER_SHIFT)
#define  MSI_DATA_TRIGGER_LEVEL		(1 << MSI_DATA_TRIGGER_SHIFT)

/*
 * Shift/mask fields for msi address
 */

#define MSI_ADDR_BASE_HI	    	0
#define MSI_ADDR_BASE_LO	    	0xfee00000
#define MSI_ADDR_HEADER             MSI_ADDR_BASE_LO

#define MSI_ADDR_DESTMODE_SHIFT     2
#define MSI_ADDR_DESTMODE_PHYS      (0 << MSI_ADDR_DESTMODE_SHIFT)
#define MSI_ADDR_DESTMODE_LOGIC     (1 << MSI_ADDR_DESTMODE_SHIFT)

#define MSI_ADDR_REDIRECTION_SHIFT  3
#define MSI_ADDR_REDIRECTION_CPU    (0 << MSI_ADDR_REDIRECTION_SHIFT)
#define MSI_ADDR_REDIRECTION_LOWPRI (1 << MSI_ADDR_REDIRECTION_SHIFT)

#define MSI_ADDR_DEST_ID_SHIFT		12
#define	 MSI_ADDR_DEST_ID_MASK		0x00ffff0
#define  MSI_ADDR_DEST_ID(dest)		(((dest) << MSI_ADDR_DEST_ID_SHIFT) & MSI_ADDR_DEST_ID_MASK)

/* MAX fixed pages reserved for mapping MSIX tables. */
#if defined(__x86_64__)
#define FIX_MSIX_MAX_PAGES              512
#else
#define FIX_MSIX_MAX_PAGES              32
#endif

struct msi_info {
    int bus;
    int devfn;
    int irq;
    int entry_nr;
    uint64_t table_base;
};

struct msi_msg {
	u32	address_lo;	/* low 32 bits of msi message address */
	u32	address_hi;	/* high 32 bits of msi message address */
	u32	data;		/* 16 bits of msi message data */
	u32	dest32;		/* used when Interrupt Remapping with EIM is enabled */
};

struct msi_desc;
/* Helper functions */
extern void mask_msi_irq(unsigned int irq);
extern void unmask_msi_irq(unsigned int irq);
extern void set_msi_affinity(unsigned int vector, cpumask_t mask);
extern int pci_enable_msi(struct msi_info *msi, struct msi_desc **desc);
extern void pci_disable_msi(struct msi_desc *desc);
extern void pci_cleanup_msi(struct pci_dev *pdev);
extern int setup_msi_irq(struct pci_dev *dev, struct msi_desc *desc, int irq);
extern void teardown_msi_irq(int irq);
extern int msi_free_vector(struct msi_desc *entry);
extern int pci_restore_msi_state(struct pci_dev *pdev);

extern unsigned int pci_msix_get_table_len(struct pci_dev *pdev);

struct msi_desc {
	struct {
		__u8	type	: 5; 	/* {0: unused, 5h:MSI, 11h:MSI-X} */
		__u8	maskbit	: 1; 	/* mask-pending bit supported ?   */
		__u8	masked	: 1;
		__u8	is_64	: 1;	/* Address size: 0=32bit 1=64bit  */
		__u8	pos;	 	/* Location of the msi capability */
		__u16	entry_nr;    	/* specific enabled entry 	  */
	}msi_attrib;

	struct list_head list;

	void __iomem *mask_base;        /* va for the entry in mask table */
	struct pci_dev *dev;
	int irq;

	struct msi_msg msg;		/* Last set MSI message */

	int remap_index;		/* index in interrupt remapping table */
};

int msi_maskable_irq(const struct msi_desc *);
int msi_free_irq(struct msi_desc *entry);

/*
 * Assume the maximum number of hot plug slots supported by the system is about
 * ten. The worstcase is that each of these slots is hot-added with a device,
 * which has two MSI/MSI-X capable functions. To avoid any MSI-X driver, which
 * attempts to request all available vectors, NR_HP_RESERVED_VECTORS is defined
 * as below to ensure at least one message is assigned to each detected MSI/
 * MSI-X device function.
 */
#define NR_HP_RESERVED_VECTORS 	20

extern const struct hw_interrupt_type pci_msi_type;

/*
 * MSI-X Address Register
 */
#define PCI_MSIX_FLAGS_QSIZE		0x7FF
#define PCI_MSIX_FLAGS_ENABLE		(1 << 15)
#define PCI_MSIX_FLAGS_BIRMASK		(7 << 0)
#define PCI_MSIX_FLAGS_BITMASK		(1 << 0)

#define PCI_MSIX_ENTRY_SIZE			16
#define  PCI_MSIX_ENTRY_LOWER_ADDR_OFFSET	0
#define  PCI_MSIX_ENTRY_UPPER_ADDR_OFFSET	4
#define  PCI_MSIX_ENTRY_DATA_OFFSET		8
#define  PCI_MSIX_ENTRY_VECTOR_CTRL_OFFSET	12

#define msi_control_reg(base)		(base + PCI_MSI_FLAGS)
#define msi_lower_address_reg(base)	(base + PCI_MSI_ADDRESS_LO)
#define msi_upper_address_reg(base)	(base + PCI_MSI_ADDRESS_HI)
#define msi_data_reg(base, is64bit)	\
	( (is64bit == 1) ? base+PCI_MSI_DATA_64 : base+PCI_MSI_DATA_32 )
#define msi_mask_bits_reg(base, is64bit) \
	( (is64bit == 1) ? base+PCI_MSI_MASK_BIT : base+PCI_MSI_MASK_BIT-4)
#define msi_disable(control)		control &= ~PCI_MSI_FLAGS_ENABLE
#define multi_msi_capable(control) \
	(1 << ((control & PCI_MSI_FLAGS_QMASK) >> 1))
#define multi_msi_enable(control, num) \
	control |= (((num >> 1) << 4) & PCI_MSI_FLAGS_QSIZE);
#define is_64bit_address(control)	(!!(control & PCI_MSI_FLAGS_64BIT))
#define is_mask_bit_support(control)	(!!(control & PCI_MSI_FLAGS_MASKBIT))
#define msi_enable(control, num) multi_msi_enable(control, num); \
	control |= PCI_MSI_FLAGS_ENABLE

#define msix_control_reg(base)		(base + PCI_MSIX_FLAGS)
#define msix_table_offset_reg(base)	(base + 0x04)
#define msix_pba_offset_reg(base)	(base + 0x08)
#define msix_enable(control)	 	control |= PCI_MSIX_FLAGS_ENABLE
#define msix_disable(control)	 	control &= ~PCI_MSIX_FLAGS_ENABLE
#define msix_table_size(control) 	((control & PCI_MSIX_FLAGS_QSIZE)+1)
#define multi_msix_capable		msix_table_size
#define msix_unmask(address)	 	(address & ~PCI_MSIX_FLAGS_BITMASK)
#define msix_mask(address)		(address | PCI_MSIX_FLAGS_BITMASK)
#define msix_is_pending(address) 	(address & PCI_MSIX_FLAGS_PENDMASK)

/*
 * MSI Defined Data Structures
 */
#define MSI_ADDRESS_HEADER		0xfee
#define MSI_ADDRESS_HEADER_SHIFT	12
#define MSI_ADDRESS_HEADER_MASK		0xfff000
#define MSI_ADDRESS_DEST_ID_MASK	0xfff0000f
#define MSI_TARGET_CPU_MASK		0xff
#define MSI_TARGET_CPU_SHIFT		12
#define MSI_DELIVERY_MODE		0
#define MSI_LEVEL_MODE			1	/* Edge always assert */
#define MSI_TRIGGER_MODE		0	/* MSI is edge sensitive */
#define MSI_PHYSICAL_MODE		0
#define MSI_LOGICAL_MODE		1
#define MSI_REDIRECTION_HINT_MODE	0

#define __LITTLE_ENDIAN_BITFIELD	1

struct msg_data {
#if defined(__LITTLE_ENDIAN_BITFIELD)
	__u32	vector		:  8;
	__u32	delivery_mode	:  3;	/* 000b: FIXED | 001b: lowest prior */
	__u32	reserved_1	:  3;
	__u32	level		:  1;	/* 0: deassert | 1: assert */
	__u32	trigger		:  1;	/* 0: edge | 1: level */
	__u32	reserved_2	: 16;
#elif defined(__BIG_ENDIAN_BITFIELD)
	__u32	reserved_2	: 16;
	__u32	trigger		:  1;	/* 0: edge | 1: level */
	__u32	level		:  1;	/* 0: deassert | 1: assert */
	__u32	reserved_1	:  3;
	__u32	delivery_mode	:  3;	/* 000b: FIXED | 001b: lowest prior */
	__u32	vector		:  8;
#else
#error "Bitfield endianness not defined! Check your byteorder.h"
#endif
} __attribute__ ((packed));

struct msg_address {
	union {
		struct {
#if defined(__LITTLE_ENDIAN_BITFIELD)
			__u32	reserved_1	:  2;
			__u32	dest_mode	:  1;	/*0:physic | 1:logic */
			__u32	redirection_hint:  1;  	/*0: dedicated CPU
							  1: lowest priority */
			__u32	reserved_2	:  4;
 			__u32	dest_id		: 24;	/* Destination ID */
#elif defined(__BIG_ENDIAN_BITFIELD)
 			__u32	dest_id		: 24;	/* Destination ID */
			__u32	reserved_2	:  4;
			__u32	redirection_hint:  1;  	/*0: dedicated CPU
							  1: lowest priority */
			__u32	dest_mode	:  1;	/*0:physic | 1:logic */
			__u32	reserved_1	:  2;
#else
#error "Bitfield endianness not defined! Check your byteorder.h"
#endif
      		}u;
       		__u32  value;
	}lo_address;
	__u32 	hi_address;
} __attribute__ ((packed));

void msi_compose_msg(struct pci_dev *pdev, int irq,
                            struct msi_msg *msg);
#endif /* __ASM_MSI_H */

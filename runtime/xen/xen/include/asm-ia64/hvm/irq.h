/******************************************************************************
 * irq.h
 *
 * Interrupt distribution and delivery logic.
 *
 * Copyright (c) 2006, K A Fraser, XenSource Inc.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307 USA.
 */

#ifndef __ASM_IA64_HVM_IRQ_H__
#define __ASM_IA64_HVM_IRQ_H__

#include <xen/irq.h>

#define VIOAPIC_NUM_PINS  48

#include <xen/hvm/irq.h>

struct hvm_hw_pci_irqs {
    /*
     * Virtual interrupt wires for a single PCI bus.
     * Indexed by: device*4 + INTx#.
     */
    union {
        DECLARE_BITMAP(i, 32*4);
        uint64_t pad[2];
    };
};

struct hvm_irq {
    /*
     * Virtual interrupt wires for a single PCI bus.
     * Indexed by: device*4 + INTx#.
     */
    struct hvm_hw_pci_irqs pci_intx;

    /* Virtual interrupt and via-link for paravirtual platform driver. */
    uint32_t callback_via_asserted;
    union {
        enum {
            HVMIRQ_callback_none,
            HVMIRQ_callback_gsi,
            HVMIRQ_callback_pci_intx
        } callback_via_type;
    };
    union {
        uint32_t gsi;
        struct { uint8_t dev, intx; } pci;
    } callback_via;

    /*
     * Number of wires asserting each GSI.
     *
     * GSIs 0-15 are the ISA IRQs. ISA devices map directly into this space
     * except ISA IRQ 0, which is connected to GSI 2.
     * PCI links map into this space via the PCI-ISA bridge.
     *
     * GSIs 16+ are used only be PCI devices. The mapping from PCI device to
     * GSI is as follows: ((device*4 + device/8 + INTx#) & 31) + 16
     */
    u8 gsi_assert_count[VIOAPIC_NUM_PINS];

    /*
     * GSIs map onto PIC/IO-APIC in the usual way:
     *  0-7:  Master 8259 PIC, IO-APIC pins 0-7
     *  8-15: Slave  8259 PIC, IO-APIC pins 8-15
     *  16+ : IO-APIC pins 16+
     */

    /* Last VCPU that was delivered a LowestPrio interrupt. */
    u8 round_robin_prev_vcpu;

    struct hvm_irq_dpci *dpci;
};

#define hvm_pci_intx_gsi(dev, intx)  \
    (((((dev)<<2) + ((dev)>>3) + (intx)) & 31) + 16)
#define hvm_pci_intx_link(dev, intx) \
    (((dev) + (intx)) & 3)

#define IA64_INVALID_VECTOR	((unsigned int)((int)-1))
static inline unsigned int irq_to_vector(int irq)
{
    int acpi_gsi_to_irq (u32 gsi, unsigned int *irq);
    unsigned int vector;

    if ( acpi_gsi_to_irq(irq, &vector) < 0)
        return 0;

    return vector;
}

extern u8 irq_vector[NR_IRQS];
extern int vector_irq[NR_VECTORS];

#endif /* __ASM_IA64_HVM_IRQ_H__ */

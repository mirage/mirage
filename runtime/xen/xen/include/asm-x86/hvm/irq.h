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

#ifndef __ASM_X86_HVM_IRQ_H__
#define __ASM_X86_HVM_IRQ_H__

#include <xen/hvm/irq.h>
#include <asm/hvm/hvm.h>
#include <asm/hvm/vpic.h>
#include <asm/hvm/vioapic.h>

struct hvm_irq {
    /*
     * Virtual interrupt wires for a single PCI bus.
     * Indexed by: device*4 + INTx#.
     */
    struct hvm_hw_pci_irqs pci_intx;

    /*
     * Virtual interrupt wires for ISA devices.
     * Indexed by ISA IRQ (assumes no ISA-device IRQ sharing).
     */
    struct hvm_hw_isa_irqs isa_irq;

    /*
     * PCI-ISA interrupt router.
     * Each PCI <device:INTx#> is 'wire-ORed' into one of four links using
     * the traditional 'barber's pole' mapping ((device + INTx#) & 3).
     * The router provides a programmable mapping from each link to a GSI.
     */
    struct hvm_hw_pci_link pci_link;

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

    /* Number of INTx wires asserting each PCI-ISA link. */
    u8 pci_link_assert_count[4];

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

#define hvm_isa_irq_to_gsi(isa_irq) ((isa_irq) ? : 2)

/* Check/Acknowledge next pending interrupt. */
struct hvm_intack hvm_vcpu_has_pending_irq(struct vcpu *v);
struct hvm_intack hvm_vcpu_ack_pending_irq(struct vcpu *v,
                                           struct hvm_intack intack);

/*
 * Currently IA64 Xen doesn't support MSI. So for x86, we define this macro
 * to control the conditional compilation of some MSI-related functions.
 * This macro will be removed once IA64 has MSI support.
 */
#define SUPPORT_MSI_REMAPPING 1

#endif /* __ASM_X86_HVM_IRQ_H__ */

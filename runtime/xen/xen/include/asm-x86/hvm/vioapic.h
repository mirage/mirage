/*
 *  Copyright (C) 2001  MandrakeSoft S.A.
 *
 *    MandrakeSoft S.A.
 *    43, rue d'Aboukir
 *    75002 Paris - France
 *    http://www.linux-mandrake.com/
 *    http://www.mandrakesoft.com/
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 */

#ifndef __ASM_X86_HVM_VIOAPIC_H__
#define __ASM_X86_HVM_VIOAPIC_H__

#include <xen/config.h>
#include <xen/types.h>
#include <xen/smp.h>
#include <public/hvm/save.h>

#if !VIOAPIC_IS_IOSAPIC
#define VIOAPIC_VERSION_ID 0x11 /* IOAPIC version */
#else
#define VIOAPIC_VERSION_ID 0x21 /* IOSAPIC version */
#endif

#define VIOAPIC_EDGE_TRIG  0
#define VIOAPIC_LEVEL_TRIG 1

#define VIOAPIC_DEFAULT_BASE_ADDRESS  0xfec00000
#define VIOAPIC_MEM_LENGTH            0x100

/* Direct registers. */
#define VIOAPIC_REG_SELECT  0x00
#define VIOAPIC_REG_WINDOW  0x10
#define VIOAPIC_REG_EOI     0x40 /* IA64 IOSAPIC only */

/* Indirect registers. */
#define VIOAPIC_REG_APIC_ID 0x00 /* x86 IOAPIC only */
#define VIOAPIC_REG_VERSION 0x01
#define VIOAPIC_REG_ARB_ID  0x02 /* x86 IOAPIC only */

struct hvm_vioapic {
    struct hvm_hw_vioapic hvm_hw_vioapic;
    struct domain *domain;
};

#define domain_vioapic(d) (&(d)->arch.hvm_domain.vioapic->hvm_hw_vioapic)
#define vioapic_domain(v) (container_of((v), struct hvm_vioapic, \
                                        hvm_hw_vioapic)->domain)

int vioapic_init(struct domain *d);
void vioapic_deinit(struct domain *d);
void vioapic_reset(struct domain *d);
void vioapic_irq_positive_edge(struct domain *d, unsigned int irq);
void vioapic_update_EOI(struct domain *d, int vector);

#endif /* __ASM_X86_HVM_VIOAPIC_H__ */

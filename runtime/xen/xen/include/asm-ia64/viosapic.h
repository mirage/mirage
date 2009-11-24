/*
 *
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

#ifndef __ASM_IA64_VMX_VIOSAPIC_H__
#define __ASM_IA64_VMX_VIOSAPIC_H__

#include <xen/config.h>
#include <xen/types.h>
#include <xen/smp.h>
#include <public/arch-ia64/hvm/save.h> /* for VIOSAPIC_NUM_PINS and
                                          union viosapic_rte */

/* Direct registers. */
#define VIOSAPIC_REG_SELECT   0x00
#define VIOSAPIC_WINDOW       0x10
#define VIOSAPIC_EOI          0x40

#define VIOSAPIC_VERSION      0x1

#define VIOSAPIC_DEST_SHIFT   16


#define VIOSAPIC_VERSION_ID   0x21 /* IOSAPIC version */

#define VIOSAPIC_DEFAULT_BASE_ADDRESS  0xfec00000
#define VIOSAPIC_MEM_LENGTH            0x100

#define domain_viosapic(d) (&(d)->arch.hvm_domain.viosapic)
#define viosapic_domain(v) (container_of((v), struct domain, \
                                        arch.hvm_domain.viosapic))
#define vcpu_viosapic(v) (&(v)->domain->arch.hvm_domain.viosapic)

struct viosapic {
    uint64_t irr;
    uint64_t isr;     /* This is used for level trigger */
    uint32_t ioregsel;
    spinlock_t lock;
    struct vcpu * lowest_vcpu;
    uint64_t base_address;
    union vioapic_redir_entry redirtbl[VIOSAPIC_NUM_PINS];
};

void viosapic_init(struct domain *d);
void viosapic_set_irq(struct domain *d, int irq, int level);
void viosapic_set_pci_irq(struct domain *d, int device, int intx, int level);
void viosapic_write(struct vcpu *v, unsigned long addr,
                    unsigned long length, unsigned long val);

unsigned long viosapic_read(struct vcpu *v, unsigned long addr,
                            unsigned long length);
void hvm_dpci_eoi(struct domain *d, unsigned int guest_gsi,
                          union vioapic_redir_entry *ent);

#endif /* __ASM_IA64_VMX_VIOSAPIC_H__ */

/*
 * hvm_vlapic.h: virtualize LAPIC definitions.
 *
 * Copyright (c) 2004, Intel Corporation.
 * Copyright (c) 2006 Keir Fraser, XenSource Inc.
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

#ifndef __ASM_X86_HVM_VLAPIC_H__
#define __ASM_X86_HVM_VLAPIC_H__

#include <xen/softirq.h>
#include <asm/msr.h>
#include <public/hvm/ioreq.h>
#include <asm/hvm/vpt.h>

#define MAX_VECTOR      256

#define vcpu_vlapic(x)   (&(x)->arch.hvm_vcpu.vlapic)
#define vlapic_vcpu(x)   (container_of((x), struct vcpu, arch.hvm_vcpu.vlapic))
#define vlapic_domain(x) (vlapic_vcpu(x)->domain)

#define VLAPIC_ID(vlapic)   \
    (GET_xAPIC_ID(vlapic_get_reg((vlapic), APIC_ID)))

/*
 * APIC can be disabled in two ways:
 *  1. 'Hardware disable': via IA32_APIC_BASE_MSR[11]
 *     CPU should behave as if it does not have an APIC.
 *  2. 'Software disable': via APIC_SPIV[8].
 *     APIC is visible but does not respond to interrupt messages.
 */
#define VLAPIC_HW_DISABLED              0x1
#define VLAPIC_SW_DISABLED              0x2
#define vlapic_sw_disabled(vlapic) ((vlapic)->hw.disabled & VLAPIC_SW_DISABLED)
#define vlapic_hw_disabled(vlapic) ((vlapic)->hw.disabled & VLAPIC_HW_DISABLED)
#define vlapic_disabled(vlapic)    ((vlapic)->hw.disabled)
#define vlapic_enabled(vlapic)     (!vlapic_disabled(vlapic))

#define vlapic_base_address(vlapic)                             \
    ((vlapic)->hw.apic_base_msr & MSR_IA32_APICBASE_BASE)

struct vlapic {
    struct hvm_hw_lapic      hw;
    struct hvm_hw_lapic_regs *regs;
    struct periodic_time     pt;
    s_time_t                 timer_last_update;
    struct page_info         *regs_page;
    struct tasklet           init_tasklet;
};

static inline uint32_t vlapic_get_reg(struct vlapic *vlapic, uint32_t reg)
{
    return *((uint32_t *)(&vlapic->regs->data[reg]));
}

static inline void vlapic_set_reg(
    struct vlapic *vlapic, uint32_t reg, uint32_t val)
{
    *((uint32_t *)(&vlapic->regs->data[reg])) = val;
}

static inline int is_vlapic_lvtpc_enabled(struct vlapic *vlapic)
{
    return vlapic_enabled(vlapic) &&
           !(vlapic_get_reg(vlapic, APIC_LVTPC) & APIC_LVT_MASKED);
}

int vlapic_set_irq(struct vlapic *vlapic, uint8_t vec, uint8_t trig);

int vlapic_has_pending_irq(struct vcpu *v);
int vlapic_ack_pending_irq(struct vcpu *v, int vector);

int  vlapic_init(struct vcpu *v);
void vlapic_destroy(struct vcpu *v);

void vlapic_reset(struct vlapic *vlapic);

void vlapic_msr_set(struct vlapic *vlapic, uint64_t value);

int vlapic_accept_pic_intr(struct vcpu *v);

void vlapic_adjust_i8259_target(struct domain *d);

void vlapic_EOI_set(struct vlapic *vlapic);

int vlapic_ipi(struct vlapic *vlapic, uint32_t icr_low, uint32_t icr_high);

struct vlapic *vlapic_lowest_prio(
    struct domain *d, struct vlapic *source,
    int short_hand, uint8_t dest, uint8_t dest_mode);

bool_t vlapic_match_dest(
    struct vlapic *target, struct vlapic *source,
    int short_hand, uint8_t dest, uint8_t dest_mode);

#endif /* __ASM_X86_HVM_VLAPIC_H__ */

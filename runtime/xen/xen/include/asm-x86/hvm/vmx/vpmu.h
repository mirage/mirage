/*
 * vpmu.h: PMU virtualization for HVM domain.
 *
 * Copyright (c) 2007, Intel Corporation.
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
 *
 * Author: Haitao Shan <haitao.shan@intel.com>
 */

#ifndef __ASM_X86_HVM_VPMU_H_
#define __ASM_X86_HVM_VPMU_H_

#define msraddr_to_bitpos(x) (((x)&0xffff) + ((x)>>31)*0x2000)
#define vcpu_vpmu(vcpu)   (&(vcpu)->arch.hvm_vcpu.u.vmx.vpmu)
#define vpmu_vcpu(vpmu)   (container_of((vpmu), struct vcpu, \
                                          arch.hvm_vcpu.u.vmx.vpmu))
#define vpmu_domain(vpmu) (vpmu_vcpu(vpmu)->domain)

#define MSR_TYPE_COUNTER            0
#define MSR_TYPE_CTRL               1
#define MSR_TYPE_GLOBAL             2
#define MSR_TYPE_ARCH_COUNTER       3
#define MSR_TYPE_ARCH_CTRL          4

struct pmumsr {
    unsigned int num;
    u32 *msr;
};

struct msr_load_store_entry {
    u32 msr_index;
    u32 msr_reserved;
    u64 msr_data;
};

/* Arch specific operations shared by all vpmus */
struct arch_vpmu_ops {
    int (*do_wrmsr)(struct cpu_user_regs *regs);
    int (*do_rdmsr)(struct cpu_user_regs *regs);
    int (*do_interrupt)(struct cpu_user_regs *regs);
    void (*arch_vpmu_initialise)(struct vcpu *v);
    void (*arch_vpmu_destroy)(struct vcpu *v);
    void (*arch_vpmu_save)(struct vcpu *v);
    void (*arch_vpmu_load)(struct vcpu *v);
};

struct vpmu_struct {
    u32 flags;
    void *context;
    struct arch_vpmu_ops *arch_vpmu_ops;
};

#define VPMU_CONTEXT_ALLOCATED              0x1
#define VPMU_CONTEXT_LOADED                 0x2
#define VPMU_RUNNING                        0x4
#define PASSIVE_DOMAIN_ALLOCATED	    0x8
int vpmu_do_wrmsr(struct cpu_user_regs *regs);
int vpmu_do_rdmsr(struct cpu_user_regs *regs);
int vpmu_do_interrupt(struct cpu_user_regs *regs);
void vpmu_initialise(struct vcpu *v);
void vpmu_destroy(struct vcpu *v);
void vpmu_save(struct vcpu *v);
void vpmu_load(struct vcpu *v);

extern int acquire_pmu_ownership(int pmu_ownership);
extern void release_pmu_ownership(int pmu_ownership);

#endif /* __ASM_X86_HVM_VPMU_H_*/



/*
 * vpmu_core2.h: CORE 2 specific PMU virtualization for HVM domain.
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

#ifndef __ASM_X86_HVM_VPMU_CORE_H_
#define __ASM_X86_HVM_VPMU_CORE_H_

struct arch_msr_pair {
    u64 counter;
    u64 control;
};

struct core2_pmu_enable {
    char fixed_ctr_enable[3];
    char arch_pmc_enable[1];
};

struct core2_vpmu_context {
    struct core2_pmu_enable *pmu_enable;
    u64 counters[3];
    u64 ctrls[3];
    u64 global_ovf_status;
    u32 hw_lapic_lvtpc;
    struct arch_msr_pair arch_msr_pair[1];
};

#endif /* __ASM_X86_HVM_VPMU_CORE_H_ */


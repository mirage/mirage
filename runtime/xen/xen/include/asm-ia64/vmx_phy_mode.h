/* -*-  Mode:C; c-basic-offset:4; tab-width:4; indent-tabs-mode:nil -*- */
/*
 * vmx_phy_mode.h: 
 * Copyright (c) 2004, Intel Corporation.
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
 */

#ifndef _PHY_MODE_H_
#define _PHY_MODE_H_

/*
 *  Guest Physical Mode is emulated by GVMM, which is actually running
 *  in virtual mode.
 *
 *  For all combinations of (it,dt,rt), only three were taken into
 *  account:
 *  (0,0,0): some firmware and kernel start code execute in this mode;
 *  (1,1,1): most kernel C code execute in this mode;
 *  (1,0,1): some low level TLB miss handler code execute in this mode;
 *  Till now, no other kind of combinations were found.
 *
 *  Because all physical addresses fall into two categories:
 *  0x0xxxxxxxxxxxxxxx, which is cacheable, and 0x8xxxxxxxxxxxxxxx, which
 *  is uncacheable. These two kinds of addresses reside in region 0 and 4
 *  of the virtual mode. Therefore, we load two different Region IDs
 *  (A, B) into RR0 and RR4, respectively, when guest is entering phsical
 *  mode. These two RIDs are totally different from the RIDs used in
 *  virtual mode. So, the aliasness between physical addresses and virtual
 *  addresses can be disambiguated by different RIDs.
 *
 *  RID A and B are stolen from the cpu ulm region id. In linux, each
 *  process is allocated 8 RIDs:
 *          mmu_context << 3 + 0
 *          mmu_context << 3 + 1
 *          mmu_context << 3 + 2
 *          mmu_context << 3 + 3
 *          mmu_context << 3 + 4
 *          mmu_context << 3 + 5
 *          mmu_context << 3 + 6
 *          mmu_context << 3 + 7
 *  Because all processes share region 5~7, the last 3 are left untouched.
 *  So, we stolen "mmu_context << 3 + 5" and "mmu_context << 3 + 6" from
 *  ulm and use them as RID A and RID B.
 *
 *  When guest is running in (1,0,1) mode, the instructions been accessed
 *  reside in region 5~7, not in region 0 or 4. So, instruction can be
 *  accessed in virtual mode without interferring physical data access.
 *
 *  When dt!=rt, it is rarely to perform "load/store" and "RSE" operation
 *  at the same time. No need to consider such a case. We consider (0,1)
 *  as (0,0).
 *
 */


#ifndef __ASSEMBLY__

#include <asm/vmx_vcpu.h>
#include <asm/regionreg.h>
#include <asm/gcc_intrin.h>
#include <asm/pgtable.h>

#define PHY_PAGE_WB (_PAGE_A|_PAGE_D|_PAGE_P|_PAGE_MA_WB|_PAGE_AR_RWX)

extern void physical_mode_init(VCPU *);
extern void switch_to_physical_rid(VCPU *);
extern void switch_to_virtual_rid(VCPU *vcpu);
extern void switch_mm_mode(VCPU *vcpu, IA64_PSR old_psr, IA64_PSR new_psr);
extern void switch_mm_mode_fast(VCPU *vcpu, IA64_PSR old_psr, IA64_PSR new_psr);
extern void check_mm_mode_switch(VCPU *vcpu,  IA64_PSR old_psr, IA64_PSR new_psr);
extern void prepare_if_physical_mode(VCPU *vcpu);
extern void recover_if_physical_mode(VCPU *vcpu);
extern void vmx_init_all_rr(VCPU *vcpu);
extern void vmx_load_all_rr(VCPU *vcpu);
extern void physical_tlb_miss(VCPU *vcpu, u64 vadr, int type);

#define VMX_MMU_MODE(v)     ((v)->arch.arch_vmx.mmu_mode)
#define is_virtual_mode(v)  (VMX_MMU_MODE(v) == VMX_MMU_VIRTUAL)

#endif /* __ASSEMBLY__ */

#define VMX_MMU_VIRTUAL    0    /* Full virtual mode: it=dt=1  */
#define VMX_MMU_PHY_D      1    /* Half physical: it=1,dt=0  */
#define VMX_MMU_PHY_DT     3    /* Full physical mode: it=0,dt=0  */

#define PAL_INIT_ENTRY 0x80000000ffffffa0

#endif /* _PHY_MODE_H_ */

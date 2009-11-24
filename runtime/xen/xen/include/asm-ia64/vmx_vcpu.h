/* -*-  Mode:C; c-basic-offset:8; tab-width:8; indent-tabs-mode:nil -*- */
/*
 * vmx_vcpu.h:
 * Copyright (c) 2005, Intel Corporation.
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
 *  Xuefei Xu (Anthony Xu) (Anthony.xu@intel.com)
 *  Yaozu Dong (Eddie Dong) (Eddie.dong@intel.com)
 */

#ifndef _XEN_IA64_VMX_VCPU_H
#define _XEN_IA64_VMX_VCPU_H

#include <xen/sched.h>
#include <asm/ia64_int.h>
#include <asm/vmx_vpd.h>
#include <asm/ptrace.h>
#include <asm/regs.h>
#include <asm/regionreg.h>
#include <asm/types.h>
#include <asm/vcpu.h>

#define VRN_SHIFT	61
#define VRN0		0x0UL
#define VRN1		0x1UL
#define VRN2		0x2UL
#define VRN3		0x3UL
#define VRN4		0x4UL
#define VRN5		0x5UL
#define VRN6		0x6UL
#define VRN7		0x7UL
// for vlsapic
#define VLSAPIC_INSVC(vcpu, i) ((vcpu)->arch.insvc[i])

#define VMX(x,y)  ((x)->arch.arch_vmx.y)

#define VMM_RR_SHIFT	20
#define VMM_RR_MASK	((1UL<<VMM_RR_SHIFT)-1)

extern u64 indirect_reg_igfld_MASK(int type, int index, u64 value);
extern u64 cr_igfld_mask(int index, u64 value);
extern int check_indirect_reg_rsv_fields(int type, int index, u64 value);
extern u64 set_isr_ei_ni(VCPU * vcpu);
extern u64 set_isr_for_na_inst(VCPU * vcpu, int op);
extern void set_illegal_op_isr (VCPU *vcpu);

/* next all for VTI domain APIs definition */
extern void vmx_vcpu_set_psr(VCPU * vcpu, unsigned long value);
extern IA64FAULT vmx_vcpu_cover(VCPU * vcpu);
extern IA64FAULT vmx_vcpu_set_rr(VCPU * vcpu, u64 reg, u64 val);
extern u64 vmx_vcpu_get_pkr(VCPU * vcpu, u64 reg);
IA64FAULT vmx_vcpu_set_pkr(VCPU * vcpu, u64 reg, u64 val);
extern IA64FAULT vmx_vcpu_itc_i(VCPU * vcpu, u64 pte, u64 itir, u64 ifa);
extern IA64FAULT vmx_vcpu_itc_d(VCPU * vcpu, u64 pte, u64 itir, u64 ifa);
extern IA64FAULT vmx_vcpu_itr_i(VCPU * vcpu, u64 slot, u64 pte, u64 itir,
                                u64 ifa);
extern IA64FAULT vmx_vcpu_itr_d(VCPU * vcpu, u64 slot, u64 pte, u64 itir,
                                u64 ifa);
extern IA64FAULT vmx_vcpu_ptr_d(VCPU * vcpu, u64 vadr, u64 ps);
extern IA64FAULT vmx_vcpu_ptr_i(VCPU * vcpu, u64 vadr, u64 ps);
extern IA64FAULT vmx_vcpu_ptc_l(VCPU * vcpu, u64 vadr, u64 ps);
extern IA64FAULT vmx_vcpu_ptc_e(VCPU * vcpu, u64 vadr);
extern IA64FAULT vmx_vcpu_ptc_g(VCPU * vcpu, u64 vadr, u64 ps);
extern IA64FAULT vmx_vcpu_ptc_ga(VCPU * vcpu, u64 vadr, u64 ps);
extern u64 vmx_vcpu_thash(VCPU * vcpu, u64 vadr);
extern u64 vmx_vcpu_get_itir_on_fault(VCPU * vcpu, u64 ifa);
extern u64 vmx_vcpu_ttag(VCPU * vcpu, u64 vadr);
extern IA64FAULT vmx_vcpu_tpa(VCPU * vcpu, u64 vadr, u64 * padr);
extern u64 vmx_vcpu_tak(VCPU * vcpu, u64 vadr);
extern IA64FAULT vmx_vcpu_rfi(VCPU * vcpu);
extern u64 vmx_vcpu_get_psr(VCPU * vcpu);
extern IA64FAULT vmx_vcpu_get_bgr(VCPU * vcpu, unsigned int reg, u64 * val);
extern IA64FAULT vmx_vcpu_set_bgr(VCPU * vcpu, unsigned int reg, u64 val,
                                  int nat);
#if 0
extern IA64FAULT vmx_vcpu_get_gr(VCPU * vcpu, unsigned reg, u64 * val);
extern IA64FAULT vmx_vcpu_set_gr(VCPU * vcpu, unsigned reg, u64 value, int nat);
#endif
extern IA64FAULT vmx_vcpu_reset_psr_sm(VCPU * vcpu, u64 imm24);
extern IA64FAULT vmx_vcpu_set_psr_sm(VCPU * vcpu, u64 imm24);
extern IA64FAULT vmx_vcpu_set_psr_l(VCPU * vcpu, u64 val);
extern void vtm_init(VCPU * vcpu);
extern uint64_t vtm_get_itc(VCPU * vcpu);
extern void vtm_set_itc(VCPU * vcpu, uint64_t new_itc);
extern void vtm_set_itv(VCPU * vcpu, uint64_t val);
extern void vtm_set_itm(VCPU * vcpu, uint64_t val);
extern void vlsapic_reset(VCPU * vcpu);
extern int vmx_check_pending_irq(VCPU * vcpu);
extern void guest_write_eoi(VCPU * vcpu);
extern int is_unmasked_irq(VCPU * vcpu);
extern uint64_t guest_read_vivr(VCPU * vcpu);
extern int vmx_vcpu_pend_interrupt(VCPU * vcpu, uint8_t vector);
extern void vcpu_load_kernel_regs(VCPU * vcpu);
extern void __vmx_switch_rr7(unsigned long rid, void *guest_vhpt,
                             void *shared_arch_info);
extern void __vmx_switch_rr7_vcpu(struct vcpu *v, unsigned long rid);
extern void vmx_switch_rr7_vcpu(struct vcpu *v, unsigned long rid);
extern void vmx_ia64_set_dcr(VCPU * v);
extern void inject_guest_interruption(struct vcpu *vcpu, u64 vec);
extern void vmx_asm_bsw0(void);
extern void vmx_asm_bsw1(void);

/**************************************************************************
 VCPU control register access routines
**************************************************************************/

static inline u64 vmx_vcpu_get_itm(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, itm));
}

static inline u64 vmx_vcpu_get_iva(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, iva));
}

static inline u64 vmx_vcpu_get_pta(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, pta));
}

static inline u64 vmx_vcpu_get_lid(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, lid));
}

static inline u64 vmx_vcpu_get_ivr(VCPU * vcpu)
{
	return ((u64)guest_read_vivr(vcpu));
}

static inline u64 vmx_vcpu_get_tpr(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, tpr));
}

static inline u64 vmx_vcpu_get_eoi(VCPU * vcpu)
{
	return (0UL);		// reads of eoi always return 0
}

static inline u64 vmx_vcpu_get_irr0(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, irr[0]));
}

static inline u64 vmx_vcpu_get_irr1(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, irr[1]));
}

static inline u64 vmx_vcpu_get_irr2(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, irr[2]));
}

static inline u64 vmx_vcpu_get_irr3(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, irr[3]));
}

static inline u64 vmx_vcpu_get_itv(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, itv));
}

static inline u64 vmx_vcpu_get_pmv(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, pmv));
}

static inline u64 vmx_vcpu_get_cmcv(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, cmcv));
}

static inline u64 vmx_vcpu_get_lrr0(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, lrr0));
}

static inline u64 vmx_vcpu_get_lrr1(VCPU * vcpu)
{
	return ((u64)VCPU(vcpu, lrr1));
}

static inline IA64FAULT vmx_vcpu_set_itm(VCPU * vcpu, u64 val)
{
	vtm_set_itm(vcpu, val);
	return IA64_NO_FAULT;
}

static inline IA64FAULT vmx_vcpu_set_iva(VCPU * vcpu, u64 val)
{
	VCPU(vcpu, iva) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vmx_vcpu_set_pta(VCPU * vcpu, u64 val)
{
	VCPU(vcpu, pta) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vmx_vcpu_set_lid(VCPU * vcpu, u64 val)
{
	VCPU(vcpu, lid) = val;
	return IA64_NO_FAULT;
}
extern IA64FAULT vmx_vcpu_set_tpr(VCPU * vcpu, u64 val);

static inline IA64FAULT vmx_vcpu_set_eoi(VCPU * vcpu, u64 val)
{
	guest_write_eoi(vcpu);
	return IA64_NO_FAULT;
}

static inline IA64FAULT vmx_vcpu_set_itv(VCPU * vcpu, u64 val)
{

	vtm_set_itv(vcpu, val);
	return IA64_NO_FAULT;
}

static inline IA64FAULT vmx_vcpu_set_pmv(VCPU * vcpu, u64 val)
{
	VCPU(vcpu, pmv) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vmx_vcpu_set_cmcv(VCPU * vcpu, u64 val)
{
	VCPU(vcpu, cmcv) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vmx_vcpu_set_lrr0(VCPU * vcpu, u64 val)
{
	VCPU(vcpu, lrr0) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vmx_vcpu_set_lrr1(VCPU * vcpu, u64 val)
{
	VCPU(vcpu, lrr1) = val;
	return IA64_NO_FAULT;
}

/**************************************************************************
 VCPU privileged application register access routines
**************************************************************************/
static inline IA64FAULT vmx_vcpu_set_itc(VCPU * vcpu, u64 val)
{
	vtm_set_itc(vcpu, val);
	return IA64_NO_FAULT;
}

static inline u64 vmx_vcpu_get_itc(VCPU * vcpu)
{
	return ((u64)vtm_get_itc(vcpu));
}

/*
static inline
IA64FAULT vmx_vcpu_get_rr(VCPU *vcpu, u64 reg, u64 *pval)
{
    *pval = VMX(vcpu,vrr[reg>>61]);
    return IA64_NO_FAULT;
}
 */
/**************************************************************************
 VCPU debug breakpoint register access routines
**************************************************************************/

static inline u64 vmx_vcpu_get_cpuid(VCPU * vcpu, u64 reg)
{
	// TODO: unimplemented DBRs return a reserved register fault
	// TODO: Should set Logical CPU state, not just physical
	if (reg > 4) {
		panic_domain(vcpu_regs(vcpu),
			     "there are only five cpuid registers");
	}
	return ((u64)VCPU(vcpu, vcpuid[reg]));
}

static inline IA64FAULT vmx_vcpu_set_dbr(VCPU * vcpu, u64 reg, u64 val)
{
        return vcpu_set_dbr(vcpu, reg, val);
}

static inline IA64FAULT vmx_vcpu_set_ibr(VCPU * vcpu, u64 reg, u64 val)
{
        return vcpu_set_ibr(vcpu, reg, val);
}

static inline IA64FAULT vmx_vcpu_get_dbr(VCPU * vcpu, u64 reg, u64 *pval)
{
        return vcpu_get_dbr(vcpu, reg, pval);
}

static inline IA64FAULT vmx_vcpu_get_ibr(VCPU * vcpu, u64 reg, u64 *pval)
{
        return vcpu_get_ibr(vcpu, reg, pval);
}

/**************************************************************************
 VCPU performance monitor register access routines
**************************************************************************/
static inline IA64FAULT vmx_vcpu_set_pmc(VCPU * vcpu, u64 reg, u64 val)
{
	// TODO: Should set Logical CPU state, not just physical
	// NOTE: Writes to unimplemented PMC registers are discarded
	ia64_set_pmc(reg, val);
	return IA64_NO_FAULT;
}

static inline IA64FAULT vmx_vcpu_set_pmd(VCPU * vcpu, u64 reg, u64 val)
{
	// TODO: Should set Logical CPU state, not just physical
	// NOTE: Writes to unimplemented PMD registers are discarded
	ia64_set_pmd(reg, val);
	return IA64_NO_FAULT;
}

static inline u64 vmx_vcpu_get_pmc(VCPU * vcpu, u64 reg)
{
	// NOTE: Reads from unimplemented PMC registers return zero
	return ((u64)ia64_get_pmc(reg));
}

static inline u64 vmx_vcpu_get_pmd(VCPU * vcpu, u64 reg)
{
	// NOTE: Reads from unimplemented PMD registers return zero
	return ((u64)ia64_get_pmd(reg));
}

/**************************************************************************
 VCPU banked general register access routines
**************************************************************************/
#if 0
static inline IA64FAULT vmx_vcpu_bsw0(VCPU * vcpu)
{

	VCPU(vcpu, vpsr) &= ~IA64_PSR_BN;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vmx_vcpu_bsw1(VCPU * vcpu)
{

	VCPU(vcpu, vpsr) |= IA64_PSR_BN;
	return IA64_NO_FAULT;
}
#endif
#if 0
/* Another hash performance algorithm */
#define redistribute_rid(rid)	(((rid) & ~0xffff) | (((rid) << 8) & 0xff00) | (((rid) >> 8) & 0xff))
#endif
static inline unsigned long vrrtomrr(VCPU * v, unsigned long val)
{
	ia64_rr rr;

	rr.rrval = val;
	rr.rid = rr.rid + v->arch.starting_rid;
	if (rr.ps > PAGE_SHIFT)
		rr.ps = PAGE_SHIFT;
	rr.ve = 1;
	return vmMangleRID(rr.rrval);
/* Disable this rid allocation algorithm for now */
#if 0
	rid = (((u64) vcpu->domain->domain_id) << DOMAIN_RID_SHIFT) + rr.rid;
	rr.rid = redistribute_rid(rid);
#endif

}
static inline thash_cb_t *vmx_vcpu_get_vtlb(VCPU * vcpu)
{
	return &vcpu->arch.vtlb;
}

static inline thash_cb_t *vcpu_get_vhpt(VCPU * vcpu)
{
	return &vcpu->arch.vhpt;
}


/**************************************************************************
 VCPU fault injection routines
**************************************************************************/

/*
 * Set vIFA & vITIR & vIHA, when vPSR.ic =1
 * Parameter:
 *  set_ifa: if true, set vIFA
 *  set_itir: if true, set vITIR
 *  set_iha: if true, set vIHA
 */
static inline void
set_ifa_itir_iha (VCPU *vcpu, u64 vadr,
		  int set_ifa, int set_itir, int set_iha)
{
	IA64_PSR vpsr;
	u64 value;
	vpsr.val = VCPU(vcpu, vpsr);
	/* Vol2, Table 8-1 */
	if (vpsr.ic) {
		if (set_ifa){
			vcpu_set_ifa(vcpu, vadr);
		}
		if (set_itir) {
			value = vmx_vcpu_get_itir_on_fault(vcpu, vadr);
			vcpu_set_itir(vcpu, value);
		}
		if (set_iha) {
			value = vmx_vcpu_thash(vcpu, vadr);
			vcpu_set_iha(vcpu, value);
		}
	}
}

/*
 * Data TLB Fault
 *  @ Data TLB vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
dtlb_fault (VCPU *vcpu, u64 vadr)
{
	/* If vPSR.ic, IFA, ITIR, IHA */
	set_ifa_itir_iha(vcpu, vadr, 1, 1, 1);
	inject_guest_interruption(vcpu, IA64_DATA_TLB_VECTOR);
}

/*
 * Instruction TLB Fault
 *  @ Instruction TLB vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
itlb_fault (VCPU *vcpu, u64 vadr)
{
	/* If vPSR.ic, IFA, ITIR, IHA */
	set_ifa_itir_iha(vcpu, vadr, 1, 1, 1);
	inject_guest_interruption(vcpu, IA64_INST_TLB_VECTOR);
}

/*
 * Data Nested TLB Fault
 *  @ Data Nested TLB Vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
nested_dtlb (VCPU *vcpu)
{
	inject_guest_interruption(vcpu, IA64_DATA_NESTED_TLB_VECTOR);
}

/*
 * Alternate Data TLB Fault
 *  @ Alternate Data TLB vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
alt_dtlb (VCPU *vcpu, u64 vadr)
{
	set_ifa_itir_iha(vcpu, vadr, 1, 1, 0);
	inject_guest_interruption(vcpu, IA64_ALT_DATA_TLB_VECTOR);
}

/*
 * Data TLB Fault
 *  @ Data TLB vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
alt_itlb (VCPU *vcpu, u64 vadr)
{
	set_ifa_itir_iha(vcpu, vadr, 1, 1, 0);
	inject_guest_interruption(vcpu, IA64_ALT_INST_TLB_VECTOR);
}

/*
 * Deal with:
 *  VHPT Translation Vector
 */
static inline void
_vhpt_fault(VCPU *vcpu, u64 vadr)
{
	/* If vPSR.ic, IFA, ITIR, IHA*/
	set_ifa_itir_iha(vcpu, vadr, 1, 1, 1);
	inject_guest_interruption(vcpu, IA64_VHPT_TRANS_VECTOR);
}

/*
 * VHPT Instruction Fault
 *  @ VHPT Translation vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
ivhpt_fault (VCPU *vcpu, u64 vadr)
{
	_vhpt_fault(vcpu, vadr);
}

/*
 * VHPT Data Fault
 *  @ VHPT Translation vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
dvhpt_fault (VCPU *vcpu, u64 vadr)
{
	_vhpt_fault(vcpu, vadr);
}

/*
 * Deal with:
 *  General Exception vector
 */
static inline void
_general_exception (VCPU *vcpu)
{
	inject_guest_interruption(vcpu, IA64_GENEX_VECTOR);
}

/*
 * Illegal Operation Fault
 *  @ General Exception Vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
illegal_op (VCPU *vcpu)
{
	_general_exception(vcpu);
}

/*
 * Illegal Dependency Fault
 *  @ General Exception Vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
illegal_dep (VCPU *vcpu)
{
	_general_exception(vcpu);
}

/*
 * Reserved Register/Field Fault
 *  @ General Exception Vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
rsv_reg_field (VCPU *vcpu)
{
	_general_exception(vcpu);
}

/*
 * Privileged Operation Fault
 *  @ General Exception Vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
privilege_op (VCPU *vcpu)
{
	_general_exception(vcpu);
}

/*
 * Unimplement Data Address Fault
 *  @ General Exception Vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
unimpl_daddr (VCPU *vcpu)
{
	ISR isr;

	isr.val = set_isr_ei_ni(vcpu);
	isr.code = IA64_UNIMPL_DADDR_FAULT;
	vcpu_set_isr(vcpu, isr.val);
	_general_exception(vcpu);
}

/*
 * Privileged Register Fault
 *  @ General Exception Vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
privilege_reg (VCPU *vcpu)
{
	_general_exception(vcpu);
}

/*
 * Deal with
 *  Nat consumption vector
 * Parameter:
 *  vaddr: Optional, if t == REGISTER
 */
static inline void
_nat_consumption_fault(VCPU *vcpu, u64 vadr, miss_type t)
{
	/* If vPSR.ic && t == DATA/INST, IFA */
	if ( t == DATA || t == INSTRUCTION ) {
		/* IFA */
		set_ifa_itir_iha(vcpu, vadr, 1, 0, 0);
	}

	inject_guest_interruption(vcpu, IA64_NAT_CONSUMPTION_VECTOR);
}

/*
 * IR Data Nat Page Consumption Fault
 *  @ Nat Consumption Vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
#if 0
static inline void
ir_nat_page_consumption (VCPU *vcpu, u64 vadr)
{
	_nat_consumption_fault(vcpu, vadr, DATA);
}
#endif //shadow it due to no use currently 

/*
 * Instruction Nat Page Consumption Fault
 *  @ Nat Consumption Vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
inat_page_consumption (VCPU *vcpu, u64 vadr)
{
	_nat_consumption_fault(vcpu, vadr, INSTRUCTION);
}

/*
 * Register Nat Consumption Fault
 *  @ Nat Consumption Vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
rnat_consumption (VCPU *vcpu)
{
	_nat_consumption_fault(vcpu, 0, REGISTER);
}

/*
 * Data Nat Page Consumption Fault
 *  @ Nat Consumption Vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
dnat_page_consumption (VCPU *vcpu, uint64_t vadr)
{
	_nat_consumption_fault(vcpu, vadr, DATA);
}

/*
 * Deal with
 *  Page not present vector
 */
static inline void
__page_not_present(VCPU *vcpu, u64 vadr)
{
	/* If vPSR.ic, IFA, ITIR */
	set_ifa_itir_iha(vcpu, vadr, 1, 1, 0);
	inject_guest_interruption(vcpu, IA64_PAGE_NOT_PRESENT_VECTOR);
}

static inline void
data_page_not_present(VCPU *vcpu, u64 vadr)
{
	__page_not_present(vcpu, vadr);
}

static inline void
inst_page_not_present(VCPU *vcpu, u64 vadr)
{
	__page_not_present(vcpu, vadr);
}

/*
 * Deal with
 *  Data access rights vector
 */
static inline void
data_access_rights(VCPU *vcpu, u64 vadr)
{
	/* If vPSR.ic, IFA, ITIR */
	set_ifa_itir_iha(vcpu, vadr, 1, 1, 0);
	inject_guest_interruption(vcpu, IA64_DATA_ACCESS_RIGHTS_VECTOR);
}

/*
 * Unimplement Instruction Address Trap
 *  @ Lower-Privilege Transfer Trap Vector
 * Refer to SDM Vol2 Table 5-6 & 8-1
 */
static inline void
unimpl_iaddr_trap (VCPU *vcpu, u64 vadr)
{
	ISR isr;

	isr.val = set_isr_ei_ni(vcpu);
	isr.code = IA64_UNIMPL_IADDR_TRAP;
	vcpu_set_isr(vcpu, isr.val);
	vcpu_set_ifa(vcpu, vadr);
	inject_guest_interruption(vcpu, IA64_LOWERPRIV_TRANSFER_TRAP_VECTOR);
}
#endif

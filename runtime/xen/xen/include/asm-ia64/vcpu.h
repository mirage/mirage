#ifndef _XEN_IA64_VCPU_H
#define _XEN_IA64_VCPU_H

// TODO: Many (or perhaps most) of these should eventually be
// static inline functions

#include <asm/delay.h>
#include <asm/fpu.h>
#include <asm/tlb.h>
#include <asm/ia64_int.h>
#include <asm/privop_stat.h>
#include <xen/types.h>
#include <public/xen.h>
#include <linux/acpi.h>
struct vcpu;
typedef struct vcpu VCPU;
typedef struct cpu_user_regs REGS;

extern u64 cycle_to_ns(u64 cycle);

/* Note: PSCB stands for Privilegied State Communication Block.  */
#define VCPU(_v,_x)	(_v->arch.privregs->_x)
#define PSCB(_v,_x)	VCPU(_v,_x)
#define PSCBX(_v,_x)	(_v->arch._x)
#define FP_PSR(_v)	PSCBX(_v, fp_psr)

#define SPURIOUS_VECTOR 0xf

/* general registers */
extern u64 vcpu_get_gr(VCPU * vcpu, unsigned long reg);
extern IA64FAULT vcpu_get_gr_nat(VCPU * vcpu, unsigned long reg, u64 * val);
extern IA64FAULT vcpu_set_gr(VCPU * vcpu, unsigned long reg, u64 value,
                             int nat);
extern IA64FAULT vcpu_get_fpreg(VCPU * vcpu, unsigned long reg,
                                struct ia64_fpreg *val);

extern IA64FAULT vcpu_set_fpreg(VCPU * vcpu, unsigned long reg,
                                struct ia64_fpreg *val);

/* application registers */
extern void vcpu_load_kernel_regs(VCPU * vcpu);
extern IA64FAULT vcpu_set_ar(VCPU * vcpu, u64 reg, u64 val);
extern IA64FAULT vcpu_get_ar(VCPU * vcpu, u64 reg, u64 * val);
/* psr */
extern BOOLEAN vcpu_get_psr_ic(VCPU * vcpu);
extern u64 vcpu_get_psr(VCPU * vcpu);
extern IA64FAULT vcpu_set_psr(VCPU * vcpu, u64 val);
extern IA64FAULT vcpu_get_psr_masked(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_reset_psr_sm(VCPU * vcpu, u64 imm);
extern IA64FAULT vcpu_set_psr_sm(VCPU * vcpu, u64 imm);
extern IA64FAULT vcpu_set_psr_l(VCPU * vcpu, u64 val);
extern IA64FAULT vcpu_set_psr_i(VCPU * vcpu);
extern IA64FAULT vcpu_reset_psr_dt(VCPU * vcpu);
extern IA64FAULT vcpu_set_psr_dt(VCPU * vcpu);

/**************************************************************************
 VCPU control register access routines
**************************************************************************/

static inline IA64FAULT vcpu_get_dcr(VCPU * vcpu, u64 * pval)
{
	*pval = PSCB(vcpu, dcr);
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_get_iva(VCPU * vcpu, u64 * pval)
{
	if (VMX_DOMAIN(vcpu))
		*pval = PSCB(vcpu, iva) & ~0x7fffL;
	else
		*pval = PSCBX(vcpu, iva) & ~0x7fffL;

	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_get_pta(VCPU * vcpu, u64 * pval)
{
	*pval = PSCB(vcpu, pta);
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_get_ipsr(VCPU * vcpu, u64 * pval)
{
	*pval = PSCB(vcpu, ipsr);
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_get_isr(VCPU * vcpu, u64 * pval)
{
	*pval = PSCB(vcpu, isr);
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_get_iip(VCPU * vcpu, u64 * pval)
{
	*pval = PSCB(vcpu, iip);
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_get_ifa(VCPU * vcpu, u64 * pval)
{
	PRIVOP_COUNT_ADDR(vcpu_regs(vcpu), privop_inst_get_ifa);
	*pval = PSCB(vcpu, ifa);
	return IA64_NO_FAULT;
}

static inline unsigned long vcpu_get_rr_ps(VCPU * vcpu, u64 vadr)
{
	ia64_rr rr;

	rr.rrval = PSCB(vcpu, rrs)[vadr >> 61];
	return rr.ps;
}

static inline unsigned long vcpu_get_rr_rid(VCPU * vcpu, u64 vadr)
{
	ia64_rr rr;

	rr.rrval = PSCB(vcpu, rrs)[vadr >> 61];
	return rr.rid;
}

static inline unsigned long vcpu_get_itir_on_fault(VCPU * vcpu, u64 ifa)
{
	ia64_rr rr;

	rr.rrval = 0;
	rr.ps = vcpu_get_rr_ps(vcpu, ifa);
	rr.rid = vcpu_get_rr_rid(vcpu, ifa);
	return rr.rrval;
}

static inline IA64FAULT vcpu_get_itir(VCPU * vcpu, u64 * pval)
{
	u64 val = PSCB(vcpu, itir);
	*pval = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_get_iipa(VCPU * vcpu, u64 * pval)
{
	u64 val = PSCB(vcpu, iipa);
	*pval = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_get_ifs(VCPU * vcpu, u64 * pval)
{
	*pval = PSCB(vcpu, ifs);
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_get_iim(VCPU * vcpu, u64 * pval)
{
	u64 val = PSCB(vcpu, iim);
	*pval = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_get_iha(VCPU * vcpu, u64 * pval)
{
	PRIVOP_COUNT_ADDR(vcpu_regs(vcpu), privop_inst_thash);
	*pval = PSCB(vcpu, iha);
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_set_dcr(VCPU * vcpu, u64 val)
{
	PSCB(vcpu, dcr) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_set_iva(VCPU * vcpu, u64 val)
{
	if (VMX_DOMAIN(vcpu))
		PSCB(vcpu, iva) = val & ~0x7fffL;
	else
		PSCBX(vcpu, iva) = val & ~0x7fffL;

	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_set_pta(VCPU * vcpu, u64 val)
{
	if (val & (0x3f << 9))	/* reserved fields */
		return IA64_RSVDREG_FAULT;
	if (val & 2)		/* reserved fields */
		return IA64_RSVDREG_FAULT;
	PSCB(vcpu, pta) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_set_ipsr(VCPU * vcpu, u64 val)
{
	PSCB(vcpu, ipsr) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_set_isr(VCPU * vcpu, u64 val)
{
	PSCB(vcpu, isr) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_set_iip(VCPU * vcpu, u64 val)
{
	PSCB(vcpu, iip) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_increment_iip(VCPU * vcpu)
{
	REGS *regs = vcpu_regs(vcpu);
	regs_increment_iip(regs);
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_decrement_iip(VCPU * vcpu)
{
	REGS *regs = vcpu_regs(vcpu);
	struct ia64_psr *ipsr = (struct ia64_psr *)&regs->cr_ipsr;

	if (ipsr->ri == 0) {
		ipsr->ri = 2;
		regs->cr_iip -= 16;
	} else
		ipsr->ri--;

	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_set_ifa(VCPU * vcpu, u64 val)
{
	PSCB(vcpu, ifa) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_set_itir(VCPU * vcpu, u64 val)
{
	PSCB(vcpu, itir) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_set_iipa(VCPU * vcpu, u64 val)
{
	PSCB(vcpu, iipa) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_set_ifs(VCPU * vcpu, u64 val)
{
	PSCB(vcpu, ifs) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_set_iim(VCPU * vcpu, u64 val)
{
	PSCB(vcpu, iim) = val;
	return IA64_NO_FAULT;
}

static inline IA64FAULT vcpu_set_iha(VCPU * vcpu, u64 val)
{
	PSCB(vcpu, iha) = val;
	return IA64_NO_FAULT;
}

/* control registers */
extern IA64FAULT vcpu_set_itm(VCPU * vcpu, u64 val);
extern IA64FAULT vcpu_set_lid(VCPU * vcpu, u64 val);
extern IA64FAULT vcpu_set_tpr(VCPU * vcpu, u64 val);
extern IA64FAULT vcpu_set_eoi(VCPU * vcpu, u64 val);
extern IA64FAULT vcpu_set_lrr0(VCPU * vcpu, u64 val);
extern IA64FAULT vcpu_set_lrr1(VCPU * vcpu, u64 val);
extern IA64FAULT vcpu_get_itm(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_get_itir(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_get_lid(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_get_tpr(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_get_irr0(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_get_irr1(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_get_irr2(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_get_irr3(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_get_lrr0(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_get_lrr1(VCPU * vcpu, u64 * pval);
/* interrupt registers */
extern void vcpu_pend_unspecified_interrupt(VCPU * vcpu);
extern u64 vcpu_check_pending_interrupts(VCPU * vcpu);
extern IA64FAULT vcpu_get_itv(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_get_pmv(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_get_cmcv(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_get_ivr(VCPU * vcpu, u64 * pval);
extern IA64FAULT vcpu_set_itv(VCPU * vcpu, u64 val);
extern IA64FAULT vcpu_set_pmv(VCPU * vcpu, u64 val);
extern IA64FAULT vcpu_set_cmcv(VCPU * vcpu, u64 val);
/* interval timer registers */
extern IA64FAULT vcpu_set_itc(VCPU * vcpu, u64 val);
extern u64 vcpu_timer_pending_early(VCPU * vcpu);
/* debug breakpoint registers */
extern IA64FAULT vcpu_set_ibr(VCPU * vcpu, u64 reg, u64 val);
extern IA64FAULT vcpu_set_dbr(VCPU * vcpu, u64 reg, u64 val);
extern IA64FAULT vcpu_get_ibr(VCPU * vcpu, u64 reg, u64 * pval);
extern IA64FAULT vcpu_get_dbr(VCPU * vcpu, u64 reg, u64 * pval);
/* performance monitor registers */
extern IA64FAULT vcpu_set_pmc(VCPU * vcpu, u64 reg, u64 val);
extern IA64FAULT vcpu_set_pmd(VCPU * vcpu, u64 reg, u64 val);
extern IA64FAULT vcpu_get_pmc(VCPU * vcpu, u64 reg, u64 * pval);
extern IA64FAULT vcpu_get_pmd(VCPU * vcpu, u64 reg, u64 * pval);
/* banked general registers */
extern IA64FAULT vcpu_bsw0(VCPU * vcpu);
extern IA64FAULT vcpu_bsw1(VCPU * vcpu);
/* region registers */
extern IA64FAULT vcpu_set_rr(VCPU * vcpu, u64 reg, u64 val);
extern IA64FAULT vcpu_get_rr(VCPU * vcpu, u64 reg, u64 * pval);
extern IA64FAULT vcpu_get_rr_ve(VCPU * vcpu, u64 vadr);
extern IA64FAULT vcpu_set_rr0_to_rr4(VCPU * vcpu, u64 val0, u64 val1,
				     u64 val2, u64 val3, u64 val4);
/* protection key registers */
extern void vcpu_pkr_load_regs(VCPU * vcpu);
static inline int vcpu_pkr_in_use(VCPU * vcpu)
{
	return (PSCBX(vcpu, pkr_flags) & XEN_IA64_PKR_IN_USE);
}
static inline void vcpu_pkr_use_set(VCPU * vcpu)
{
	PSCBX(vcpu, pkr_flags) |= XEN_IA64_PKR_IN_USE;
}
static inline void vcpu_pkr_use_unset(VCPU * vcpu)
{
	PSCBX(vcpu, pkr_flags) &= ~XEN_IA64_PKR_IN_USE;
}
extern IA64FAULT vcpu_get_pkr(VCPU * vcpu, u64 reg, u64 * pval);
extern IA64FAULT vcpu_set_pkr(VCPU * vcpu, u64 reg, u64 val);
extern IA64FAULT vcpu_tak(VCPU * vcpu, u64 vadr, u64 * key);
/* TLB */
static inline void vcpu_purge_tr_entry(TR_ENTRY * trp)
{
	trp->pte.val = 0;
}
extern IA64FAULT vcpu_itr_d(VCPU * vcpu, u64 slot, u64 padr, u64 itir, u64 ifa);
extern IA64FAULT vcpu_itr_i(VCPU * vcpu, u64 slot, u64 padr, u64 itir, u64 ifa);
extern IA64FAULT vcpu_itc_d(VCPU * vcpu, u64 padr, u64 itir, u64 ifa);
extern IA64FAULT vcpu_itc_i(VCPU * vcpu, u64 padr, u64 itir, u64 ifa);
extern IA64FAULT vcpu_ptc_l(VCPU * vcpu, u64 vadr, u64 log_range);
extern IA64FAULT vcpu_ptc_e(VCPU * vcpu, u64 vadr);
extern IA64FAULT vcpu_ptc_g(VCPU * vcpu, u64 vadr, u64 addr_range);
extern IA64FAULT vcpu_ptc_ga(VCPU * vcpu, u64 vadr, u64 addr_range);
extern IA64FAULT vcpu_ptr_d(VCPU * vcpu, u64 vadr, u64 log_range);
extern IA64FAULT vcpu_ptr_i(VCPU * vcpu, u64 vadr, u64 log_range);
union U_IA64_BUNDLE;
extern int vcpu_get_domain_bundle(VCPU * vcpu, REGS * regs, u64 gip,
                                  union U_IA64_BUNDLE *bundle);
extern IA64FAULT vcpu_translate(VCPU * vcpu, u64 address, BOOLEAN is_data,
                                u64 * pteval, u64 * itir, u64 * iha);
extern IA64FAULT vcpu_tpa(VCPU * vcpu, u64 vadr, u64 * padr);
extern IA64FAULT vcpu_force_inst_miss(VCPU * vcpu, u64 ifa);
extern IA64FAULT vcpu_force_data_miss(VCPU * vcpu, u64 ifa);
extern IA64FAULT vcpu_fc(VCPU * vcpu, u64 vadr);
/* misc */
extern IA64FAULT vcpu_rfi(VCPU * vcpu);
extern IA64FAULT vcpu_thash(VCPU * vcpu, u64 vadr, u64 * pval);
extern IA64FAULT vcpu_cover(VCPU * vcpu);
extern IA64FAULT vcpu_ttag(VCPU * vcpu, u64 vadr, u64 * padr);
extern IA64FAULT vcpu_get_cpuid(VCPU * vcpu, u64 reg, u64 * pval);

extern void vcpu_pend_interrupt(VCPU * vcpu, u64 vector);
extern void vcpu_pend_timer(VCPU * vcpu);
extern void vcpu_poke_timer(VCPU * vcpu);
extern void vcpu_set_next_timer(VCPU * vcpu);
extern BOOLEAN vcpu_timer_expired(VCPU * vcpu);
extern u64 vcpu_deliverable_interrupts(VCPU * vcpu);
struct p2m_entry;
extern void vcpu_itc_no_srlz(VCPU * vcpu, u64, u64, u64, u64, u64,
                             struct p2m_entry *);
extern u64 vcpu_get_tmp(VCPU *, u64);
extern void vcpu_set_tmp(VCPU *, u64, u64);

extern IA64FAULT vcpu_set_dtr(VCPU * vcpu, u64 slot,
                              u64 pte, u64 itir, u64 ifa, u64 rid);
extern IA64FAULT vcpu_set_itr(VCPU * vcpu, u64 slot,
                              u64 pte, u64 itir, u64 ifa, u64 rid);

/* Initialize vcpu regs.  */
extern void vcpu_init_regs(struct vcpu *v);

static inline u64 itir_ps(u64 itir)
{
	return ((itir >> 2) & 0x3f);
}

static inline u64 itir_mask(u64 itir)
{
	return (~((1UL << itir_ps(itir)) - 1));
}

static inline s64 vcpu_get_next_timer_ns(VCPU * vcpu)
{
	s64 vcpu_get_next_timer_ns;
	u64 d = PSCBX(vcpu, domain_itm);
	u64 now = ia64_get_itc();

	if (d > now)
		vcpu_get_next_timer_ns = cycle_to_ns(d - now) + NOW();
	else
		vcpu_get_next_timer_ns =
		    cycle_to_ns(local_cpu_data->itm_delta) + NOW();

	return vcpu_get_next_timer_ns;
}

static inline u64 vcpu_pl_adjust(u64 reg, u64 shift)
{
	u64 pl;

	pl = reg & (3UL << shift);
	if (pl < ((u64)CONFIG_CPL0_EMUL << shift))
		pl = (u64)CONFIG_CPL0_EMUL << shift;
	return (reg & ~(3UL << shift)) | pl;
}

#define verbose(a...) do {if (vcpu_verbose) printk(a);} while(0)

//#define vcpu_quick_region_check(_tr_regions,_ifa) 1
#define vcpu_quick_region_check(_tr_regions,_ifa)           \
    (_tr_regions & (1 << ((unsigned long)_ifa >> 61)))
#define vcpu_quick_region_set(_tr_regions,_ifa)             \
    do {_tr_regions |= (1 << ((unsigned long)_ifa >> 61)); } while (0)

#endif

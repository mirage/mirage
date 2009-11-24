/*
 * Copyright (c) 2007 Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 *
 ******************************************************************************
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */
#include <mini-os/types.h>
#include <mini-os/sched.h>
#include <xen/xen.h>
#include <xen/arch-ia64.h>

#define DEFINE(sym, val)					\
  asm volatile("\n->" sym " %0 /* " #val " */": : "i" (val))
#define DEFINE_STR2(sym, pfx, val)				\
  asm volatile("\n->" sym " " pfx "%0" : : "i"(val));

#define SZ(st,e) sizeof(((st *)0)->e)
#define OFF(st,e,d,o)				\
  DEFINE(#d, offsetof(st, e) + o);		\
  DEFINE(#d "_sz", SZ(st,e ));			\
  DEFINE_STR2(#d "_ld", "ld", SZ(st, e));	\
  DEFINE_STR2(#d "_st", "st", SZ(st, e));			

#define TFOFF(e,d) OFF(trap_frame_t, e, d, 0)
#define SIZE(st,d) DEFINE(#d, sizeof(st))

#define SWOFF(e,d) OFF(struct thread, e, d, 0)

/* shared_info_t from xen/xen.h */
#define SI_OFF(e, d) OFF(shared_info_t, e, d,0)
/* mapped_regs_t from xen/arch-ia64.h */
#define MR_OFF(e, d) OFF(mapped_regs_t, e, d, XMAPPEDREGS_OFS)

int
main(int argc, char ** argv)
{
	TFOFF(cfm, TF_CFM);
	TFOFF(pfs, TF_PFS);
	TFOFF(bsp, TF_BSP);
	TFOFF(rnat, TF_RNAT);
	TFOFF(csd, TF_CSD);
	TFOFF(ccv, TF_CCV);
	TFOFF(unat, TF_UNAT);
	TFOFF(fpsr, TF_FPSR);
	TFOFF(pr, TF_PR);	

	TFOFF(sp, TF_SP);
	TFOFF(gp, TF_GP);
	TFOFF(tp, TF_TP);

	TFOFF(r2, TF_GREG2);
	TFOFF(r3, TF_GREG3);
	TFOFF(r16, TF_GREG16);
	TFOFF(r17, TF_GREG17);

	TFOFF(b0, TF_BREG0);
	TFOFF(b6, TF_BREG6);
	TFOFF(b7, TF_BREG7);

	TFOFF(f6, TF_FREG6);
	TFOFF(f7, TF_FREG7);

	TFOFF(rsc, TF_RSC);
	TFOFF(ndirty, TF_NDIRTY);
	TFOFF(ssd, TF_SSD);
	TFOFF(iip, TF_IIP);
	TFOFF(ipsr, TF_IPSR);
	TFOFF(ifs, TF_IFS);
	TFOFF(trap_num, TF_TRAP_NUM);

	TFOFF(ifa, TF_IFA);
	TFOFF(isr, TF_ISR);
	TFOFF(iim, TF_IIM);

	SIZE(trap_frame_t, TF_SIZE);

	SIZE(struct thread, SW_SIZE);
	SWOFF(regs.unat_b, SW_UNATB);
	SWOFF(regs.sp, SW_SP);
	SWOFF(regs.rp, SW_RP);
	SWOFF(regs.pr, SW_PR);
	SWOFF(regs.pfs, SW_PFS);
	SWOFF(regs.bsp, SW_BSP);
	SWOFF(regs.rnat, SW_RNAT);
	SWOFF(regs.lc, SW_LC);
	//SWOFF(regs.fpsr, SW_FPSR);
	//SWOFF(regs.psr, SW_PSR);
	//SWOFF(regs.gp, SW_GP);
	SWOFF(regs.unat_a, SW_UNATA);
        SWOFF(regs.r4, SW_R4);
        SWOFF(regs.r5, SW_R5);
        SWOFF(regs.r6, SW_R6);
        SWOFF(regs.r7, SW_R7);
        SWOFF(regs.b1, SW_B1);
        SWOFF(regs.b2, SW_B2);
        SWOFF(regs.b3, SW_B3);
        SWOFF(regs.b4, SW_B4);
        SWOFF(regs.b5, SW_B5);
        SWOFF(regs.f2, SW_F2);
        SWOFF(regs.f3, SW_F3);
        SWOFF(regs.f4, SW_F4);
        SWOFF(regs.f5, SW_F5);

	SI_OFF(arch.start_info_pfn, START_INFO_PFN);
	MR_OFF(interrupt_mask_addr, XSI_PSR_I_ADDR_OFS);
	MR_OFF(interrupt_collection_enabled, XSI_PSR_IC_OFS);
	MR_OFF(ipsr, XSI_IPSR_OFS);
	MR_OFF(iip, XSI_IIP_OFS);
	MR_OFF(ifs, XSI_IFS_OFS);
	MR_OFF(ifa, XSI_IFA_OFS);
	MR_OFF(iim, XSI_IIM_OFS);
	MR_OFF(iim, XSI_IIM_OFS);
	MR_OFF(iipa, XSI_IIPA_OFS);
	MR_OFF(isr, XSI_ISR_OFS);
	MR_OFF(banknum, XSI_BANKNUM_OFS);
	MR_OFF(bank1_regs[0], XSI_BANK1_R16_OFS);
	MR_OFF(precover_ifs, XSI_PRECOVER_IFS_OFS);

	return 0;
}

/*
 * Copyright (c) 2007 Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 * Description: ia64 specific trap handling.
 *
 ****************************************************************************
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 * DEALINGS IN THE SOFTWARE.
 *
 */


#include <mini-os/asm.h>
#include <mini-os/page.h>
#include <mini-os/ia64_cpu.h>
#include <mini-os/privop.h>
#include <mini-os/offsets.h>


/* General register usage in interrupt handling:
 *	r16, r17, ... are used for input parameters of sub-routines
 *	r29:	used to access memory which may raise nested TLB fault
 *	r30:	b0 save register
 *	r31:	predicates save register
 *	p30,p31:	used for TLB stuff: (0,1)=data, (1,0)=instruction
 */


#define FILL_FP_PAIR(f1, f2, b1, b2)	\
	ldf.fill	f1=[b1],32	;\
	ldf.fill	f2=[b2],32	;\
	;;

#define SPILL_FP_PAIR(f1, f2, b1, b2)	\
	stf.spill	[b1]=f1,32	;\
	stf.spill	[b2]=f2,32	;\
	;;

#define FILL_REG_PAIR(r1, r2, b1, b2)	\
	ld8.fill	r1=[b1],16	;\
	ld8.fill	r2=[b2],16	;\
	;;

#define SPILL_REG_PAIR(r1, r2, b1, b2)	\
	.mem.offset 0,0			;\
	st8.spill	[b1]=r1,16	;\
	.mem.offset 8,0			;\
	st8.spill	[b2]=r2,16	;\
	;;


/**
 *	The function does a store of the current processor context
 *	to the given exception frame address.
 *	These are some special and the scratch registers for calling
 *	C-functions later.
 *	The bspstore will be the same. A clean RSE is made with the
 *	cover instruction.
 *	
 *	The return is done through a jump to the next bundle after ip (r16).
 *
 *	Used register: r16, r18, r19, r20, r21, r22 of bank 0
 *
 * 	@param: r16 ip of the bundle with the jump.
 *	@param: r18 pointer to the trap frame.
 *	@param: r23 trap number/err val
 *
 */

ENTRY(save_tf_rse_switch)
	movl	r21=XSI_IPSR		// XEN !!
	movl	r22=XSI_IIP		// XEN !!
	;;
	ld8	r21=[r21]		// XEN.ipsr
	ld8	r22=[r22];;		// XEN.iip
	add	r19=TF_IPSR,r18
	add	r20=TF_IIP,r18
	;;
	st8	[r19]=r21		// store cr.ipsr
	st8	[r20]=r22		// store cr.iip
	;;
	//// r16 return jump pointer, r18 - trap frame base, 
	add	r19=TF_UNAT,r18
	mov	r20=ar.unat
	;;
	st8	[r19]=r20		// store scratch unat
	;;

	add	r19=TF_GP,r18
	add	r20=TF_SP,r18
	;;
	st8	[r19]=gp,TF_TP-TF_GP	// store gp
	st8	[r20]=sp,TF_PR-TF_SP	// store sp
	mov	r21=pr
	;;
	st8	[r19]=r13		// store tp
	st8	[r20]=r21		// store pr
	;;
	add	r19=TF_GREG2,r18	// Now first general regs.
	add	r20=TF_GREG3,r18
	;;
	SPILL_REG_PAIR( r2, r3,r19,r20)
	SPILL_REG_PAIR( r8, r9,r19,r20)
	SPILL_REG_PAIR(r10,r11,r19,r20)
	SPILL_REG_PAIR(r14,r15,r19,r20)
	;;
	mov	r14=r18		// move trap frame base for bsw
	mov	r15=r16		// save return address
	;;
	//bsw.1		// switch to bank 1 for saving these registers.
	movl r30=XSI_BANKNUM		// Switch to bank 1.
	mov r31=1;;
	st4 [r30]=r31
	;;
	/*
	 * On XEN the hypervisor has stored the bank 1 registers
	 * r16-r31. I must reload these registers here to get
	 * access.
	 */
	movl r30=XSI_BANK1_R16;
	movl r31=XSI_BANK1_R16+8;; 
	ld8 r16=[r30],16; ld8 r17=[r31],16;;
	ld8 r18=[r30],16; ld8 r19=[r31],16;;
	ld8 r20=[r30],16; ld8 r21=[r31],16;;
	ld8 r22=[r30],16; ld8 r23=[r31],16;;
	ld8 r24=[r30],16; ld8 r25=[r31],16;;
	ld8 r26=[r30],16; ld8 r27=[r31],16;;
	ld8 r28=[r30],16; ld8 r29=[r31],16;;
	ld8 r30=[r30]; ld8 r31=[r31];;
	add	r2=TF_GREG16,r14
	add	r3=TF_GREG17,r14
	;;
	SPILL_REG_PAIR(r16,r17,r2,r3)
	SPILL_REG_PAIR(r18,r19,r2,r3)
	SPILL_REG_PAIR(r20,r21,r2,r3)
	SPILL_REG_PAIR(r22,r23,r2,r3)
	SPILL_REG_PAIR(r24,r25,r2,r3)
	SPILL_REG_PAIR(r26,r27,r2,r3)
	SPILL_REG_PAIR(r28,r29,r2,r3)
	SPILL_REG_PAIR(r30,r31,r2,r3)
	;;
	//bsw.0				// back to interrupt bank 0
	movl r2=XSI_BANKNUM;;
	st4 [r2]=r0
	;;
	mov	r18=r14			// restore context pointer
	mov	r16=r15			// restore return address
	;;
	//// r16 return jump pointer, r18 - trap frame base, 
	add	r19=TF_CCV,r18
	add	r20=TF_CSD,r18
	mov	r21=ar.ccv
	mov	r22=ar.csd
	;;
	st8	[r19]=r21		// ar.ccv
	st8	[r20]=r22		// ar.csd
	;;
	add	r19=TF_SSD,r18
	mov	r21=ar.ssd
	;;
	st8	[r19]=r21		// ar.ssd
	;;
	add	r19=TF_FREG6,r18
	add	r20=TF_FREG7,r18
	;;
	SPILL_FP_PAIR(f6, f7, r19, r20)
	SPILL_FP_PAIR(f8, f9, r19, r20)
	SPILL_FP_PAIR(f10, f11, r19, r20)

	add	r19=TF_BREG0,r18	// b0, b6, b7
	add	r20=TF_BREG6,r18
	mov	r21=b0
	mov	r22=b6
	;;
	st8	[r19]=r21,TF_BREG7-TF_BREG0	// store b0
	st8	[r20]=r22,16		// store b6
	;;
	mov	r21=b7
	;;
	st8	[r19]=r21		// store b7

	//// r16 return jump pointer, r18 - trap frame base, 

		// Read and save RSC, PFS
	add	r19=TF_PFS,r18
	add	r20=TF_RSC,r18
	mov	r21=ar.pfs
	mov	r22=ar.rsc
	;;
{	.mmb
	st8	[r19]=r21		// store ar.pfs
	st8	[r20]=r22		// store ar.rsc
		// Issue cover instruction
	cover		// must be the last instruction in bundle
	//XEN_HYPER_COVER
	;;
}
		// Read and save IFS
	add	r19=TF_IFS,r18
	add	r20=TF_CFM,r18
		/* xen special handling for possibly lazy cover */
	movl	r8=XSI_PRECOVER_IFS;
	;;
	ld8	r21=[r8]
	;;
	st8	[r19]=r21		// store cr.ifs
	dep.z	r22=r21,0,38		// copy ifm part from ifs.ifm
	;;
	st8	[r20]=r22		// store cfm
		// RSE in enforced lazy mode
	mov	ar.rsc=IA64_RSE_LAZY
	;;
		// Read and save BSPSTORE and RNAT
	add	r19=TF_BSP,r18
	add	r20=TF_RNAT,r18
	mov	r21=ar.bspstore
	mov	r22=ar.rnat
	;;
	st8	[r19]=r21	                // store ar.bspstore
	st8	[r20]=r22			// store ar.rnat
	;;
		// Write new BSPSTORE
	//mov	r21=ar.bsp
	//;;
	mov	r22=r21			// new bspstore equal to old
	;;
	mov	ar.bspstore=r22		// the new bspstore
	;;
		// Read and save the new BSP for calculating number of dirty regs.
	mov	r21=ar.bsp
	;;
	sub	r21=r21,r22		// r21 -> ndirty
	add     r19=TF_NDIRTY-TF_BSP,r19        // TF_NDIRTY pos in r19
	;;
	st8	[r19]=r21		// store ndirty
	;;
	mov	ar.rsc=IA64_RSE_EAGER	// RSE on again
	;;
	add	r19=TF_FPSR,r18
	;;
	mov	r21=ar.fpsr
	;;
	st8	[r19]=r21		// ar.fpsr
	;;
	//// r16 return jump pointer, r18 - trap frame base, 
		// Load the gp with our module __gp
	movl	gp=__gp
	;;
	add	r16=16,r16	// for jump to next bundle
	;;
	mov	b7=r16
	;;

{	.mfb
	srlz.d
	nop	0
	br.sptk	b7
	;;
}

END(save_tf_rse_switch)


/**
 *	The function reloads the processor context stored in
 *	save_tf_rse_switch().
 *	
 *	On calling the function the bank 0 must be activ.
 *	The return is done through a rfi.
 *	Used register: b7, r16, r18, r19, r20, r21, r22 of bank 0
 *
 *	@param: r18 pointer to the exception frame
 *
 */
ENTRY(restore_tf_rse_switch) 
	add	r19=TF_IPSR,r18
	add	r20=TF_IIP,r18
	;;
	ld8	r21=[r19]		// load cr.ipsr
	ld8	r22=[r20]		// load cr.iip
	movl	r16=XSI_IPSR		// XEN !!
	;;
	st8	[r16]=r21,XSI_IIP_OFS-XSI_IPSR_OFS	// XEN.ipsr
	mov	r2=r21			// save for fp stuff below
	;;
	st8	[r16]=r22		// XEN.iip
	;;
	//// r18 - trap frame base 
		// Allocate a zero sized frame
	alloc	r30=ar.pfs,0,0,0,0	// discard current frame
	;;
		// calc number of dirty regs and put this into rsc.loardrs
	add	r19=TF_NDIRTY,r18
	;;
	ld8	r22=[r19]		// ndirty
	;;
	shl	r21=r22,16		// value for ar.rsc
	;;
	mov	ar.rsc=r21		// setup for loadrs
	;;
		// Issue a loadrs instruction
{	.mmi
	loadrs		// must be the first instruction
	;;
	nop 0x0
	nop 0x0
}
		// Restore BSPSTORE from interrupted context
	add	r19=TF_BSP,r18
	add	r20=TF_RNAT,r18
	;;	
	ld8	r21=[r19]		// load ar.bspstore
	ld8	r22=[r20]		// load ar.rnat
	;;
	mov	ar.bspstore=r21		// set ar.bspstore
	;;
		// Restore RNAT
	mov	ar.rnat=r22		// set ar.rnat
	;;
		// Restore PFS and IFS
	add	r19=TF_PFS,r18
	add	r20=TF_IFS,r18
	movl	r16=XSI_IFS		// XEN !!
	;;
	ld8	r21=[r19]		// load ar.pfs
	ld8	r22=[r20]		// load cr.ifs
	;;
	add	r19=TF_RSC,r18
	mov	ar.pfs=r21
	st8	[r16]=r22		// XEN.ifs
	;;
		// Restore RSC
	ld8	r21=[r19]		// load ar.rsc
	;;
	mov	ar.rsc=r21		// set ar.rsc
	//// r18 - trap frame base
	add	r19=TF_GP,r18
	add	r20=TF_SP,r18
	;;
	ld8	gp=[r19],TF_TP-TF_GP	// load gp
	ld8	sp=[r20],TF_PR-TF_SP	// load sp
	;;
	ld8	r13=[r19]		// load tp
	ld8	r21=[r20]		// load pr
	;;
	mov	pr=r21,-1		// set pr
	;;
	add	r19=TF_BREG0,r18
	add	r20=TF_BREG6,r18
	;;
	ld8	r21=[r19],TF_BREG7-TF_BREG0	// load b0
	ld8	r22=[r20],16		// load b6
	;;
	mov	b0=r21
	mov	b6=r22
	;;
	ld8	r21=[r19]		// load b7
	ld8	r22=[r20],16		// load b3
	;;
	mov	b7=r21
	//// r18 - trap frame base
	mov	r14=r18			// Save the context pointer
	;;
	// bsw.1
	movl r30=XSI_BANKNUM		// Switch to bank 1.
	mov r31=1;;
	st4 [r30]=r31
	;;
	add	r2=TF_GREG16,r14
	add	r3=TF_GREG17,r14
	;;
	FILL_REG_PAIR(r16,r17,r2,r3)
	FILL_REG_PAIR(r18,r19,r2,r3)
	FILL_REG_PAIR(r20,r21,r2,r3)
	FILL_REG_PAIR(r22,r23,r2,r3)
	FILL_REG_PAIR(r24,r25,r2,r3)
	FILL_REG_PAIR(r26,r27,r2,r3)
	FILL_REG_PAIR(r28,r29,r2,r3)
	FILL_REG_PAIR(r30,r31,r2,r3)

	/*
	 * On XEN I have to store the bank 1 register into the
	 * global XSI_... area.
	 */
		// r16-r31 all now hold bank1 values
	movl r2=XSI_BANK1_R16
	movl r3=XSI_BANK1_R16+8
	;;
	.mem.offset 0,0; st8.spill [r2]=r16,16
	.mem.offset 8,0; st8.spill [r3]=r17,16
	;;
	.mem.offset 0,0; st8.spill [r2]=r18,16
	.mem.offset 8,0; st8.spill [r3]=r19,16
	;;
	.mem.offset 0,0; st8.spill [r2]=r20,16
	.mem.offset 8,0; st8.spill [r3]=r21,16
	;;
	.mem.offset 0,0; st8.spill [r2]=r22,16
	.mem.offset 8,0; st8.spill [r3]=r23,16
	;;
	.mem.offset 0,0; st8.spill [r2]=r24,16
	.mem.offset 8,0; st8.spill [r3]=r25,16
	;;
	.mem.offset 0,0; st8.spill [r2]=r26,16
	.mem.offset 8,0; st8.spill [r3]=r27,16
	;;
	.mem.offset 0,0; st8.spill [r2]=r28,16
	.mem.offset 8,0; st8.spill [r3]=r29,16
	;;
	.mem.offset 0,0; st8.spill [r2]=r30,16
	.mem.offset 8,0; st8.spill [r3]=r31,16
	;;
	// bsw.0
	movl r2=XSI_BANKNUM;;
	st4 [r2]=r0;

	mov	r18=r14			// Move back the context pointer
	;;
	add	r19=TF_GREG2,r18
	add	r20=TF_GREG3,r18
	;;
	FILL_REG_PAIR( r2, r3,r19,r20)
	FILL_REG_PAIR( r8, r9,r19,r20)
	FILL_REG_PAIR(r10,r11,r19,r20)
	FILL_REG_PAIR(r14,r15,r19,r20)

	//// r18 - trap frame base, 

	add	r19=TF_CCV,r18
	add	r20=TF_CSD,r18
	;;
	ld8	r21=[r19]		// ar.ccv
	ld8	r22=[r20]		// ar.csd
	;;
	mov	ar.ccv=r21
	mov	ar.csd=r22
	add	r19=TF_SSD,r18
	;;
	ld8	r21=[r19]		// ar.ssd
	;;
	mov	ar.ssd=r21
	add	r19=TF_FREG6,r18
	add	r20=TF_FREG7,r18
	;;
	FILL_FP_PAIR(f6, f7, r19, r20)
	FILL_FP_PAIR(f8, f9, r19, r20)
	FILL_FP_PAIR(f10, f11, r19, r20)
	add	r19=TF_FPSR,r18
	;;
	ld8	r21=[r19]		// ar.fpsr
	;;
	mov	ar.fpsr=r21
	add	r19=TF_UNAT,r18
	;;
	ld8	r21=[r19]
	;;
	mov	ar.unat=r21
	;;
	srlz.i
	;;
	//rfi
	XEN_HYPER_RFI;
	;;
END(restore_tf_rse_switch)


ENTRY(save_special_regs)
	alloc	loc0=ar.pfs,1,7,0,0
	movl	loc1=XSI_IFA		// XEN !!
	movl	loc2=XSI_ISR		// XEN !!
	;;
	ld8	loc3=[loc1],XSI_IIM_OFS-XSI_IFA_OFS	// load XEN.ifa
	ld8	loc4=[loc2],XSI_IIPA_OFS-XSI_ISR_OFS	// load XEN.isr
	add	loc5=TF_IFA,in0
	add	loc6=TF_ISR,in0
	;;
	st8	[loc5]=loc3,TF_IIM-TF_IFA	// store cr.ifa
	st8	[loc6]=loc4			// store cr.isr
	;;
	ld8	loc3=[loc1]			// load XEN.iim
	;;
	st8	[loc5]=loc3			// store cr.iim
	;;
	mov	ar.pfs=loc0
	;;
	br.ret.sptk.few rp
END(save_special_regs)


ENTRY(hypervisor_callback)
	/*
	 * Use the thread stack here for storing the trap frame.
	 * It's not wired mapped, so nested data tlb faults may occur!
	 */
	add	r18=-TF_SIZE,sp
	;;
{	.mib
	nop	0x02
	mov	r16=ip		// for jump back from save_tf_rse_switch
	br.sptk	save_tf_rse_switch
	;;
}
	add	sp=-16,r18		// the new stack
	alloc	r15=ar.pfs,0,0,1,0	// 1 out for do_hypervisor_callback
	;;
	mov	out0=r18		// the trap frame
	movl	r22=XSI_PSR_IC
	mov	r23=1;;
	st8	[r22]=r23		// ssm psr.ic
	;;
	br.call.sptk.few rp = do_hypervisor_callback

	movl	r22=XSI_PSR_IC
	;;
	st4	[r22]=r0		// rsm psr.ic
	add	r18=16,sp		// load EF-pointer again
	;;
			// must have r18-efp, calls rfi at the end.
	br.sptk	restore_tf_rse_switch
	;;
END(hypervisor_callback)

	/*
	 * In: r30 - trap number
	 */
ENTRY(trap_error)
		// Calculate the stack address for storing.
	add	r18=-TF_SIZE,sp
	;;
	add	r20=TF_TRAP_NUM,r18
	;;
	st2	[r20]=r30	// save trap number
	;;

{	.mib
	nop	0x02
	mov	r16=ip		// for jumping back from save_tf_rse_switch
		// Used register: r16, r18, r19, r20, r21, r22 of bank 0
	br.sptk	save_tf_rse_switch
	;;
}

	alloc	r15=ar.pfs,0,0,1,0	// 1 out for do_trap_error
	;;
	mov	out0=r18		// the trap frame
	add	sp=-16,r18		// C-call abi
	;;
	movl r30=XSI_BANKNUM		// bsw.1
	mov r31=1;;
	st4 [r30]=r31;;

		/* Save extra interrupt registers to the trap frame. */
	br.call.sptk.few rp = save_special_regs
	;;

	movl	r22=XSI_PSR_IC
	movl	r23=XSI_PSR_I_ADDR
	;;
	ld8	r23=[r23]
	mov	r25=1
	;;
	st4	[r22]=r25		// ssm psr.ic
	st1	[r23]=r0		// ssm psr.i
	;;

	br.call.sptk.few rp = do_trap_error
	;;
		// --> currently not reached!!!
	movl r23=XSI_PSR_I_ADDR
	movl r22=XSI_PSR_IC
	;;
	ld8 r23=[r23]
	mov r25=1
	;;
	st1 [r23]=r25
	st4 [r22]=r0            // note: clears both vpsr.i and vpsr.ic!
	;;
	bsw.0
	;;
	add	r18=16,sp		// load EF-pointer again
	;;
	mov	sp=r18
			// must have r18-efp, calls rfi at the end.
	br.sptk	restore_tf_rse_switch
	;;
END(trap_error)


/*
 * The trap handler stuff.
 */

#define TRAP_ERR(num)			\
	mov	r30 = num;		\
	;;		;		\
	br.sptk	trap_error		\
	;;

#define	IVT_ENTRY(name, offset)			\
	.org	ia64_trap_table + offset;	\
	.global	hivt_##name;			\
	.proc	hivt_##name;			\
	.prologue;				\
	.body;					\
hivt_##name:

#define	IVT_END(name)				\
	.endp	hivt_##name;			\
	.align	0x100

#define IVT_ERR(name, num, offset)		\
	IVT_ENTRY(name, offset);		\
	TRAP_ERR(num);				\
	IVT_END(name)
/*
 * The IA64 Interrupt Vector Table (IVT) contains 20 slots with 64
 * bundles per vector and 48 slots with 16 bundles per vector.
 */

	.section .text.hivt,"ax"
	.align	32768
	.global ia64_trap_table
	.size	ia64_trap_table, 32768
ia64_trap_table:

IVT_ERR(VHPT_Translation, 0, 0x0)
IVT_ERR(Instruction_TLB, 1, 0x0400)
IVT_ERR(Data_TLB, 2, 0x0800)
IVT_ERR(Alternate_Instruction_TLB, 3, 0x0c00)


IVT_ENTRY(Alternate_Data_TLB, 0x1000)
	mov	r30=4			// trap number
adt_common:
	mov	r16=cr.ifa		// where did it happen
	mov	r31=pr			// save predicates
	;;
	extr.u	r17=r16,IA64_RR_IDX_POS,3	// get region number
	;;
	cmp.eq	p14,p15=7,r17
	;;
//(p14)	br.sptk adt_regf_addr		// Check for region 7 - phys addresses
//	;;
//	br.sptk	trap_error
//		// No return
//
//adt_regf_addr:
//	extr.u	r17=r16,60,4		// get region number
//	;;
//	cmp.eq	p14,p15=0xf,r17
//	;;
(p14)	br.sptk adt_reg7_addr		// Check for region 7 - phys addresses
	;;
	br.sptk	trap_error

adt_reg7_addr:
	/*
	 * region 7 addresses are only directly mapped physically
	 * addresses. Currently I don't do a check.
	 */
	movl	r20=~((7 << IA64_RR_IDX_POS) | 0xfff)
	movl	r18=((PTE_PS_16K<<IA64_ITIR_PS)|(IA64_KEY_REG7<<IA64_ITIR_KEY))
	;;
	movl	r19=	((1<<PTE_OFF_P) | (PTE_MA_WB<<PTE_OFF_MA) | \
			 (1<<PTE_OFF_A) | (1<<PTE_OFF_D) | \
			 (PTE_PL_KERN<<PTE_OFF_PL) | (PTE_AR_RW<<PTE_OFF_AR))
			// clear the region bits and 0-11
			// extract the pfn from the ifa
	mov	cr.itir=r18
	and	r20=r20, r16
	;;
	or	r20=r20,r19		// put pfn into pte
	;;
	mov	pr=r31,-1		// restore predicates
	itc.d	r20
	;;
	XEN_HYPER_RFI;
	;;

IVT_END(Alternate_Data_TLB)

/*
 * Handling of nested data tlb is needed, because in hypervisor_callback()
 * the stack is used to store the register trap frame. This stack is allocated
 * dynamically (as identity mapped address) and therewidth no tr mapped page!
 */
IVT_ENTRY(Data_Nested_TLB, 0x1400)

	mov	r30=5			// trap number
	add	r28=-TF_SIZE,sp		// r28 is never used in trap handling
	;;
	mov	cr.ifa=r28
	;;
	br.sptk	adt_common
IVT_END(Data_Nested_TLB)



IVT_ERR(Instruction_Key_Miss, 6, 0x1800)
IVT_ERR(Data_Key_Miss, 7, 0x1c00)
IVT_ERR(Dirty_Bit, 8, 0x2000)
IVT_ERR(Instruction_Access_Bit, 9, 0x2400)
IVT_ERR(Data_Access_Bit, 10, 0x2800)
IVT_ERR(Break_Instruction, 11, 0x2c00)
IVT_ERR(External_Interrupt, 12, 0x3000)
IVT_ERR(Reserved_3400, 13, 0x3400)
IVT_ERR(Reserved_3800, 14, 0x3800)
IVT_ERR(Reserved_3c00, 15, 0x3c00)
IVT_ERR(Reserved_4000, 16, 0x4000)
IVT_ERR(Reserved_4400, 17, 0x4400)
IVT_ERR(Reserved_4800, 18, 0x4800)
IVT_ERR(Reserved_4c00, 19, 0x4c00)
IVT_ERR(Page_Not_Present, 20, 0x5000)
IVT_ERR(Key_Permission, 21, 0x5100)
IVT_ERR(Instruction_Access_Rights, 22, 0x5200)
IVT_ERR(Data_Access_Rights, 23, 0x5300)
IVT_ERR(General_Exception, 24, 0x5400)
IVT_ERR(Disabled_FP_Register, 25, 0x5500)
IVT_ERR(NaT_Consumption, 26, 0x5600)
IVT_ERR(Speculation, 27, 0x5700)
IVT_ERR(Reserved_5800, 28, 0x5800)
IVT_ERR(Debug, 29, 0x5900)
IVT_ERR(Unaligned_Reference, 30, 0x5a00)
IVT_ERR(Unsupported_Data_Reference, 31, 0x5b00)
IVT_ERR(Floating_Point_Fault, 32, 0x5c00)
IVT_ERR(Floating_Point_Trap, 33, 0x5d00)
IVT_ERR(Lower_Privilege_Transfer_Trap, 34, 0x5e00)
IVT_ERR(Taken_Branch_Trap, 35, 0x5f00)
IVT_ERR(Single_Step_Trap, 36, 0x6000)
IVT_ERR(Reserved_6100, 37, 0x6100)
IVT_ERR(Reserved_6200, 38, 0x6200)
IVT_ERR(Reserved_6300, 39, 0x6300)
IVT_ERR(Reserved_6400, 40, 0x6400)
IVT_ERR(Reserved_6500, 41, 0x6500)
IVT_ERR(Reserved_6600, 42, 0x6600)
IVT_ERR(Reserved_6700, 43, 0x6700)
IVT_ERR(Reserved_6800, 44, 0x6800)
IVT_ERR(IA_32_Exception, 45, 0x6900)
IVT_ERR(IA_32_Intercept, 46, 0x6a00)
IVT_ERR(IA_32_Interrupt, 47, 0x6b00)
IVT_ERR(Reserved_6c00, 48, 0x6c00)
IVT_ERR(Reserved_6d00, 49, 0x6d00)
IVT_ERR(Reserved_6e00, 50, 0x6e00)
IVT_ERR(Reserved_6f00, 51, 0x6f00)
IVT_ERR(Reserved_7000, 52, 0x7000)
IVT_ERR(Reserved_7100, 53, 0x7100)
IVT_ERR(Reserved_7200, 54, 0x7200)
IVT_ERR(Reserved_7300, 55, 0x7300)
IVT_ERR(Reserved_7400, 56, 0x7400)
IVT_ERR(Reserved_7500, 57, 0x7500)
IVT_ERR(Reserved_7600, 58, 0x7600)
IVT_ERR(Reserved_7700, 59, 0x7700)
IVT_ERR(Reserved_7800, 60, 0x7800)
IVT_ERR(Reserved_7900, 61, 0x7900)
IVT_ERR(Reserved_7a00, 62, 0x7a00)
IVT_ERR(Reserved_7b00, 63, 0x7b00)
IVT_ERR(Reserved_7c00, 64, 0x7c00)
IVT_ERR(Reserved_7d00, 65, 0x7d00)
IVT_ERR(Reserved_7e00, 66, 0x7e00)
IVT_ERR(Reserved_7f00, 67, 0x7f00)

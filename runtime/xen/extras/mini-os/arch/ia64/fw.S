/*
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 * Parts taken from FreeBSD.
 *
 ***************************************************************************
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


#include <mini-os/asm.h>
#include <mini-os/page.h>
#include <mini-os/ia64_cpu.h>
#include <mini-os/ia64_fpu.h>
#include <mini-os/offsets.h>
#include <mini-os/xen/xen.h>


/*
 * ia64_change_mode:	change mode to/from physical mode
 *
 * Arguments:
 *	r14	psr for desired mode
 *
 * Modifies:
 *	r15-r20	scratch
 *	ar.bsp	translated to new mode
 *	sp	translated to new mode
 *	iip	translated to new mode
 */
ENTRY(ia64_change_mode)
	rsm	psr.i | psr.ic
	mov	r19=ar.rsc		// save rsc while we change mode
	tbit.nz	p8,p9=r14,17		// Uses psr.dt-physical or virtual ?
			// p8 == true: switch to virtual
			// p9 == true: switch to physical
	;;
	mov	ar.rsc=IA64_RSE_LAZY	// turn off RSE
	mov	r16=rp
	;;
	flushrs				// clean the rse
	srlz.i
	;;
1:	mov	r15=ip
	mov	r17=ar.bsp
	mov	r18=ar.rnat
	;;
	add	r15=2f-1b,r15		// address to rfi to
		/* !!! must be the same like in  minios-ia64.lds */
(p8)	movl	r20=(KERNEL_START - (1<<KERNEL_PHYS_START_SHIFT))
	;;
			// (p8): switch to virtual
			// (p9): switch to physical

		// from virtual to physical
(p9)	tpa	r15=r15			// ip
(p9)	tpa	r16=r16			// rp
(p9)	tpa	r17=r17			// ar.bsp
(p9)	tpa	sp=sp			// sp
	;;		/* Needed only for assembler violate ... warnings. */
		// from physical to virtual
(p8)	add	r15=r20,r15		// ip
(p8)	add	r16=r20,r16		// rp
(p8)	add	r17=r20,r17		// ar.bsp
(p8)	add	sp=r20,sp		// sp
	;;
	mov	ar.bspstore=r17
	mov	rp=r16
	;;
	mov	ar.rnat=r18
	mov	cr.iip=r15
	mov	cr.ipsr=r14		// psr for new mode
	mov	cr.ifs=r0
	;;
	rfi
	;;
2:	mov	ar.rsc=r19		// restore ar.rsc
	;;
	br.ret.sptk.few rp		// now in new mode
END(ia64_change_mode)

/*
 * ia64_physical_mode:  change mode to physical mode
 *
 * Return:
 *  ret0  psr to restore
 *
 * Modifies:
 *  r15-r18 scratch
 *  ar.bsp  tranlated to physical mode
 *  psr.i cleared
 */
ENTRY(ia64_physical_mode)
	mov	r14=psr
	movl	r15=(IA64_PSR_I|IA64_PSR_IT|IA64_PSR_DT|	\
			IA64_PSR_RT|IA64_PSR_DFL|IA64_PSR_DFH)
	;;
	mov	ret0=r14
	movl	r16=IA64_PSR_BN
	;;
	andcm	r14=r14,r15	// clear various xT bits
	;;
	or	r14=r14,r16	// make sure BN=1
	or	ret0=ret0,r16	// make sure BN=1
	;;
	br.cond.sptk.many ia64_change_mode
END(ia64_physical_mode)

/*
 * ia64_call_efi_physical:	call an EFI procedure in physical mode
 *
 * Arguments:
 *	in0		Address of EFI procedure descriptor
 *	in1-in5		Arguments to EFI procedure
 *
 * Return:
 *	ret0-ret3	return values from EFI
 *
 */
ENTRY(ia64_call_efi_physical)
	.prologue
	.regstk	6,4,5,0
	.save	ar.pfs,loc0
	alloc	loc0=ar.pfs,6,4,5,0
	;;
	.save	rp,loc1
	mov	loc1=rp
	;;
	.body
	br.call.sptk.many rp=ia64_physical_mode
	;;

	mov	loc2=r8			// psr to restore mode
	mov	loc3=gp			// save kernel gp
	ld8	r14=[in0],8		// function address
	;;
	ld8	gp=[in0]		// function gp value
	mov	out0=in1
	mov	out1=in2
	mov	out2=in3
	mov	out3=in4
	mov	out4=in5
	mov	b6=r14
	;;
	br.call.sptk.many rp=b6		// call EFI procedure
	mov	gp=loc3			// restore kernel gp
	mov	r14=loc2		// psr to restore mode
	;;
	br.call.sptk.many rp=ia64_change_mode
	;;
	mov	rp=loc1
	mov	ar.pfs=loc0
	;;
	br.ret.sptk.many rp
END(ia64_call_efi_physical)
	

/*
 * struct ia64_pal_result ia64_call_pal_static(uint64_t proc,
 *	uint64_t arg1, uint64_t arg2, uint64_t arg3)
 */
ENTRY(ia64_call_pal_static)
	
	.regstk	4,5,0,0
palret	=	loc0
entry	=	loc1
rpsave	=	loc2
pfssave =	loc3
psrsave	=	loc4

	alloc	pfssave=ar.pfs,4,5,0,0
	;; 
	mov	rpsave=rp

	movl	entry=@gprel(ia64_pal_entry)
1:	mov	palret=ip		// for return address
	;;
	add	entry=entry,gp
	mov	psrsave=psr
	mov	r28=in0			// procedure number
	;;
	ld8	entry=[entry]		// read entry point
	mov	r29=in1			// copy arguments
	mov	r30=in2
	mov	r31=in3
	;;
	mov	b6=entry
	add	palret=2f-1b,palret	// calculate return address
	;;
	mov	b0=palret
	rsm	psr.i			// disable interrupts
	;;
	br.cond.sptk b6			// call into firmware
	;;
	ssm	psr.i			// enable interrupts
	;;
2:	mov	psr.l=psrsave
	mov	rp=rpsave
	mov	ar.pfs=pfssave
	;;
	srlz.d
	br.ret.sptk rp

END(ia64_call_pal_static)

/*
 * Call a efi function.
 * in0: func descriptor
 * in1: param1
 * ...
 * in5: param5
 */
ENTRY(ia64_call_efi_func)
	alloc	loc0=ar.pfs,6,3,5,0

	mov	loc1=gp
	mov	loc2=rp

	mov	out0=in1
	mov	out1=in2
	mov	out2=in3
	mov	out3=in4
	mov	out4=in5

	ld8	r14=[in0],8		// get function address
	;;
	ld8	gp=[in0]		// function gp value
	;;
	mov	b6=r14
	br.call.sptk.many rp=b6		// call EFI procedure
	
	mov	ar.pfs=loc0
	mov	gp=loc1
	mov	rp=loc2
	br.ret.sptk rp

END(ia64_call_efi_func)


/* Restore the context from the thread context.
 */
ENTRY(restore_context)
{	.mmi
	invala
	mov	ar.rsc=IA64_RSE_LAZY
	add	r29=SW_SP,in0
}
	add	r30=SW_RP,in0
	add	r31=SW_PR,in0
	;;
	ld8	r12=[r29],SW_LC-SW_SP		// load sp
	ld8	r16=[r30],SW_BSP-SW_RP		// load rp
	;;
	ld8	r17=[r31],SW_RNAT-SW_PR		// load pr
	ld8	r18=[r30],SW_PFS-SW_BSP		// load bsp
	mov	rp=r16
	;;
	ld8	r16=[r31],SW_R4-SW_RNAT		// load rnat
	mov	pr=r17,-1			// set pr
	mov	ar.bspstore=r18
	;;
	ld8	r18=[r30],SW_UNATA-SW_PFS	// load pfs
	ld8	r17=[r29],SW_UNATB-SW_LC	// load lc
	mov	ar.rnat=r16
	;;
	ld8	r16=[r30],SW_R5-SW_UNATA	// load unat_a
	mov	ar.pfs=r18
	mov	ar.lc=r17
	;;
	ld8.fill r4=[r31],SW_R6-SW_R4		// load r4
	mov	ar.unat=r16
	;;
	ld8.fill r5=[r30],SW_R7-SW_R5		// load r5
	ld8	r16=[r29],SW_B3-SW_UNATB	// load unat_b
	mov	ar.rsc=IA64_RSE_EAGER
	;;
	ld8.fill r6=[r31],SW_B1-SW_R6		// load r6
	ld8.fill r7=[r30],SW_B2-SW_R7		// load r7
	;;
	ld8	r17=[r31],SW_B4-SW_B1		// load b1
	ld8	r18=[r30],SW_B5-SW_B2		// load b2
	mov	ar.unat=r16			// unat_b
	;;
	ld8	r16=[r29],SW_F2-SW_B3		// load b3
	mov	b1=r17
	mov	b2=r18
	;;
	ld8	r17=[r31],SW_F3-SW_B4		// load b4
	ld8	r18=[r30],SW_F4-SW_B5		// load b5
	mov	b3=r16
	;;
	ldf.fill f2=[r29]			// load f2
	mov	b4=r17
	mov	b5=r18
	;;
	ldf.fill f3=[r31],SW_F5-SW_F3		// load f3
	ldf.fill f4=[r30],SW_F4-SW_F2		// load f4
	;;
	ldf.fill f5=[r31],SW_F5-SW_F3		// load f5
	ldf.fill f16=[r30],SW_F4-SW_F2		// load f16
	;;
	ldf.fill f17=[r31],SW_F5-SW_F3		// load f17
	ldf.fill f18=[r30],SW_F4-SW_F2		// load f18
	;;
	ldf.fill f19=[r31],SW_F5-SW_F3		// load f19
	ldf.fill f20=[r30],SW_F4-SW_F2		// load f20
	;;
	ldf.fill f21=[r31],SW_F5-SW_F3		// load f21
	ldf.fill f22=[r30],SW_F4-SW_F2		// load f22
	;;
	ldf.fill f23=[r31],SW_F5-SW_F3		// load f23
	ldf.fill f24=[r30],SW_F4-SW_F2		// load f24
	;;
	ldf.fill f25=[r31],SW_F5-SW_F3		// load f25
	ldf.fill f26=[r30],SW_F4-SW_F2		// load f26
	;;
	ldf.fill f27=[r31],SW_F5-SW_F3		// load f27
	ldf.fill f28=[r30],SW_F4-SW_F2		// load f28
	;;
	ldf.fill f29=[r31],SW_F5-SW_F3		// load f29
	ldf.fill f30=[r30],SW_F4-SW_F2		// load f30
	;;
	ldf.fill f31=[r30],SW_F4-SW_F2		// load f31
	add		r8=1,r0
	br.ret.sptk	rp
	;;
END(restore_context)

/*
 * void switch_context(struct thread* old, struct thread* new)
 */
ENTRY(switch_context)

	mov	ar.rsc=IA64_RSE_LAZY
	mov	r16=ar.unat
	add	r31=SW_UNATB,in0
	add	r30=SW_SP,in0
	;;
{	.mmi
	flushrs
	st8	[r30]=sp,SW_RP-SW_SP		// sp
	mov	r17=rp
	;;
}
	st8	[r31]=r16,SW_PR-SW_UNATB	// unat (before)
	st8	[r30]=r17,SW_BSP-SW_RP		// rp
	mov	r16=pr
	;;
	st8	[r31]=r16,SW_PFS-SW_PR		// pr
	mov	r17=ar.bsp
	mov	r16=ar.pfs
	;;
	st8	[r31]=r16,SW_RNAT-SW_PFS	// save pfs
	st8	[r30]=r17,SW_R4-SW_BSP		// save bsp
	mov	r16=ar.rnat
	;;
	st8	[r31]=r16,SW_R5-SW_RNAT		// save rnat
	mov	ar.rsc=IA64_RSE_EAGER
	;;
{	.mmi
	.mem.offset	8,0
	st8.spill	[r30]=r4,SW_R6-SW_R4	// r4
	.mem.offset	16,0
	st8.spill	[r31]=r5,SW_R7-SW_R5	// r5
	mov		r16=b1
	;;
}
{	.mmi
	.mem.offset	8,0
	st8.spill	[r30]=r4,SW_B1-SW_R6	// r6
	.mem.offset	16,0
	st8.spill	[r31]=r5,SW_B2-SW_R7	// r7
	mov		r17=b2
	;;
}
	st8	[r30]=r16,SW_UNATA-SW_B1	// b1
	st8	[r31]=r17,SW_B3-SW_B2		// b2
	mov	r18=ar.unat
	mov	r19=b3
	mov	r20=b4
	mov	r21=b5
	;;
	st8	[r30]=r18,SW_B4-SW_UNATA	// unat (after)
	st8	[r31]=r19,SW_B5-SW_B3		// b3
	;;
	st8	[r30]=r20,SW_LC-SW_B4		// b4
	st8	[r31]=r21,SW_F2-SW_B5		// b5
	mov	r17=ar.lc
	;;
	st8		[r30]=r17,SW_F3-SW_LC	// ar.lc
	stf.spill	[r31]=f2,SW_F4-SW_F2
	;;
	stf.spill	[r30]=f3,SW_F5-SW_F3
	stf.spill	[r31]=f4,SW_F4-SW_F2
	;;
	stf.spill	[r30]=f5,SW_F5-SW_F3
	stf.spill	[r31]=f16,SW_F4-SW_F2
	;;
	stf.spill	[r30]=f17,SW_F5-SW_F3
	stf.spill	[r31]=f18,SW_F4-SW_F2
	;;
	stf.spill	[r30]=f19,SW_F5-SW_F3
	stf.spill	[r31]=f20,SW_F4-SW_F2
	;;
	stf.spill	[r30]=f21,SW_F5-SW_F3
	stf.spill	[r31]=f22,SW_F4-SW_F2
	;;
	stf.spill	[r30]=f23,SW_F5-SW_F3
	stf.spill	[r31]=f24,SW_F4-SW_F2
	;;
	stf.spill	[r30]=f25,SW_F5-SW_F3
	stf.spill	[r31]=f26,SW_F4-SW_F2
	;;
	stf.spill	[r30]=f27,SW_F5-SW_F3
	stf.spill	[r31]=f28,SW_F4-SW_F2
	;;
	stf.spill	[r30]=f29,SW_F4-SW_F2
	stf.spill	[r31]=f30
	;;
	stf.spill	[r30]=f31
	add		r8=0,r0
	mf
//	br.ret.sptk	rp

{	.mfb
	mov		r32=r33
	nop		0
	br.sptk		restore_context
	;;
}

END(switch_context)

/*
 * The function is used to start a new thread.
 */
ENTRY(thread_starter)

	.prologue
	.save	ar.pfs,loc0
	alloc	loc0=ar.pfs,0,1,1,0
	;;
	.body
	;;
	mov	b7=r4			// the function pointer
	mov	out0=r6			// the argument
	;;
	br.call.sptk.many rp=b7		// Call the thread function
	;;
	br.call.sptk.many rp=exit_thread	// call exit_thread
	;;
END(thread_starter)

ENTRY(__hypercall)
	mov r2=r37
	break 0x1000
	br.ret.sptk.many b0
	;;
END(__hypercall)

/*
 * Stub for suspend.
 * Just force the stacked registers to be written in memory.
 */
ENTRY(xencomm_arch_hypercall_suspend)
	;;
	alloc	r20=ar.pfs,0,0,6,0
	mov	r2=__HYPERVISOR_sched_op
	;;
	/* We don't want to deal with RSE.  */
	flushrs
	mov	r33=r32
	mov	r32=2		// SCHEDOP_shutdown
	;;
	break	0x1000
	;;
	br.ret.sptk.many b0
END(xencomm_arch_hypercall_suspend)


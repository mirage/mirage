/*
 * Copyright (c) 2007 Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 *
 *****************************************************************************
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
 */



#include <mini-os/asm.h>
#include <mini-os/page.h>
#include <mini-os/ia64_cpu.h>
#include <mini-os/ia64_fpu.h>
#include <mini-os/privop.h>
#include <mini-os/offsets.h>



	/*
	 * Allocate kernel stack area.
	 * This is used for stack pointer (goes down from kstack+PAGE_SIZE) and
	 * RSE (goes up from kstack).
	 */
	.section .data.start,"aw"
	.global	kstack
	.align	PAGE_SIZE
kstack:	.space KSTACK_PAGES * PAGE_SIZE

	.text

	/*
	 * Start the kernel.
	 * r28 points to the address of the boot parameter area, given
	 * from the bootloader.
	 * Execution reaches here in physical mode.
	 */
ENTRY(_start)
	.prologue
	.save rp, r0		// terminate unwind chain with a NULL rp
	.body

	alloc	loc0=ar.pfs,0,1,1,0

	rsm psr.i | psr.ic
	;;
	srlz.i
	;;

	/*
	 * Initialize mini-os region registers:
	 * Currently only region registers 5 and 7 are used for addressing.
	 * rr[5] : virtual kernel address space
	 * rr[7] : directly mapped physically addresses.
	 */
	movl	r2=0<<IA64_RR_IDX_POS
	movl	r3=1<<IA64_RR_IDX_POS
	;;
	mov	rr[r2]=r0
	mov	rr[r3]=r0
	;;
	movl	r2=2<<IA64_RR_IDX_POS
	movl	r3=3<<IA64_RR_IDX_POS
	;;
	mov	rr[r2]=r0
	mov	rr[r3]=r0
	;;
	movl	r2=4<<IA64_RR_IDX_POS
	movl	r3=6<<IA64_RR_IDX_POS
	;;
	mov	rr[r2]=r0
	mov	rr[r3]=r0
	;;
	// Wired memory for kernel data and text.
	movl	r2=IA64_RR_VAL(KERNEL_TR_PAGE_SIZE,0)
	movl	r3=5<<IA64_RR_IDX_POS		// region 5
	;;
	mov	rr[r3]=r2
	;;
	/*
	 * Region 7 addresses are only for directly mapped physically
	 * addresses.
	 */
	movl	r2=IA64_RR_VAL(PTE_PS_16K,0)
	movl	r3=7<<IA64_RR_IDX_POS		// region 7
	;;
	mov	rr[r3]=r2
	;;
	/*
	 * Setup protection keys for region 5 and 7.
	 */
	mov	r2=(IA64_KEY_REG5 << IA64_PKR_KEY) | IA64_PKR_VALID
	mov	r3=(IA64_KEY_REG7 << IA64_PKR_KEY) | IA64_PKR_VALID
	mov	r14=0x1
	;;
	mov	pkr[r0]=r2	/* Region 5 */
	mov	pkr[r14]=r3	/* Region 7 */
	;;
	/*
	 * Now pin mappings into the TLB for kernel text and data
	 */
	mov	r18=(KERNEL_TR_PAGE_SIZE<<IA64_ITIR_PS)| \
			(IA64_KEY_REG5<<IA64_ITIR_KEY)
	movl	r17=KERNEL_START
	;;
	mov	cr.itir=r18
	mov	cr.ifa=r17
	mov	r16=IA64_TR_KERNEL
	mov	r3=ip
	movl	r18=PTE_KERNEL_ATTR
	;;
	dep	r2=0,r3,0,KERNEL_TR_PAGE_SIZE
	;;
	or	r18=r2,r18
	;;
	srlz.i
	;;
	itr.i	itr[r16]=r18
	;;
	itr.d	dtr[r16]=r18
	;;
	srlz.i

	/*  Switch into virtual mode */
	movl	r16=STARTUP_PSR
	;;
	mov	cr.ipsr=r16
	movl	r17=1f
	;;
	mov	cr.iip=r17
	mov	cr.ifs=r0
	;;
	rfi
	;;
1:	/* now we are in virtual mode */

	movl	r3=ia64_trap_table
	;;
	mov	cr.iva=r3
	;;

	movl	r2=IA64_FPSR_DEFAULT
	movl	r3=IA64_DCR_DEFAULT
	;;
	srlz.i
	movl	gp=__gp

	mov	ar.fpsr=r2
	mov	cr.dcr=r3
	;;
	movl	r2=kstack
	movl	r5=KSTACK_PAGES * PAGE_SIZE - 16
	mov	ar.rsc=0	// place RSE in enforced lazy mode
	;;
	loadrs			// clear the dirty partition
	;;
	mov	ar.bspstore=r2	// establish the new RSE stack
	add	sp=r2,r5
	;;
	mov	ar.rsc=IA64_RSE_EAGER	// place RSE in eager mode

	;;
	movl	r2=ia64_boot_paramP
	mov	r3=7		// make address virtual region 7.
	;;
	dep	r28=r3,r28,61,3
	;;
				// save the address of the boot param area
				// passed by the bootloader
	st8	[r2]=r28
	;;

	/* Set xsi base. I use here XSI_BASE. */
#define FW_HYPERCALL_SET_SHARED_INFO_VA                 0x600
	mov r2=FW_HYPERCALL_SET_SHARED_INFO_VA
	movl r28=XSI_BASE
	;;
	break 0x1000
	;;
	/*
	 * I set up here the pointer to the global start_info structure.
	 * This structure will be initialized in arch_init().
	 */
	movl	out0=start_info_union
		// Prepare out0 - the pointer to start_info_t.
	movl	r14=XSI_BASE
	;;
	add	r15=START_INFO_PFN,r14	// add offset to XSI_BASE
	;;
	START_INFO_PFN_ld	r14=[r15]	// load the start_info_pfn
	add	r16=7, r0
	;;
	shl	r15=r14,PAGE_SHIFT_XEN_16K	// pfn << PAGE_SHIFT_XEN_16K
	shl	r16=r16,IA64_RR_IDX_POS		// (7<<IA64_RR_IDX_POS)
	;;
	or	out0=r16, r15			// make a region 7 address
	;;
	ssm	psr.i | psr.ic
	;;
	srlz.i
	;;
	br.call.sptk.many rp=start_kernel
	;;
	add	r2=3,r0
	;;
	ld8	r3=[r2]
	;;

self:	hint @pause
	br.sptk.many self		// endless loop
END(_start)


ENTRY(do_nop)
	nop	0x01
	add	r15=1,r15
	br.ret.sptk.many rp
END(do_nop)

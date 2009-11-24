/*
 * crt0_cfe.S -- Runtime startup for MIPS targets running CFE.
 *
 * Copyright 2003
 * Broadcom Corporation. All rights reserved.
 *
 * This software is furnished under license and may be used and copied only
 * in accordance with the following terms and conditions.  Subject to these
 * conditions, you may download, copy, install, use, modify and distribute
 * modified or unmodified copies of this software in source and/or binary
 * form. No title or ownership is transferred hereby.
 *
 * 1) Any source code used, modified or distributed must reproduce and
 *    retain this copyright notice and list of conditions as they appear in
 *    the source file.
 *
 * 2) No right is granted to use any trade name, trademark, or logo of
 *    Broadcom Corporation.  The "Broadcom Corporation" name may not be
 *    used to endorse or promote products derived from this software
 *    without the prior written permission of Broadcom Corporation.
 *
 * 3) THIS SOFTWARE IS PROVIDED "AS-IS" AND ANY EXPRESS OR IMPLIED
 *    WARRANTIES, INCLUDING BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF
 *    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
 *    NON-INFRINGEMENT ARE DISCLAIMED. IN NO EVENT SHALL BROADCOM BE LIABLE
 *    FOR ANY DAMAGES WHATSOEVER, AND IN PARTICULAR, BROADCOM SHALL NOT BE
 *    LIABLE FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 *    BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 *    OR OTHERWISE), EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Derived from crt0_cygmon.S:
 *
 * Copyright (c) 1995, 1996, 1997, 2000 Red Hat, Inc.
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

/*
 * This file does minimal runtime startup for code running under
 * CFE firmware.
 *
 * It does minimal hardware initialization.  In particular
 * it sets Status:FR to match the requested floating point
 * mode.
 *
 * It is meant to be linked with the other files provided by libcfe.a,
 * and calls routines in those files.
 */

#ifdef __mips16
/* This file contains 32 bit assembly code.  */
	.set nomips16
#endif
#ifdef __mips_embedded_pic
# error -membedded-pic is not supported.
#endif

#include "regs.S"

/*
 * Set up some room for a stack. We just grab a chunk of memory.
 */
#define STARTUP_STACK_SIZE	(1 * 1024)		

	.comm	_lstack, STARTUP_STACK_SIZE

	.text
	.align	4

    /*
     * Without the following nop, GDB thinks _start is a data variable.
     * This is probably a bug in GDB in handling a symbol that is at the
     * start of the .text section.
     */
	nop


    /*
     * On entry, the following values have been passed in registers
     * by the firmware:
     *
     * a0: firmware handle
     * a1: zero (unused)
     * a2: firmware callback entrypoint
     * a3: CFE entrypoint seal (unused)
     *
     * They must be preserved until the CFE entrypoint and handle
     * are passed to __libcfe_init().
     */

	.globl	_start
	.ent	_start
_start:
	.set	noreorder
    /* Set the global data pointer, defined in the linker script.  */
	la		gp, _gp

#ifndef __mips_soft_float
    /* If compiled for hard float, set the FPU mode based on the
       compilation flags.  Note that this assumes that enough code
       will run after the mtc0 to clear any hazards.  */
	mfc0	t0, C0_SR
	or	t0, t0, (SR_CU1 | SR_FR)
#if (__mips_fpr == 32)
	xor	t0, t0, SR_FR		/* If 32-bit FP mode, clear FR.  */
#endif
	mtc0	t0, C0_SR
#endif
	.end	_start

    /*
     * zero out the bss section.
     */
	.globl	_zerobss
	.ent	_zerobss
_zerobss:
    /* These variables are defined in the linker script.  */
	la		v0, _fbss
	la		v1, _end

3:
	sw		zero, 0(v0)
	bltu	v0, v1, 3b
	addiu	v0, v0, 4		/* Delay slot.  */
	.end	_zerobss

    /*
     * Setup a small stack so we can run some C code, and do
     * the library initialization.  (32 bytes are saved for
     * the argument registers' stack slots.)
     */
	.globl	_stackinit
	.ent	_stackinit
_stackinit:
	la	t0, _lstack
	addiu	sp, t0, (STARTUP_STACK_SIZE - 32)
	jal	__libcfe_init
	nop

    /*
     * Setup the stack pointer -- 
     *    __libcfe_init() returns the value to be used as the top of
     *    the program's stack.
     *
     *    We subtract 32 bytes for the 4 argument registers, in case
     *    main() wants to write them back to the stack.  The caller
     *    allocates stack space for parameters in the old MIPS ABIs.
     *    We must do this even though we aren't passing arguments,
     *    because main might be declared to have them.)
     *
     *    We subtract 32 more bytes for the argv/envp setup for the
     *    call to main().
     */
	subu	v0, v0, 64
	move	sp, v0

	.end	_stackinit

    /*
     * initialize target specific stuff. Only execute these
     * functions it they exist.
     */
	.globl	hardware_init_hook .text
	.globl	software_init_hook .text
	.type	_fini,@function
	.type	_init,@function
	.globl	atexit .text
	.globl	exit .text
	.globl	_crt0init
	.ent	_crt0init
_crt0init:
	la		t9, hardware_init_hook	# init the hardware if needed
	beq		t9, zero, 6f
	nop
	jal		t9
	nop
6:
	la		t9, software_init_hook	# init the software if needed
	beq		t9, zero, 7f
	nop
	jal		t9
	nop
7:
	la		a0, _fini
	jal		atexit
	nop

#ifdef GCRT0
	.globl	_ftext
	.globl	_extext
	la		a0, _ftext
	la		a1, _etext
	jal		monstartup
	nop
#endif

	jal	_init			# run global constructors
	nop

	addiu	a1,sp,32			# argv = sp + 32
	addiu	a2,sp,40			# envp = sp + 40
#if __mips64
	sd	zero,(a1)			# argv[argc] = 0
	sd	zero,(a2)			# envp[0] = 0
#else
	sw	zero,(a1)
	sw	zero,(a2)
#endif

	jal	main			# call the program start function
	move	a0,zero			# set argc to 0; delay slot.

	# fall through to the "exit" routine
	jal	exit			# call libc exit to run the G++
					# destructors
	move	a0, v0			# pass through the exit code
	.end	_crt0init
	
/*
 * _exit -- Exit from the application.  This is provided in this file because
 *          program exit should shut down profiling (if GCRT0 is defined),
 *          and only this file is compiled with GCRT0 defined.
 */
	.globl	_exit
	.ent	_exit
_exit:
7:
	move	s0, a0			/* Save in case we loop.  */

#ifdef GCRT0
	jal	_mcleanup
	nop
#endif

	la	t0, hardware_exit_hook
	beq	t0,zero,1f
	nop
	jal	t0
	nop

1:
	/* Call into the library to do the heavy lifting.  */
        jal	__libcfe_exit
	move	a0, s0			/* Delay slot.  */

	b	7b			/* Loop back just in case.  */
	nop
	.end	_exit

/* EOF crt0_cfe.S */

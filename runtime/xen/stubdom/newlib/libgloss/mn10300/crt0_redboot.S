/*
 * crt0_redboot.S -- Minimal startup file for MN10300 targets running Redboot.
 *
 * Copyright (c) 2001 Red Hat, Inc.
 * Derived from crt0_cygmon.S - Copyright (c) 1995, 1996, 1997, 2000 Red Hat, Inc.
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
 * This file contains the minimal startup code necessary.
 * This will not do any hardware initialization.  It is assumed that we are talking to Redboot
 * and therefore the hardware will be initialized properly.
 */

/*
 * Set up some room for a stack. We just grab a chunk of memory.
 */
#define STACK_SIZE  0x4000
#define GLOBAL_SIZE 0x2000

#define STARTUP_STACK_SIZE	0x0100

	.comm	__memsize, 12
	.comm	__lstack, STARTUP_STACK_SIZE
	.comm	__stackbase,4

	.section .text
	.global	_start
_start:
	/*
	 * Setup a small stack so we can run some C code,
	 * and get the usable memory size.
	 */
	mov	__lstack,a0
	add	STARTUP_STACK_SIZE-4,a0
	mov	a0,sp

	/*
	 * zero out the bss section.
	 */
	.global	__memsize
	.global	_get_mem_info
zerobss:
	mov	__bss_start, a0				# These variables are defined in the linker script
	mov	_end, a1

	cmp	a0, a1					# If no bss, then do nothing
	beq	7f

	clr	d0
3:
	movbu	d0,(a0)					# Clear a byte and bump pointer
	inc	a0
	cmp	a0, a1
	bne	3b

7:
	/*
	 * Setup the stack pointer -- 
	 *    get_mem_info returns the top of memory, so just use that In
	 *    addition, we must subtract 24 bytes for the 3 8 byte
	 *    arguments to main, in case main wants to write them back to
	 *    the stack.  The caller is supposed to allocate stack space
	 *    for parameters in registers in the old MIPS ABIs.	 We must
	 *    do this even though we aren't passing arguments, because
	 *    main might be declared to have them.
	 *    Some ports need a larger alignment for the stack, so we
	 *    subtract 32, which satisifes the stack for the arguments and
	 *    keeps the stack pointer better aligned.
	 */
	mov	__memsize, d0
	call	_get_mem_info,[],0

	sub	32, a0
	mov	a0, sp

	mov	__stackbase, a1
	mov	a0, (a1)				# keep this for future ref

	call	___main,[],0				# Call __main to run ctors/dtors
	clr	d0
	clr	d1
	mov	d0, (4,sp)
 	or	0x0800,psw				# Enable interrupts
	call	_main,[],0				# Call main program
	call	_exit,[],0
	
/* EOF crt0_redboot.S */

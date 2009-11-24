/*
 * crt0.S for the Blackfin processor
 *
 * Copyright (C) 2006 Analog Devices, Inc.
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

	.text
	.align 	2

	.global	__start
__start:

	/* Start by setting up a stack */
	link 0xc;
	/* Zero the memory in the .bss section.  */

	p0.l = __edata;
	p0.h = __edata;
	p1.l = __end;
	p1.h = __end;
	p1 -= p0;
	r0 = 0;
	lsetup (L$L$clear_bss, L$L$clear_bss) lc0 = p1;
L$L$clear_bss:
	B [p0++] = r0;

#ifdef __BFIN_FDPIC__
	/* Set up GOT pointer.  */
	P0.L = __ROFIXUP_END__;
	P0.H = __ROFIXUP_END__;
	P4 = [P0 - 4];
#endif

	/* Need to set up standard file handles */
	/*  Parse string at r1 */

	p0.l = __init;
	p0.h = __init; 
	P3 = P4; 
	call	(p0)

	p0.l = _atexit;
	p0.h = _atexit;
#ifdef __BFIN_FDPIC__
	r0 = [P4 + __fini@FUNCDESC_GOT17M4]  ; 
	P3 = P4; 
#else
	r0.l = __fini;
	r0.h = __fini;
#endif
	call	(p0)

	p0.l = ___setup_argv_and_call_main;
	p0.h = ___setup_argv_and_call_main; 
	P3 = P4; 
	call	(p0)

	p0.l = _exit;
	p0.h = _exit; 
	P3 = P4; 
	jump	(p0)		/* Should not return.  */
	nop;

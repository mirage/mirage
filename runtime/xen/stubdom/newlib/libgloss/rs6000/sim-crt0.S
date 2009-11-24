/*
 * crt0.S -- startup file for PowerPC systems.
 *
 * Copyright (c) 1995 Cygnus Support
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

#include "ppc-asm.h"

	.file	"sim-crt0.S"
	.text
	.globl	_start
	.type	_start,@function
_start:
	lis	r0,0
	stw	r0,0(sp)	/* clear back chain */
	stwu	sp,-64(sp)	/* push another stack frame */

	/* Let her rip */
	bl	FUNC_NAME(main)

	/* return value from main is argument to exit */
	bl	FUNC_NAME(exit)
.Lstart:
	.size	_start,.Lstart-_start

	.extern	FUNC_NAME(atexit)
	.globl	FUNC_NAME(__atexit)
	.section ".sdata","aw"
	.align	2
FUNC_NAME(__atexit):			/* tell C's eabi-ctor's we have an atexit function */
	.long	FUNC_NAME(atexit)@fixup	/* and that it is to register __do_global_dtors */

	.section ".fixup","aw"
	.align	2
	.long	FUNC_NAME(__atexit)

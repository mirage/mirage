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

	.file	"crt0.S"
	.section ".got2","aw"
	.align	2

.LCTOC1 = .+32768

	.extern	FUNC_NAME(atexit)
	.globl	FUNC_NAME(__atexit)
	.section ".sdata","aw"
	.align	2
FUNC_NAME(__atexit):			/* tell C's eabi-ctor's we have an atexit function */
	.long	FUNC_NAME(atexit)@fixup	/* and that it is to register __do_global_dtors */

	.section ".fixup","aw"
	.align	2
	.long	FUNC_NAME(__atexit)

	.section ".got2","aw"
.Ltable = .-.LCTOC1
	.long	.LCTOC1			/* address we think .LCTOC1 is loaded at */

.Lsbss_start = .-.LCTOC1
	.long	__sbss_start

.Lsbss_end = .-.LCTOC1
	.long	__sbss_end

.Lbss_start = .-.LCTOC1
	.long	__bss_start

.Lend = .-.LCTOC1
	.long	_end

.Lstack = .-.LCTOC1			/* stack address if set by user */
	.long	__stack

	.text
.Lptr:
	.long .LCTOC1-.Laddr

	.globl	_start
	.type	_start,@function
_start:
	bl	.Laddr			/* get current address */
.Laddr:
	mflr	r4			/* real address of .Laddr */
	lwz	r5,(.Lptr-.Laddr)(r4)	/* linker generated address of .LCTOC1 */
	add	r5,r5,r4		/* correct to real pointer */
	lwz	r4,.Ltable(r5)		/* get linker's idea of where .Laddr is */
	subf	r4,r4,r5		/* calculate difference between where linked and current */

	/* clear bss and sbss */
	lwz	r6,.Lbss_start(r5)	/* calculate beginning of the BSS */
	lwz	r7,.Lend(r5)		/* calculate end of the BSS */
	add	r6,r6,r4		/* adjust pointers */
	add	r7,r7,r4

	cmplw	1,r6,r7
	bc	4,4,.Ldone1

	subf	r8,r6,r7		/* number of bytes to zero */
	srwi	r9,r8,2			/* number of words to zero */
	mtctr	r9
	li	r0,0			/* zero to clear memory */
	addi	r6,r6,-4		/* adjust so we can use stwu */
.Lloop:
	stwu	r0,4(r6)		/* zero bss */
	bdnz	.Lloop

.Ldone1:

	lwz	r6,.Lsbss_start(r5)	/* calculate beginning of the SBSS */
	lwz	r7,.Lsbss_end(r5)	/* calculate end of the SBSS */
	add	r6,r6,r4		/* adjust pointers */
	add	r7,r7,r4

	cmplw	1,r6,r7
	bc	4,4,.Ldone

	subf	r8,r6,r7		/* number of bytes to zero */
	srwi	r9,r8,2			/* number of words to zero */
	mtctr	r9
	li	r0,0			/* zero to clear memory */
	addi	r6,r6,-4		/* adjust so we can use stwu */
.Lloop2:
	stwu	r0,4(r6)		/* zero bss */
	bdnz	.Lloop2

.Ldone:

	lwz	r0,.Lstack(r5)		/* stack address or 0 */
	cmplwi	1,r0,0			/* equal to 0? */
	bc	12,6,.Lnostack		/* use default stack if == 0 */
	mr	sp,r0			/* use user defined stack */

.Lnostack:
	/* set up initial stack frame */
	addi	sp,sp,-4		/* make sure we don't overwrite debug mem */
	lis	r0,0
	stw	r0,0(sp)		/* clear back chain */
	stwu	sp,-64(sp)		/* push another stack frame */

	/* Let her rip */
	bl	FUNC_NAME(main)

	/* return value from main is argument to exit */
	bl	FUNC_NAME(exit)
	trap
.Lstart:
	.size	_start,.Lstart-_start

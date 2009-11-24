/*
 * crt0.S -- startup file for D30V systems.
 *
 * Copyright (c) 1997 Cygnus Support
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

	.file	"crt0.S"
	.text
	.globl	_start
	.extern	main
	.extern	exit
	.extern __stack
	.extern	__sbss_start
	.extern	__sbss_end
	.extern	__ebss_start
	.extern	__ebss_end
	.extern	__bss_start
	.extern	__bss_end
	.extern	memset
	.type	_start,@function

_start:	or.l	sp,r0,__stack

	/* Zero the .sbss area */
	or.l	r2,r0,__sbss_start
	or.l	r4,r0,__sbss_end
	sub	r4,r4,r2	|| or.s r3,r0,0
	bsrtnz.l r4,(memset)

	/* Zero the .ebss area */
	or.l	r2,r0,__ebss_start
	or.l	r4,r0,__ebss_end
	sub	r4,r4,r2	|| or.s r3,r0,0
	bsrtnz.l r4,(memset)

	/* Zero the .bss area */
	or.l	r2,r0,__bss_start
	or.l	r4,r0,__bss_end
	sub	r4,r4,r2	|| or.s r3,r0,0
	bsrtnz.l r4,(memset)

	or.s	r2,r0,0		|| or.s	r3,r0,0
	or	r4,r0,0		|| nop
	jsr.l	(main)
	jsr.l	(exit)
	.size	_start,.-_start

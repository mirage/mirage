/*
 * fido-hosted.S -- 
 *
 * Copyright (c) 2006 CodeSourcery Inc
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

/* Semihosting function.  The debugger intercepts the halt, and
   determines that it is followed by the sentinel pattern. */

	.globl __hosted
__hosted:
	linkw %fp,#0
	movel %fp@(8),%d0
	movel %fp@(12),%d1
	.align 4
	nop
	bkpt #0
	
	/* This sentinel instruction value must be immediately after
	   the bkpt instruction.  The debugger will adjust the pc, so
	   that it is never executed.  This instruction is
	   'movec %sp,0'.  */
	.long 0x4e7bf000
	unlk %fp
	rts

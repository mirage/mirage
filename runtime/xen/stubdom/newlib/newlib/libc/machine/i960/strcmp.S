/*******************************************************************************
 * 
 * Copyright (c) 1993 Intel Corporation
 * 
 * Intel hereby grants you permission to copy, modify, and distribute this
 * software and its documentation.  Intel grants this permission provided
 * that the above copyright notice appears in all copies and that both the
 * copyright notice and this permission notice appear in supporting
 * documentation.  In addition, Intel grants this permission provided that
 * you prominently mark as "not part of the original" any modifications
 * made to this software or documentation, and that the name of Intel
 * Corporation not be used in advertising or publicity pertaining to
 * distribution of the software or the documentation without specific,
 * written prior permission.
 * 
 * Intel Corporation provides this AS IS, WITHOUT ANY WARRANTY, EXPRESS OR
 * IMPLIED, INCLUDING, WITHOUT LIMITATION, ANY WARRANTY OF MERCHANTABILITY
 * OR FITNESS FOR A PARTICULAR PURPOSE.  Intel makes no guarantee or
 * representations regarding the use of, or the results of the use of,
 * the software and documentation in terms of correctness, accuracy,
 * reliability, currentness, or otherwise; and you rely on the software,
 * documentation and results solely at your own risk.
 *
 * IN NO EVENT SHALL INTEL BE LIABLE FOR ANY LOSS OF USE, LOSS OF BUSINESS,
 * LOSS OF PROFITS, INDIRECT, INCIDENTAL, SPECIAL OR CONSEQUENTIAL DAMAGES
 * OF ANY KIND.  IN NO EVENT SHALL INTEL'S TOTAL LIABILITY EXCEED THE SUM
 * PAID TO INTEL FOR THE PRODUCT LICENSED HEREUNDER.
 * 
 ******************************************************************************/

	.file "strcmp.s"
#ifdef	__PIC
	.pic
#endif
#ifdef	__PID
	.pid
#endif
/*
 * (c) copyright 1988,1993 Intel Corp., all rights reserved
 */
/*
	procedure strcmp  (optimized assembler version for the 80960K Series)

	result = strcmp (src1_addr, src2_addr)

	compare the null terminated string pointed to by src1_addr to 
	the string pointed to by src2_addr.  Return 0 iff the strings
	are equal, -1 if src1_addr is lexicographically less than src2_addr,
	and 1 if it is lexicographically greater.

	Undefined behavior will occur if the end of either source string
	(i.e. the terminating null byte) is in the last two words of the 
	program's allocated memory space.  This is so because strcmp fetches
	ahead.  Disallowing the fetch ahead would impose a severe performance 
	penalty.

	Strategy:

	Fetch the source strings by words and compare the words until either 
	differing words are found or the null byte is encountered.  In either
	case, move through the word until either the differing byte if found,
	in which case return -1 or 1 appropriately;  or the null byte is 
	encountered, in which case, return zero (equality).

	Tactics:

	1) Do NOT try to fetch the words in a word aligned manner because,
	in my judgement, the performance degradation experienced due to 
	non-aligned accesses does NOT outweigh the time and complexity added 
	by the preamble and convoluted body that would be necessary to assure 
	alignment.  This is supported by the intuition that many source 
	strings will be word aligned to begin with.
*/

	.globl _strcmp
	.globl __strcmp
	.leafproc _strcmp,__strcmp
	.align 2

_strcmp:
#ifndef __PIC
	lda	.Lrett,g14
#else
	lda	.Lrett-(.+8)(ip),g14
#endif
__strcmp:
	ld	(g0), g5	# fetch first word of source_1
	mov	g14,g7		# preserve return address
	ldconst 0,g14		# conform to register conventions
	ldconst 0xff,g4		# byte extraction mask
.Lwloop:
	addo     4,g0,g0	# post-increment source_1 byte ptr
	ld	(g1), g3	# fetch word of source_2
	scanbyte 0,g5		# does word have a null byte?
        mov      g5,g2		# save a copy of the source_1 word
	be .Lcloop		# branch if null byte encountered
	cmpo	 g2,g3		# are the source words the same?
	addo     4,g1,g1	# post-increment source_2 byte ptr
	ld	(g0), g5	# fetch ahead next word of source_1
	be	 .Lwloop		# fall thru if words are unequal

.Lcloop: and	g4,g2,g5  	# extract and compare individual bytes
	and	g4,g3,g6
	cmpobne	g5,g6,.diff	# if they differ, go return 1 or -1
	cmpo    0,g6		# they are the same.  Are they null?
	shlo	8,g4,g4		# position mask for next extraction
	bne	.Lcloop		# loop if null not encountered

	mov	0,g0		# return equality
	bx	(g7)
.Lrett:	
	ret
.diff:	bl	.neg
        mov     1,g0
	bx	(g7)
.neg:	subi    1,0,g0
.Lexit: 	
	bx	(g7)

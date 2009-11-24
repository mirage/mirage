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

	.file "strncmp.s"
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
	procedure strncmp  (optimized assembler version for the 80960K Series)

	result = strncmp (src1_addr, src2_addr, max_bytes)

	compare the null terminated string pointed to by src1_addr to 
	the string pointed to by src2_addr.  Return 0 iff the strings
	are equal, -1 if src1_addr is lexicographically less than src2_addr, 
	and 1 if it is lexicographically greater.  Do not compare more than 
	max_bytes bytes.

	Undefined behavior will occur if the end of either source string
	(i.e. the terminating null byte) is in the last two words of the 
	program's allocated memory space.  This is so because strncmp
	will fetch ahead.  Disallowing the fetch ahead would impose
	a severe performance penalty.

	Strategy:

	Fetch and compare the strings by words and go to a character
	comparison loop as soon as a pair of words differ.  If the
	words are equal up through either the exhaustion of max_bytes
	or the presence of the null byte, return 0 (equality).  Otherwise,
	the character comparator will return -1 or 1 for inequality, or
	0 if the differing byte is after the null byte or after the
	exhaustion of max_bytes.

	Tactics:

	1) Do NOT try to fetch the words in a word aligned manner because,
	in my judgement, the performance degradation experienced due to 
	non-aligned accesses does NOT outweigh the time and complexity added
	by the preamble and convoluted body that would be necessary to assure 
	alignment.  
*/

	.globl _strncmp
	.globl __strncmp
	.leafproc _strncmp,__strncmp
	.align 2

_strncmp:
#ifndef __PIC
	lda	.Lrett,g14
#else
	lda	.Lrett-(.+8)(ip),g14
#endif
__strncmp:
	mov	g14,g13
	ldconst 0,g14
	cmpibge	0,g2,Lequal_exit		# Lexit early if max_bytes <= 0
	addo	g2,g0,g2
.Lwloop:
	cmpo	g0,g2		# are max_bytes exhausted?
	ld	(g0), g5	# fetch word of source_1
	bge	 Lequal_exit	# Lexit (equality) if max_bytes exhausted
	ld	(g1), g3	# fetch word of source_2
	addo     4,g0,g0	# post-increment source_1 ptr
	scanbyte 0,g5		# is a null byte present?
	addo     4,g1,g1	# post-increment source_1 ptr
	be 	.Lcloop.a	# perform char comparator if null byte found
	cmpobe	 g5,g3,.Lwloop	# perform char comparator if words are unequal

.Lcloop.a: subo	4,g0,g0		# adjust max_byte counter
	ldconst 0xff,g4		# byte extraction mask

.Lcloop: and	g4,g5,g7  	# compare individual bytes
	and	g4,g3,g6
	cmpobne	g7,g6,.diff	# if different, return -1 or 1
	cmpo    0,g6		# they are equal.  are they null?
	shlo	8,g4,g4		# position mask to extract next byte
	be	Lequal_exit	# if they are null, Lexit (equality)
	addo	1,g0,g0		# is max_bytes exhausted?
	cmpobl	g0,g2,.Lcloop	# if not, loop.  if so, Lexit (equality)

Lequal_exit:
	mov	0,g0
	bx	(g13)
.Lrett:	
	ret
.diff:	bl	.neg
        mov     1,g0
	bx	(g13)

.neg:	subi    1,0,g0
.Lexit: 	
	bx	(g13)

/* end of strncmp */

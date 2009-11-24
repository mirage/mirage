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

	.file "memcmp.s"
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
	procedure memcmp  (optimized assembler version for the 80960K series)

	result = memcmp (src1_addr, src2_addr, max_bytes)

	compare the byte array pointed to by src1_addr to the byte array
	pointed to by src2_addr.  Return 0 iff the arrays are equal, -1 iff 
	src1_addr is lexicographically less than src2_addr, and 1 iff it is 
	lexicographically greater.  Do not compare more than max_bytes bytes.

	Undefined behavior will occur if the end of either source array
	is in the last two words of the program's allocated memory space. 
	This is so because memcmp fetches ahead.  Disallowing the fetch ahead 
	would impose a severe performance penalty.

	Strategy:

	Fetch the source strings by words and compare the words until either 
	a differing word is found or max_bytes is exhausted.  In the former 
	case, move through the words to find the differing byte and return 
	plus or minus one, appropriately.  In the latter case, return zero 
	(equality).

	Tactics:

	1) Do NOT try to fetch the words in a word aligned manner because,
	in my judgement, the performance degradation experienced due to 
	non-aligned accesses does NOT outweigh the time and complexity added 
	by the preamble that would be necessary to assure alignment.  This 
	is supported by the intuition that most source arrays (even more 
	true of most big source arrays) will be word aligned to begin with.

	2) Rather than decrementing max_bytes to zero, I calculate the
	address of the byte after the last byte of the source_1 array, and
	quit when the source byte pointer passes that.  
*/

	.globl _memcmp
	.globl __memcmp
	.leafproc _memcmp,__memcmp
	.align 2

_memcmp:
#ifndef __PIC
	lda	.Lrett,g14
#else
	lda	.Lrett-(.+8)(ip),g14
#endif
__memcmp:
	mov	g14,g13		# preserve return address
	ldconst 0,g14		# conform to register conventions
	cmpibge	0,g2,Lequal_exit	# quit if max_bytes <= 0
	addo	g0,g2,g2	# calculate byte addr of byte after last in src1

.Lwloop:
	cmpo	 g0,g2		
	ld	(g0), g5	# fetch word of source_1
	bge 	 Lequal_exit	# quit (equal) if max_bytes exhausted
	ld	(g1), g3	# fetch word of source_2
	addo     4,g0,g0	# post-increment source_1 byte ptr
	addo     4,g1,g1       	# post-increment source_2 byte ptr
	cmpobe	 g5,g3,.Lwloop	# branch if source words are equal

	ldconst 0xff,g4		# byte extraction mask
	subo     4,g0,g0	# back up src1 pointer

.Lcloop: and	g4,g5,g7  	# extract and compare individual bytes
	and	g4,g3,g6
	cmpobne	g7,g6,.diff	# branch if they are different
	shlo	8,g4,g4		# position mask for next extraction
	addo	1,g0,g0
	cmpobl	g0,g2,.Lcloop	# quit if max_bytes is exhausted

Lequal_exit:
	mov	0,g0
	bx	(g13)
.Lrett:	
	ret

.diff:	bl	.neg		# arrays differ at current byte.  
				/* return 1 or -1 appropriately */
        mov     1,g0
	bx	(g13)
.neg:	subi    1,0,g0
.Lexit: 	
	bx	(g13)

/* end or memcmp */

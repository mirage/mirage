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

	.file "strlen.s"
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
	procedure strlen  (optimized assembler version for the 80960K series)

	src_addr = strlen (src_addr)

	return the number of bytes that precede the null byte in the
	string pointed to by src_addr.

	Undefined behavior will occur if the end of the source string (i.e. 
	the terminating null byte) is in the last four words of the program's
	allocated memory space.  This is so because strlen fetches ahead 
	several words.  Disallowing the fetch ahead would impose a severe 
	performance penalty.

	Strategy:

	Fetch the source array by long-words and scanbyte the words for the 
	null byte until found.  Examine the word in which the null byte is
	found, to determine its actual position, and return the length.

	Tactics:

	1) Do NOT try to fetch the words in a word aligned manner because,
	in my judgement, the performance degradation experienced due to 
	non-aligned accesses does NOT outweigh the time and complexity added 
	by the preamble that would be necessary to assure alignment.  This 
	is supported by the intuition that many source strings will be word 
	aligned to begin with.
*/

	.globl	_strlen
	.globl	__strlen
	.leafproc	_strlen, __strlen
	.align	2
_strlen:
#ifndef __PIC
	lda 	Lrett,g14
#else
	lda 	Lrett-(.+8)(ip),g14
#endif
__strlen:

	mov	g14,g13		# preserve return address
	ldl	(g0),g4		# fetch first two words
	addo	8,g0,g2		# post-increment src word pointer
	lda	0xff,g3		# byte extraction mask
	

Lsearch_for_word_with_null_byte:
	scanbyte 0,g4		# check for null byte
	mov	g5,g7		# copy second word
	bo.f	Lsearch_for_null	# branch if null found 
	scanbyte 0,g7		# check for null byte
	ldl	(g2),g4		# fetch next pair of word of src
	addo	8,g2,g2		# post-increment src word pointer
	bno	Lsearch_for_word_with_null_byte	# branch if null not found yet

	subo	4,g2,g2		# back up the byte pointer
	mov	g7,g4		# move word with null to search word
Lsearch_for_null:
	subo	9,g2,g2		# back up the byte pointer
Lsearch_for_null.a:
	and	g4,g3,g14	# extract byte
	cmpo	0,g14		# is it null?
	addo	1,g2,g2		# bump src byte ptr
	shro	8,g4,g4		# shift word to position next byte
	bne	Lsearch_for_null.a

Lexit_code:
	subo	g0,g2,g0	# calculate string length
	bx	(g13)		# g0 = addr of src;  g14 = 0
Lrett:
	ret

/* end of strlen */

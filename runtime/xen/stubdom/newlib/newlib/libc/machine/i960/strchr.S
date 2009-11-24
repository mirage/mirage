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

	.file "strchr.s"
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
	procedure strchr  (optimized assembler version for the 80960K series)

	src_addr = strchr (src_addr, char)

	return a pointer to the first byte that contains the indicated
	byte in the source string.  Return null if the byte is not found.

	Undefined behavior will occur if the end of the source string (i.e. 
	the terminating null byte) is in the last two words of the program's
	allocated memory space.  This is so because strchr fetches ahead.  
	Disallowing the fetch ahead would impose a severe performance penalty.

	Strategy:

	Fetch the source string by words and scanbyte the words for the 
	char until either a word with the byte is found or the null byte is
	encountered.  In the former case, move through the word to find the
	matching byte and return its memory address.  In the latter case, 
	return zero (null).

	Tactics:

	1) Do NOT try to fetch the words in a word aligned manner because,
	in my judgement, the performance degradation experienced due to 
	non-aligned accesses does NOT outweigh the time and complexity added 
	by the preamble that would be necessary to assure alignment.  This 
	is supported by the intuition that most source arrays (even more 
	true of most big source arrays) will be word aligned to begin with.
*/

	.globl	_strchr
	.globl	__strchr
	.leafproc	_strchr, __strchr
	.align	2
_strchr:
#ifndef __PIC
	lda 	Lrett,g14
#else
	lda 	Lrett-(.+8)(ip),g14
#endif
__strchr:

	ld	(g0),g4		# fetch first word
	lda	0xff,g7		# byte extraction mask
	and	g1,g7,g1	# make char an 8-bit ordinal
	shlo	8,g1,g2		# broadcast the char to four bytes
	or	g1,g2,g2
	shlo	16,g2,g5
	or	g2,g5,g3
	mov	g14,g13		# preserve return address
	addo	4,g0,g0		# post-increment src pointer
	mov	0,g14		# conform to register linkage standard

Lsearch_for_word_with_char_or_null:
	mov	g4,g5		# copy word
	scanbyte g3,g5		# check for byte with char
	ld	(g0),g4		# fetch next word of src
	bo	Lsearch_for_char	# branch if char found 
	scanbyte 0,g5		# check for null byte
	addo	4,g0,g0		# post-increment src pointer
	bno	Lsearch_for_word_with_char_or_null	# branch if not null

Lnot_found:
	mov	0,g0		# char not found.  Return null
Lexit_code:
	bx	(g13)		# g0 = addr of char in src (or null);  g14 = 0
Lrett:
	ret

Lsearch_for_char:
	subo	5,g0,g0		# back up the byte pointer
Lsearch_for_char.a:
	and	g5,g7,g6	# extract byte
	cmpo	g1,g6		# is it char?
	addo	1,g0,g0		# bump src byte ptr
	shro	8,g5,g5		# shift word to position next byte
	be	Lexit_code
	cmpobne 0,g6,Lsearch_for_char.a	# quit if null comes before char
	b	Lnot_found

/* end of strchr */

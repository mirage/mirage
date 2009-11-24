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

	.file "memchr.s"
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
	procedure memchr  (optimized assembler version for the 80960K series)

	src_addr = memchr (src_addr, char, max_bytes)

	searching from src_addr for a span of max_bytes bytes, return a 
	pointer to the first byte in the source array that contains the 
	indicated char.  Return null if the char is not found.

	Undefined behavior will occur if the last byte of the source array 
	is in the last two words of the program's allocated memory space.
	This is so because memchr fetches ahead.  Disallowing the fetch 
	ahead would impose a severe performance penalty.

	Strategy:

	Fetch the source array by words and scanbyte the words for the 
	char until either a word with the byte is found or max_bytes is
	exhausted.  In the former case, move through the word to find the
	matching byte and return its memory address.  In the latter case, 
	return zero (null).

	Tactics:

	1) Do NOT try to fetch the words in a word aligned manner because,
	in my judgement, the performance degradation experienced due to 
	non-aligned accesses does NOT outweigh the time and complexity added 
	by the preamble that would be necessary to assure alignment.  This 
	is supported by the intuition that most source arrays (even more 
	true of most big source arrays) will be word aligned to begin with.

	2) Rather than decrementing max_bytes to zero, I calculate the
	address of the byte after the last byte of the source array, and
	quit when the source byte pointer passes that.  Refining, actually
	I calculate the address of the fifth byte after the last byte of
	the source array, because the source byte pointer is ahead of the
	actual examination point due to fetch ahead.
*/

	.globl	_memchr
	.globl	__memchr
	.leafproc	_memchr, __memchr
	.align	2
_memchr:
#ifndef __PIC
	lda 	Lrett,g14
#else
	lda 	Lrett-(.+8)(ip),g14
#endif
__memchr:

	mov	g14,g13		# preserve return address
	lda	0xff,g7		# byte extraction mask
	and	g1,g7,g1	# make char an 8-bit ordinal
	mov	0,g14		# conform to register linkage standard
	cmpibge 0,g2,Lnot_found	# do nothing if max_bytes <= 0
	addo	4,g0,g6		# post-increment src word pointer
	addo	g2,g6,g2	# compute ending address from start and len
	ld	(g0),g4		# fetch first word 
	shlo	8,g1,g3		# broadcast the char to four bytes
	or	g1,g3,g3
	shlo	16,g3,g5
	or	g3,g5,g3

Lsearch_for_word_with_char:
	mov	g4,g5		# keep a copy of word
	scanbyte g3,g5		# check for byte with char
	ld	(g6),g4		# fetch next word of src
	bo	Lsearch_for_char	# branch if null found 
	addo	4,g6,g6		# post-increment src word pointer
	cmpobge g2,g6,Lsearch_for_word_with_char	# branch if max_bytes > 3

Lnot_found:
	mov	0,g0		# char not found.  Return null
	bx	(g13)		# g0 = addr of char in src (or null);  g14 = 0
Lrett:
	ret

Lsearch_for_char:
	cmpobe.f g6,g2,Lnot_found	# quit if max_bytes exhausted
	and	g5,g7,g0	# extract byte
	cmpo	g1,g0		# is it char?
	addo	1,g6,g6		# bump src byte ptr
	shro	8,g5,g5		# shift word to position next byte
	bne.t	Lsearch_for_char
	subo	5,g6,g0		# back up the byte pointer
	bx	(g13)

/* end of memchr */

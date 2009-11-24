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

	.file "strch_ca.s"
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
	procedure strchr  (optimized assembler version for the CA)

	src_addr = strchr (src_addr, char)

	return a pointer to the first byte that contains the indicated
	byte in the source string.  Return null if the byte is not found.

	Undefined behavior will occur if the end of the source string (i.e. 
	the terminating null byte) is in the last two words of the program's
	allocated memory space.  This is so because, in several cases, strchr
	will fetch ahead.  Disallowing the fetch ahead would impose a severe 
	performance penalty.

	This program handles two cases:

	1) the argument starts on a word boundary
	2) the argument doesn't start on a word boundary

	At the time of this writing, only g0 thru g7 and g13 are available 
	for use in this leafproc;  other registers would have to be saved and
	restored.  These nine registers, plus tricky use of g14 are sufficient
	to implement the routine.  The registers are used as follows:

	g0  src ptr;  upon return it is a pointer to the matching byte, or null
	g1  char to seek
	g2  mask to avoid unimportant bytes in first word
	g3  char to seek, broadcast to all four bytes 
	g4  word of the source string
	g5  copy of the word
	g6  extracted character
	g7  byte extraction mask
	g13 return address
	g14 
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

	lda	0xff,g7		# byte extraction mask
	and	g1,g7,g1	# make char an 8-bit ordinal
	shlo	8,g1,g2		# broadcast the char to four bytes
	or	g1,g2,g2
	shlo	16,g2,g4
	cmpo	g1,g7		# is char being sought 0xff?
	or	g4,g2,g3
	 lda	(g14),g13	# preserve return address
	notand	g0,3,g5		# extract word addr of start of src
	 lda	0,g14		# conform to register linkage standard
	and	g0,3,g6		# extract byte offset of src
	 ld	(g5),g4		# fetch word containing at least first byte
	shlo	3,g6,g6		# get shift count for making mask for first word
	 lda	4(g5),g0	# post-increment src word pointer
	subi	1,0,g5		# mask initially all ones
#if __i960_BIG_ENDIAN__
	shro	g6,g5,g5	# get mask for bytes needed from first word
#else
	shlo	g6,g5,g5	# get mask for bytes needed from first word
#endif
	notor	g4,g5,g4	# set unneeded bytes to all ones
	 be.f	Lsearch_for_0xff	# branch if seeking 0xff

Lsearch_for_word_with_char_or_null:
	scanbyte g3,g4		# check for byte with char
	 lda	(g4),g5		# copy word
	ld	(g0),g4		# fetch next word of src
	 bo.f	Lsearch_for_char	# branch if null found 
	scanbyte 0,g5		# check for null byte
	 lda	4(g0),g0	# post-increment src word pointer
	bno.t	Lsearch_for_word_with_char_or_null	# branch if not null

Lnot_found:
	mov	0,g0		# char not found.  Return null
Lexit_code:
	bx	(g13)		# g0 = addr of char in src (or null);  g14 = 0
Lrett:
	ret

Lsearch_for_char:
	subo	5,g0,g0		# back up the byte pointer
Lsearch_for_char.a:
#if __i960_BIG_ENDIAN__
	rotate	8,g5,g5		# shift word to position next byte
#endif
	and	g5,g7,g6	# extract byte
	cmpo	g1,g6		# is it char?
	 lda	1(g0),g0	# bump src byte ptr
#if ! __i960_BIG_ENDIAN__
	shro	8,g5,g5		# shift word to position next byte
#endif
	 be.f	Lexit_code
	cmpobne.t 0,g6,Lsearch_for_char.a	# quit if null comes before char
	b	Lnot_found

Lsearch_for_0xff:
	lda	0xf0f0f0f0,g2	# make first comparison mask for char=-1 case.
	or	g5,g2,g2
	and	g4,g2,g4	# make unimportant bytes of first word 0x0f
	 b	Lsearch_for_word_with_char_or_null

/* end of strchr */


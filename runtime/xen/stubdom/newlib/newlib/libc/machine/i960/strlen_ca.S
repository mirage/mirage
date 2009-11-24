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

	.file "strle_ca.s"
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
	procedure strlen  (optimized assembler version for the CA)

	src_addr = strlen (src_addr)

	return the number of bytes that precede the null byte in the
	string pointed to by src_addr.

	Undefined behavior will occur if the end of the source string (i.e. 
	the terminating null byte) is in the last four words of the program's
	allocated memory space.  This is so because, in several cases, strlen
	will fetch ahead several words.  Disallowing the fetch ahead would 
	impose a severe performance penalty.

	This program handles two cases:

	1) the argument starts on a word boundary
	2) the argument doesn't start on a word boundary

	At the time of this writing, only g0 thru g7 and g13 are available 
	for use in this leafproc;  other registers would have to be saved and
	restored.  These nine registers, plus tricky use of g14 are sufficient
	to implement the routine.  The registers are used as follows:

	g0  original src ptr;  upon return it is the byte count.
	g1
	g2  src ptr  
	g3  mask
	g4  even word of the source string
	g5  odd word of the source string
	g6  copy of even word, shift count
	g7  copy of odd word
	g13 return address
	g14 byte extracted.
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

	notand	g0,3,g2		# extract word addr of start of src
	lda	(g14),g13	# preserve return address
	and	g0,3,g7		# extract byte offset of src
	ld	(g2),g5		# fetch word containing at least first byte
	shlo	3,g7,g7		# get shift count for making mask for first word
	lda	4(g2),g2	# post-increment src word pointer
	subi	1,0,g3		# mask initially all ones
	chkbit	2,g2		# are we on an even word boundary or an odd one?
#if __i960_BIG_ENDIAN__
	shro	g7,g3,g3	# get mask for bytes needed from first word
	notor	g5,g3,g7	# set unneeded bytes to all ones
	lda	0xff000000,g3	# byte extraction mask
#else
	shlo	g7,g3,g3	# get mask for bytes needed from first word
	notor	g5,g3,g7	# set unneeded bytes to all ones
	lda	0xff,g3		# byte extraction mask
#endif
	bno.f	Lodd_word	# branch if first word is odd
	mov	g7,g4		# move first word to copy thereof
	ld	(g2),g5		# load odd word
	lda	4(g2),g2	# post-increment src word pointer
	

Leven_word:
	scanbyte 0,g4		# check for null byte
	movl	g4,g6		# copy both words
Lodd_word:			# trickery!  if we branch here, following branch
				/* instruction will fall thru, as we want,  */
				/* effecting the load of g4 and g5 only. */
	ldl	(g2),g4		# fetch next pair of word of src
	bo.f	Lsearch_for_null	# branch if null found 
	scanbyte 0,g7		# check for null byte
	lda	8(g2),g2	# post-increment src word pointer
	bno.t	Leven_word	# branch if null not found yet

	subo	4,g2,g2		# back up the byte pointer
	lda	(g7),g6		# move odd word to search word
Lsearch_for_null:
	subo	9,g2,g2		# back up the byte pointer
Lsearch_for_null.a:
	and	g6,g3,g14	# extract byte
	cmpo	0,g14		# is it null?
	lda	1(g2),g2	# bump src byte ptr
#if __i960_BIG_ENDIAN__
	shlo	8,g6,g6		# shift word to position next byte
#else
	shro	8,g6,g6		# shift word to position next byte
#endif
	bne.t	Lsearch_for_null.a

Lexit_code:
	subo	g0,g2,g0	# calculate string length
	bx	(g13)		# g0 = addr of src;  g14 = 0
Lrett:
	ret

/* end of strlen */

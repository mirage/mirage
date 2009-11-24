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

	.file "strncat.s"
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
	procedure strncat  (optimized assembler version for the 80960K Series)

	dest_addr = strncat (dest_addr, src_addr, max_bytes)

	append the null terminated string pointed to by src_addr to the null 
	terminated string pointed to by dest_addr.  Return the original
	dest_addr.  If the source string is longer than max_bytes, then 
	append only max_bytes bytes, and tack on a null byte on the end.

	This routine will fail if the source and destination string
	overlap (in particular, if the end of the source is overlapped
	by the beginning of the destination).  The behavior is undefined.
	This is acceptable according to the draft C standard.

	Undefined behavior will also occur if the end of the source string
	(i.e. the terminating null byte) is in the last two words of the 
	program's allocated memory space.  This is so because strncat fetches
	ahead.  Disallowing the fetch ahead would impose a severe performance 
	penalty.

	Strategy:

	First, skip to the null byte in the destination string.  Then
	fetch the source string by words and store them by words to the
	destination string, until there are fewer than three bytes left
	to copy.  Then, using the last word of the source (the one that
	contains the remaining 0, 1, 2, or 3 bytes to be copied), store
	a byte at a time until Ldone.  

	If, before exhausting the max_byte count, the null byte is encountered
	in the source string, then just copy up thru the null byte.

	Tactics:

	1) Do NOT try to fetch and store the words in a word aligned manner 
	because, in my judgement, the performance degradation experienced due 
	to non-aligned accesses does NOT outweigh the time and complexity added
	by the preamble and convoluted body that would be necessary to assure 
	alignment.  
*/

	.globl _strncat
	.globl __strncat
	.leafproc _strncat,__strncat
	.align    2
_strncat:
#ifndef __PIC
 	lda	Lrett,g14
#else
 	lda	Lrett-(.+8)(ip),g14
#endif
__strncat:
	mov	g14,g6
	cmpibge	0, g2, Lno_operation	# Lexit early if max_bytes <= 0
	mov	g0, g5
Lskip_word_loop:
	ld	(g5), g7	# fetch word of dest string
	addo	4, g5, g5	# post-increment dest ptr
	scanbyte 0, g7		# does it contain null byte?
	bno	Lskip_word_loop	# if not, loop
	subo	5, g5, g5	# adjust dest ptr 
	lda	0xff, g3	# byte extraction mask = 0xff;
Lskip_byte_loop:
	and	g7, g3, g14	# extract byte of last word of dest string
	cmpo	0, g14		# is it null?
	addo	1, g5, g5	# adjust dest ptr
	shro	8, g7, g7	# position next byte for extraction
	bne	Lskip_byte_loop	# loop if null not found yet

	ld	(g1), g7	# fetch first word of source string
Lwloop:				# word copying loop
	cmpo	4, g2		# max_bytes < 4 ?
	addo	4, g1, g1	# post-increment source ptr
	bge	Lcloop.a		# branch if less than 4 bytes to move
	scanbyte 0, g7		# is null byte reached yet?
	mov	g7, g4		# keep a copy of the source word
	be	Lcloop		# branch if null byte reached
	ld	(g1), g7	# pre-fetch next word of source
	subo	4, g2, g2	# reduce max_byte counter
	st	g4, (g5)	# store current word
	addo	4, g5, g5	# post-increment destination ptr
	b	Lwloop

Lcloop.b:
	addo	1, g5, g5	# post-increment destination ptr
	shro	8, g7, g7	# position next byte for extraction
Lcloop:				# character copying loop  (max_byte > 3)
	and	g3, g7, g4	# extract character
	cmpo	0, g4 		# is it null?
	stob	g4, (g5)	# store it
	bne	Lcloop.b		# loop if null not encountered yet

	bx	(g6)		# g0 = dest string address; g14 = 0
Lrett:	
	ret

Lcloop.c:
	addo	1, g5, g5	# post-increment destination ptr
	shro	8, g7, g7	# position next byte for extraction
Lcloop.a:			# character copying loop  (max_byte <= 3)
	cmpdeco	0,g2,g2		# max_byte == 0?
	and	g3, g7, g4	# extract character
	be	Ldone		# store null and Lexit if max_byte exhausted
	cmpo	0, g4 		# is it null?
	stob	g4, (g5)	# store it
	bne	Lcloop.c		# loop if null not encountered yet

Ldone:	stob	g14, (g5)	# store trailing null
	bx	(g6)		# g0 = dest string address; g14 = 0

Lno_operation: mov 0, g14	# conform to register conventions
	bx	(g6)

/* end of strncat */

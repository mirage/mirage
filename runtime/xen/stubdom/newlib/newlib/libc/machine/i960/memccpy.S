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

	.file "memccpy.s"
#ifdef	__PIC
	.pic
#endif
#ifdef	__PID
	.pid
#endif
/*
 * (c) copyright 1989,1993 Intel Corp., all rights reserved
 */
/*
	procedure memccpy  (optimized assembler version for the 80960K series)

	dest_addr = memccpy (dest_addr, src_addr, char, len)

	copy len bytes pointed to by src_addr to the space pointed to by 
        dest_addr, stopping if char is copied.  If char is copied,
        return address of byte after char in dest string;  else null.


	Undefined behavior will occur if the end of the source array is in 
	the last two words of the program's allocated memory space.  This 
	is so because the routine fetches ahead.  Disallowing the fetch 
	ahead would impose a severe performance penalty.

        Undefined behavior will also occur if the source and destination
        strings overlap.

	Strategy:

	Fetch the source array by words and store them by words to the
	destination array, until there are fewer than three bytes left
	to copy.  Then, using the last word of the source (the one that
	contains the remaining 0, 1, 2, or 3 bytes to be copied), store
	a byte at a time until Ldone.

	Tactics:

	1) Do NOT try to fetch and store the words in a word aligned manner 
	because, in my judgement, the performance degradation experienced due 
	to non-aligned accesses does NOT outweigh the time and complexity added
	by the preamble and convoluted body that would be necessary to assure 
	alignment.  This is supported by the intuition that most source and
	destination arrays (even more true of most big source arrays) will 
	be word aligned to begin with.

	2) Rather than decrementing len to zero,
	I calculate the address of the byte after the last byte of the 
	destination array, and quit when the destination byte pointer passes 
	that.  

*/

	.globl _memccpy
	.leafproc _memccpy, __memccpy
	.align    2
_memccpy:
#ifndef __PIC
 	lda	Lrett,g14
#else
 	lda	Lrett-(.+8)(ip),g14
#endif
__memccpy:
	mov	g14, g13	# preserve return address
	cmpibge	0,g3,Lexit_char_not_found

	addo	g3,g1,g3	# compute beyond end of src
	ld	(g1), g7	# fetch first word of source
	lda	0xff,g5		# mask for char
	and	g5,g2,g2	# extract only char
	shlo	8,g2,g6
	or	g2,g6,g6
	shlo	16,g6,g4
	or	g6,g4,g6	# word of char
	b	Lwloop_b

Lwloop_a:
	ld	(g1), g7	# fetch ahead next word of source
	st	g4, (g0)	# store word to dest
	addo	4, g0, g0	# post-increment dest pointer
Lwloop_b:			# word copying loop
	addo	4, g1, g1	# pre-increment src pointer
	cmpo	g3, g1		# is len <= 3 ?
	mov	g7, g4		# keep a copy of the current word
	bl	Lcloop_setup	# quit word loop if less than 4 bytes
	scanbyte g6, g7		# check for char
	bno	Lwloop_a		# continue word loop if char not found.

Lcloop_setup:
	subo	4, g1, g1	# back down src pointer
	cmpobe	g1, g3, Lexit_char_not_found

Lcloop_a:			# character copying loop (len < 3)
	and	g5,g4,g7	# check the byte against char
	cmpo	g7,g2
	stob	g7,(g0)		# store the byte
	addo	1, g0, g0
	be	Lexit_char_found
	addo	1,g1,g1
	cmpo	g1,g3
	shro	8,g4,g4		# position next byte
	bne	Lcloop_a

Lexit_char_not_found:
	mov	0, g0
Lexit_char_found:
	lda	0,g14
	bx	(g13)		# g0 = dest array address; g14 = 0
Lrett:	
	ret


/* end of memccpy */

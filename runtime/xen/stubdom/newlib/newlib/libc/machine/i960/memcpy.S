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

	.file "memcpy.s"
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
	procedure memmove  (optimized assembler version for the 80960K series)
	procedure memcpy   (optimized assembler version for the 80960K series)

	dest_addr = memmove (dest_addr, src_addr, len)
	dest_addr = memcpy  (dest_addr, src_addr, len)

	copy len bytes pointed to by src_addr to the space pointed to by 
	dest_addr.  Return the original dest_addr.

	These routines will work even if the arrays overlap.  The standard
	requires this of memmove, but memcpy is allowed to fail if overlap
	is present.  Nevertheless, it is implemented the same as memmove
	because the overhead is trifling.

	Undefined behavior will occur if the end of the source array is in 
	the last two words of the program's allocated memory space.  This 
	is so because the routine fetches ahead.  Disallowing the fetch 
	ahead would impose a severe performance penalty.

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

	2) For non-overlapping arrays, rather than decrementing len to zero,
	I calculate the address of the byte after the last byte of the 
	destination array, and quit when the destination byte pointer passes 
	that.  

	3) For overlapping arrays where the source starts at a lower address
	than the destination the move is performed in reverse order.

	4) Overlapping arrays where the source starts at a higher address
	are treated like non-overlapping case.  Where the two arrays exactly
	coincide, the routine is short-circuited;  no move is Ldone at all.
	This costs only one cycle.
*/

	.globl _memcpy, _memmove
	.globl __memcpy, __memmove
	.leafproc _memmove, __memmove
	.leafproc _memcpy, __memcpy
	.align    2
_memmove:
_memcpy:
#ifndef __PIC
 	lda	Lrett,g14
#else
 	lda	Lrett-(.+8)(ip),g14
#endif
__memmove:
__memcpy:
	mov	g14, g13	# preserve return address
	cmpibge	0,g2,Lexit	# exit if number of bytes to move is <= zero.
	cmpo	g0,g1		# does start of dest overlap end of src?
	addo	g2,g1,g3
	be	Lexit		# no move necessary if src and dest are same
	concmpo	g3,g0
	addo	g2, g0, g6
	bg	Lbackwards	# if overlap, then do move backwards

	ld	(g1), g7	# fetch first word of source
	mov	g0, g5
	b	Lwloop_b

Lwloop_a:
	ld	(g1), g7	# fetch ahead next word of source
	st	g4, (g5)	# store word to dest
	addo	4, g5, g5	# post-increment dest pointer
Lwloop_b:			# word copying loop
	addo	4, g1, g1	# pre-increment src pointer
	cmpo	g3, g1		# is len <= 3 ?
	mov	g7, g4		# keep a copy of the current word
	bge	Lwloop_a		# loop if more than 3 bytes to move
	cmpobe	g6, g5, Lexit    # quit if no more bytes to move

Lcloop_a:			# character copying loop (len < 3)
	stob	g4, (g5)	# store a byte
	shro	8, g4, g4	# position next byte for storing
	addo	1, g5, g5        
	cmpobne	g6, g5, Lcloop_a	# quit if no more bytes to move

Lexit:
	mov	0, g14
	bx	(g13)		# g0 = dest array address; g14 = 0
Lrett:	
	ret

Lwloop.a:
	subo	4, g6, g6	# pre-decrement dest pointer
	st	g7, (g6)	# store word to dest
Lbackwards:			# word copying loop
	subo	4, g3, g3	# pre-decrement src pointer
	cmpo	g1, g3		# is len <= 3?
	ld	(g3), g7	# fetch ahead next word of source
	ble	Lwloop.a		# loop if more than 3 bytes to move
	cmpobe	g6, g0, Lexit	# quit if no more bytes to move

Lcloop.a:
	subo	1, g6, g6	
	rotate	8, g7, g7	# position byte for storing
	stob	g7, (g6)	# store byte
	cmpobne	g6, g0, Lcloop.a	# quit if no more bytes to move
	b	Lexit

/* end of memmove */

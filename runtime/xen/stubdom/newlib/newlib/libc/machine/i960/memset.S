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

	.file "memset.s"
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
	procedure memset  (optimized assembler version: 80960K series, 80960CA)

	dest_addr = memset (dest_addr, char, len)

	Fill len bytes pointed to by dest_addr with the value of char.
        Return the original address of dest_addr.

        This program avoids performing unaligned accesses.  It stores
        from zero to seven bytes, and then stores aligned longwords,
        and then stores from zero to seven bytes, as necessary to
        store len bytes starting at dest_addr.

	At the time of this writing, only g0 thru g7 and g13 are available 
	for use in this leafproc;  other registers would have to be saved and
	restored.  These nine registers, plus tricky use of g14 are sufficient
	to implement the routine.
*/

	.globl	_memset
	.globl	__memset
	.leafproc	_memset, __memset
	.align	2
_memset:
#ifndef __PIC
	lda 	Lrett,g14
#else
	lda 	Lrett-(.+8)(ip),g14
#endif
__memset:
	cmpo	7,g2		# are there fewer than seven characters to move?
	 lda	(g14),g13	# save return address
	notand	g0,7,g3		# test for non-aligned dest_ptr
	 lda	0,g14		# conform to register conventions
	shlo	24,g1,g4	# prepare word of char
	 lda	(g0),g6		# preserve dest_ptr for return
	shro	8,g4,g5
	 bge.f	Lcloop_setup
	cmpo	g3,g0		# is dest longword aligned
	 lda	7(g3),g3	# bump dest_ptr to next longword boundary
	or	g4,g5,g4
	 be.t	Lwloop_setup

Lbgn_cloop:
	cmpo	g6,g3		# Have we reached longword boundary?
	 stob	g1,(g6)		# store one byte of char
	subo	1,g2,g2		# decrement len
	 lda	1(g6),g6	# increment dest_ptr
	bne.t	Lbgn_cloop	# loop if more bytes to store before longword

	cmpobge.f 7,g2,Lcloop

Lwloop_setup:
	shro	16,g4,g5
	or	g4,g5,g4
	mov	g4,g5		# now have a longword of char

Lwloop:
	cmpo	15,g2		# Do we have to store more longwords?
	 stl	g4,(g6)		# Store longword of char
	subo	8,g2,g2		# Decrement len
	 lda	8(g6),g6	# Increment dest_ptr
	bl.t	Lwloop		# loop if more longwords to store

Lcloop_setup:
	cmpobge.t 0,g2,Lexit

Lcloop:
	cmpo	1,g2		# Is len exhausted?
	 stob	g1,(g6)		# Store byte
	subo	1,g2,g2		# Decrement len
	 lda	1(g6),g6	# Increment dest_ptr
	bne.t	Lcloop		# loop if more bytes to store

Lexit:	
	bx	(g13)
Lrett:	
	ret

/* end of memset */

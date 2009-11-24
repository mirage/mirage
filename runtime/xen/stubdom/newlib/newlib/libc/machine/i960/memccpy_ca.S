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

	.file "mccpy_ca.s"
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
	procedure memccpy  (optimized assembler version for the 80960CA)

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


	This program handles five cases:

	1) both arguments start on a word boundary
	2) neither are word aligned, but they are offset by the same amount
	3) source is word aligned, destination is not
	4) destination is word aligned, source is not
	5) neither is word aligned, and they are offset by differing amounts

	At the time of this writing, only g0 thru g7 and g13 are available 
	for use in this leafproc;  other registers would have to be saved and
	restored.  These nine registers, plus tricky use of g14 are sufficient
	to implement the routine.
*/

#if __i960_BIG_ENDIAN__
#define MSW g6
#define LSW g7
#else
#define LSW g6
#define MSW g7
#endif

	.globl	_memccpy
	.leafproc	_memccpy, __memccpy
	.align	2
_memccpy:
#ifndef __PIC
	lda 	Lrett,g14
#else
	lda 	Lrett-(.+8)(ip),g14
#endif
__memccpy:
	notand	g1,3,g5		# extract word addr of start of src
	 lda	(g14),g13	# preserve return address
	cmpibge.f 0,g3,Lexit_char_not_found # Lexit if # of bytes to move is <= 0
	cmpo	g5,g1		# check alignment of src
	 ld	(g5),LSW	# fetch word containing at least first byte
	notand	g0,3,g4		# extract word addr of start of dest
	 lda	4(g5),g5	# advance src word addr
	shlo	24,g2,g2	# reduce char to single byte
	 bne.f	Lcase_245	# branch if src is NOT word aligned

Lcase_13:
	cmpobe.t g0,g4,Lcase_1_setup	# branch if dest word aligned

Lcase_3:				# src is word aligned; dest is not
	mov	LSW,MSW		# make copy of first word of src
	addo	4,g4,g1		# move dest word ptr to first word boundary
	 lda	32,g14		# initialize shift count to zero

Lcase_25:
Lcase_3_cloop_at_start:		# character copying loop for start of dest str
	cmpdeci	0,g3,g3		# is max_bytes exhausted?
#if __i960_BIG_ENDIAN__
	 lda	-8(g14),g14	# augment the shift counter
#else
	 lda	8(g14),g14	# augment the shift counter
#endif
	be.f	Lexit_char_not_found	# Lexit if max_bytes is exhausted
#if __i960_BIG_ENDIAN__
	rotate	8,MSW,MSW	# move next byte into position for extraction
#endif
	shlo	24,MSW,g4
	 stob	MSW,(g0)	# store the byte in dest
	cmpo	g4,g2
	 lda	1(g0),g0	# post-increment dest ptr
#if ! __i960_BIG_ENDIAN__
	shro	8,MSW,MSW	# move next byte into position for extraction
#endif
	 be.f	Lexit_char_found	# Lexit if char found
	cmpobne.t g1,g0,Lcase_3_cloop_at_start # branch if reached word boundary

	ld	(g5),MSW	# fetch msw of operand for double shift

Lcase_4:
	shro	8,g2,g4
	or	g4,g2,g1
	shro	16,g1,g4
	or	g4,g1,g4

#if __i960_BIG_ENDIAN__
	cmpobne 0,g14,Lcase_3_wloop

Lcase_3_wloop2:
	cmpi	g3,4		# less than four bytes to move?
	 lda	4(g5),g5	# post-increment src word addr
	mov	LSW,g1		# extract 4 bytes of src
	 bl.f	Lcase_13_cloop_setup	# branch if < four bytes left to move
	scanbyte g4,g1		# branch if word has char in it
	 bo.f	Lcase_13_cloop_setup
	mov	MSW,LSW		# move msw to lsw
	 ld	(g5),MSW	# pre-fetch msw of operand for double shift
	subi	4,g3,g3		# decrease max_byte count by the 4 bytes moved
	 st	g1,(g0)		# store 4 bytes to dest
	addo	4,g0,g0		# post-increment dest ptr
	 b	Lcase_3_wloop2
#endif
	
Lcase_3_wloop:
	cmpi	g3,4		# less than four bytes to move?
	 lda	4(g5),g5	# post-increment src word addr
	eshro	g14,g6,g1	# extract 4 bytes of src
	 bl.f	Lcase_13_cloop_setup	# branch if < four bytes left to move
	scanbyte g4,g1		# branch if word has char in it
	 bo.f	Lcase_13_cloop_setup
	mov	MSW,LSW		# move msw to lsw
	 ld	(g5),MSW	# pre-fetch msw of operand for double shift
	subi	4,g3,g3		# decrease max_byte count by the 4 bytes moved
	 st	g1,(g0)		# store 4 bytes to dest
	addo	4,g0,g0		# post-increment dest ptr
	 b	Lcase_3_wloop

Lcase_1_setup:
	subo	4,g0,g0		# store is pre-incrementing;  back up dest addr
	shro	8,g2,g4
	or	g4,g2,MSW
	shro	16,MSW,g4
	or	g4,MSW,g4
	 b	Lcase_1
Lcase_1_wloop:			# word copying loop
	subi	4,g3,g3		# decrease max_byte count by the 4 bytes moved
	 ld	(g5),LSW	# pre-fetch next word of src
	addo	4,g5,g5		# post-increment src addr
	 st	g1,(g0)		# store word in dest string
Lcase_1:				# src and dest are word aligned
	cmpi	g3,4		# check for fewer than four bytes to move
	addo	4,g0,g0		# pre-increment dest addr
	 lda	(LSW),g1	# keep a copy of the src word
	 bl.f	Lcase_13_cloop_setup	# branch if less than four bytes to copy
	scanbyte LSW,g4		# branch if char is not in foursome
	bno.t	Lcase_1_wloop
Lcase_13_cloop_setup:
	cmpibe.f 0,g3,Lexit_char_not_found	# Lexit if max_bytes is exhausted

Lcase_1_cloop:
#if __i960_BIG_ENDIAN__
	rotate	8,g1,g1		# move next byte into position for extraction
#endif
	shlo	24,g1,g4
	 stob	g1,(g0)		# store the byte in dest
	cmpo	g4,g2
	 lda	1(g0),g0	# post-increment dest byte addr
	subi	1,g3,g3
	 be.f	Lexit_char_found	# Lexit if char reached
	cmpi	0,g3
#if ! __i960_BIG_ENDIAN__
	shro	8,g1,g1		# move next byte into position for extraction
#endif
	 bne.t	Lcase_1_cloop	# continue if len not exhausted

Lexit_char_not_found:
	mov	0,g0
Lexit_char_found:
	lda	0,g14
	bx	(g13)		# g0 = dest array address;  g14 = 0
Lrett:
	ret


Lcase_245:
	cmpo	g0,g4		# check alignment of dest
	 ld	(g5),MSW	# pre-fetch second half
	and	3,g1,g1		# compute shift count
	shlo	3,g1,g14	
#if __i960_BIG_ENDIAN__
	subo	g14,0,g14	# adjust shift count for big endian
#endif
	 be.t	Lcase_4		# branch if dest is word aligned
	or	g4,g1,g1	# is src earlier in word, later, or sync w/ dst
	cmpo    g0,g1		# < indicates first word of dest has more bytes
				/* than first word of source. */
	eshro	g14,g6,g4	# extract four bytes
	 lda	4(g0),g1	# move dest word addr to first word boundary
#if __i960_BIG_ENDIAN__
	 bge.f	1f
#else
	 bg.f	1f
#endif
	mov	MSW,LSW
	 lda	4(g5),g5	# move src word addr to second word boundary
1:
	notand	g1,3,g1
	 mov	g4,MSW
	 b	Lcase_25

/* end of memccpy */

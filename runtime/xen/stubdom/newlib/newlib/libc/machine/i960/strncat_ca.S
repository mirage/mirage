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

	.file "sncat_ca.s"
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
	procedure strncat  (optimized assembler version for the CA)

	dest_addr = strncat (dest_addr, src_addr, max_bytes)

	append the null terminated string pointed to by src_addr to the null 
	terminated string pointed to by dest_addr.  Return the original
	dest_addr.  If the source string is longer than max_bytes, then 
	append only max_bytes bytes, and tack on a null byte on the end

	This routine will fail if the source and destination string
	overlap (in particular, if the end of the source is overlapped
	by the beginning of the destination).  The behavior is undefined.
	This is acceptable according to the draft C standard.

	Undefined behavior will also occur if the end of the source string
	(i.e. the terminating null byte) is in the last word of the program's
	allocated memory space.  This is so because, in several cases, strncat
	will fetch ahead one word.  Disallowing the fetch ahead would impose
	a severe performance penalty.

	This program handles five cases:

	1) both arguments start on a word boundary
	2) neither are word aligned, but they are offset by the same amount
	3) source is word aligned, destination is not
	4) destination is word aligned, source is not
	5) neither is word aligned, and they are offset by differing amounts

	At the time of this writing, only g0 thru g7 and g13 are available 
	for use in this leafproc;  other registers would have to be saved and
	restored.  These nine registers, plus tricky use of g14 are sufficient
	to implement the routine.  The registers are used as follows:

	g0  original dest ptr;  not modified, so that it may be returned.
	g1  src ptr;  shift count
	g2  max_bytes
	g3  src ptr (word aligned)
	g4  dest ptr (word aligned)
	g5  0xff  --  byte extraction mask
	Little endian:
		g6  lsw of double word for extraction of 4 bytes
		g7  msw of double word for extraction of 4 bytes
	Big endian:
		g6  msw of double word for extraction of 4 bytes
		g7  lsw of double word for extraction of 4 bytes
	g13 return address
	g14 byte extracted.
*/

#if __i960_BIG_ENDIAN__
#define MSW g6
#define LSW g7
#else
#define LSW g6
#define MSW g7
#endif

	.globl	_strncat
	.globl	__strncat
	.leafproc	_strncat, __strncat
	.align	2
_strncat:
#ifndef __PIC
	lda 	Lrett,g14
#else
	lda 	Lrett-(.+8)(ip),g14
#endif
__strncat:
	notand	g0,3,g4		# extract word addr of start of dest
	 lda	(g14),g13	# preserve return address
	cmpibge.f 0,g2,Lexit_code # Lexit if number of bytes to move is <= zero.
	and	g0,3,LSW	# extract byte offset of dest
	 ld	(g4),MSW	# fetch word containing at least first byte
	shlo	3,LSW,g14	# get shift count for making mask for first word
	subi	1,0,LSW		# mask initially all ones
#if __i960_BIG_ENDIAN__
	shro	g14,LSW,LSW	# get mask for bytes needed from first word
#else
	shlo	g14,LSW,LSW	# get mask for bytes needed from first word
#endif
	notor	MSW,LSW,MSW	# set unneeded bytes to all ones
	 lda	0xff,g5		# byte extraction mask
Lsearch_for_word_with_null:
	scanbyte 0,MSW		# check for null byte
	 lda	4(g4),g4	# post-increment dest word pointer
	mov	MSW,LSW		# keep a copy of current word
	 ld	(g4),MSW	# fetch next word of dest
	 bno.t	Lsearch_for_word_with_null	# branch if null not found yet
#if __i960_BIG_ENDIAN__
	shro	24,LSW,g14	# extract byte
#else
	and	g5,LSW,g14	# extract byte
#endif
	cmpo	0,g14		# branch if null is first byte of word
	subo	4,g4,g4		# move dest word ptr to word with null
	notand	g1,3,g3		# extract word addr of start of src
	 bne.t	Lsearch_for_null

Lcase_14:
	cmpo	g1,g3		# check alignment of source
	 ld	(g3),LSW	# fetch first word of source
	shlo	3,g1,g14	# compute shift count
	 lda	4(g3),g3	# post-increment src addr
	 bne.f	Lcase_4		# branch if source is unaligned
Lcase_1:
Lcase_1_wloop:			# word copying loop
	cmpi	g2,4		# check for fewer than four bytes to move
	 lda	(LSW),g1	# keep a copy of the src word
	 bl.f	Lcase_1_cloop	# branch if fewer than four bytes to copy
	scanbyte 0,g1		# check for null byte in src word
	 ld	(g3),LSW	# pre-fetch next word of src
	addo	4,g3,g3		# post-increment src addr
	 bo.f	Lcase_1_cloop	# branch if word contains null byte
	subi	4,g2,g2		# decrease max_byte count by the 4 bytes moved
	 st	g1,(g4)		# store word in dest string
	addo	4,g4,g4		# post-increment dest addr
	 b	Lcase_1_wloop

Lcase_3_cloop:
Lcase_1_cloop:			# character copying loop (max_bytes <= 3)
	cmpdeci	0,g2,g2		# is max_bytes exhausted?
#if __i960_BIG_ENDIAN__
	rotate	8,g1,g1		# move next byte into position for extraction
#endif
	and	g5,g1,g14	# extract next char
	be.f	Lstore_null	# if max_bytes is exhausted, store null and quit
	cmpo	0,g14		# check for null byte
	 stob	g14,(g4)	# store the byte in dest
#if ! __i960_BIG_ENDIAN__
	shro	8,g1,g1		# move next byte into position for extraction
#endif
	 lda	1(g4),g4	# post-increment dest byte addr
	 bne.t	Lcase_1_cloop	# branch if null not reached
	bx	(g13)		# Lexit (g14 == 0)

Lstore_null:
	mov	0,g14		# store null, and set g14 to zero
	stob	g14,(g4)
	bx	(g13)


Lsearch_for_null:
#if __i960_BIG_ENDIAN__
	shlo	8,LSW,LSW	# check next byte
	shro	24,LSW,g14
#else
	shlo	8,g5,g5		# move mask up to next byte
	and	g5,LSW,g14	# extract byte
#endif
	 lda	1(g4),g4	# move dest byte ptr to next byte
	cmpobne.t 0,g14,Lsearch_for_null	# branch if null is not yet found

Lcase_235:
	cmpo	g1,g3		# check alignment of src
	 ld	(g3),LSW	# pre-fetch word with start of src
	and	3,g1,g1		# compute shift count
	 lda	0xff,g5		# load mask for byte extraction
	shlo	3,g1,g14	
	 lda	4(g3),g3	# post-increment src word counter
	 be.t	Lcase_3		# branch if src is word aligned
	and	g4,3,MSW	# extract byte offset for dest string
	cmpo    MSW,g1		# < indicates first word of dest has more bytes
				/* than first word of source. */
	 ld	(g3),MSW	# fetch second word of src
#if __i960_BIG_ENDIAN__
	subo	g14,0,g14	# adjust shift count for big endian
#endif
	eshro	g14,g6,g5	# extract four bytes
#if __i960_BIG_ENDIAN__
	 bge.f	1f
#else
	 bg.f	1f
#endif
	mov	MSW,LSW
	 lda	4(g3),g3	# move src word addr to second word boundary
1:
	mov	g5,MSW
	 lda	0xff,g5
	 b	Lcase_25

Lcase_3:				# src is word aligned; dest is not
	mov	LSW,MSW		# make copy of first word of src
	 lda	32,g14		# initialize shift count to zero (mod 32)
Lcase_25:

Lcase_3_cloop_at_start:		# character copying loop for start of dest str
	cmpdeci	0,g2,g2		# is max_bytes exhausted?
#if __i960_BIG_ENDIAN__
	shro	24,MSW,g5	# extract next char
#else
	and	g5,MSW,g5	# extract next char
#endif
	 be.f	Lstore_null	# Lexit if max_bytes is exhausted
	cmpo	0,g5		# check for null byte
	 stob	g5,(g4)		# store the byte in dest
	addo	1,g4,g4		# post-increment dest ptr
	 lda	0xff,g5		# re-initialize byte extraction mask
	notand	g4,3,g1		# extract word address
	 be.t	Lexit_code	# Lexit if null byte reached
	cmpo	g1,g4		# have we reached word boundary in dest yet?
#if __i960_BIG_ENDIAN__
	 lda	-8(g14),g14	# augment the shift counter
	rotate	8,MSW,MSW	# move next byte into position for extraction
#else
	 lda	8(g14),g14	# augment the shift counter
	shro	8,MSW,MSW	# move next byte into position for extraction
#endif
	 bne.t	Lcase_3_cloop_at_start	# branch if reached word boundary?

#if __i960_BIG_ENDIAN__
	cmpo	0,g14
	 ld	(g3),MSW	# fetch msw of operand for double shift
	bne	Lcase_3_wloop	# branch if src is still unaligned.

Lcase_3_wloop2:
	cmpi	g2,4		# less than four bytes to move?
	mov	LSW,g1		# extract 4 bytes of src
	 lda	4(g3),g3	# post-increment src word addr
	 bl.f	Lcase_3_cloop	# branch if < four bytes left to move
	scanbyte 0,g1		# check for null byte
	mov	MSW,LSW		# move msw to lsw
	 ld	(g3),MSW	# pre-fetch msw of operand for double shift
	 bo.f	Lcase_3_cloop	# branch if word contains null byte
	subi	4,g2,g2		# decrease max_byte count by the 4 bytes moved
	 st	g1,(g4)		# store 4 bytes to dest
	addo	4,g4,g4		# post-increment dest ptr
	 b	Lcase_3_wloop2
Lcase_4:
	subo	g14,0,g14	# adjust shift count for big endian
#else
Lcase_4:
#endif

	ld	(g3),MSW	# fetch msw of operand for double shift

Lcase_3_wloop:
	cmpi	g2,4		# less than four bytes to move?
	eshro	g14,g6,g1	# extract 4 bytes of src
	 lda	4(g3),g3	# post-increment src word addr
	 bl.f	Lcase_3_cloop	# branch if < four bytes left to move
	scanbyte 0,g1		# check for null byte
	mov	MSW,LSW		# move msw to lsw
	 ld	(g3),MSW	# pre-fetch msw of operand for double shift
	 bo.f	Lcase_3_cloop	# branch if word contains null byte
	subi	4,g2,g2		# decrease max_byte count by the 4 bytes moved
	 st	g1,(g4)		# store 4 bytes to dest
	addo	4,g4,g4		# post-increment dest ptr
	 b	Lcase_3_wloop


Lexit_code:
	mov	0,g14		# conform to register conventions
	bx	(g13)		# g0 = addr of dest;  g14 = 0
Lrett:
	ret

/* end of strncat */


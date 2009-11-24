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

	.file "sncpy_ca.s"
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
	procedure strncpy  (optimized assembler version for the CA)

	dest_addr = strncpy (dest_addr, src_addr, max_bytes)

	copy the null terminated string pointed to by src_addr to 
	the string space pointed to by dest_addr.  Return the original
	dest_addr.  If the source string is shorter than max_bytes,
        then null-pad the destination string.

	This routine will fail if the source and destination string
	overlap (in particular, if the end of the source is overlapped
	by the beginning of the destination).  The behavior is undefined.
	This is acceptable according to the draft C standard.

	Undefined behavior will also occur if the end of the source string
	(i.e. the terminating null byte) is in the last word of the program's
	allocated memory space.  This is so because, in several cases, strcpy
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

	.globl	_strncpy
	.globl	__strncpy
	.leafproc	_strncpy, __strncpy
	.align	2
_strncpy:
#ifndef __PIC
	lda 	Lrett,g14
#else
	lda 	Lrett-(.+8)(ip),g14
#endif
__strncpy:
	notand	g1,3,g3		# extract word addr of start of src
	 lda	(g14),g13	# preserve return address
	 cmpibge.f 0,g2,Lexit_code # Lexit if number of bytes to move is <= zero.
	cmpo	g3,g1		# check alignment of src
	 ld	(g3),LSW	# fetch word containing at least first byte
	notand	g0,3,g4		# extract word addr of start of dest
	 lda	4(g3),g3	# advance src word addr
	 bne.f	Lcase_245	# branch if src is NOT word aligned

Lcase_13:
	cmpo	g0,g4		# check alignment of dest
	 lda	0xff,g5		# load mask for byte extraction
	subo	4,g4,g4		# store is pre-incrementing;  back up dest addr
	 bne.f	Lcase_3		# branch if dest not word aligned

Lcase_1:				# src and dest are word aligned
Lcase_1_wloop:			# word copying loop
	cmpi	g2,4		# check for fewer than four bytes to move
	 lda	(LSW),g1	# keep a copy of the src word
	addo	4,g4,g4		# pre-increment dest addr
	 bl.f	Lcase_1_cloop.a	# branch if fewer than four bytes to copy
	scanbyte 0,g1		# check for null byte in src word
	 ld	(g3),LSW	# pre-fetch next word of src
	subi	4,g2,g2		# decrease max_byte count by the 4 bytes moved
	 bo.f	Lcase_1_cloop.c	# branch if word contains null byte
	addo	4,g3,g3		# post-increment src addr
	 st	g1,(g4)		# store word in dest string
	 b	Lcase_1_wloop

Lcase_3_cloop.a:
Lcase_1_cloop.a:			# character copying loop (max_bytes <= 3)
#if __i960_BIG_ENDIAN__
	rotate	8,g1,g1		# move next byte into position for extraction
#endif
	and	g5,g1,g14	# extract next char
Lcase_1_cloop.b:
	cmpdeci	0,g2,g2		# is max_bytes exhausted?
	be.f	Lexit_code	# Lexit if max_bytes is exhausted
	cmpo	0,g14		# check for null byte
	 stob	g14,(g4)	# store the byte in dest
#if ! __i960_BIG_ENDIAN__
	shro	8,g1,g1		# move next byte into position for extraction
#endif
	 lda	1(g4),g4	# post-increment dest byte addr
	 bne.t	Lcase_1_cloop.a	# branch if null not reached
	 b	Lcase_1_cloop.b

Lexit_code:
	mov	0,g14		# conform to register conventions
	bx	(g13)		# g0 = addr of dest;  g14 = 0
Lrett:
	ret

Lcase_1_cloop.c:
Lcase_3_cloop.c:
#if __i960_BIG_ENDIAN__
	rotate	24,g5,g5	# move mask into position for testing next byte
#endif
	and	g5,g1,g14	# extract next char
	cmpo	0,g14		# check for null byte
#if ! __i960_BIG_ENDIAN__
	 lda	(g5),LSW	# keep a copy of the current mask
	shlo	8,g5,g5		# move mask into position for testing next byte
#endif
	 bne.t	Lcase_1_cloop.c	# branch if null not reached
#if __i960_BIG_ENDIAN__
	subo	1,g5,g5		# null pad.
	andnot	g5,g1,g1	# last bytes to copy, and null pad rest of word
#else
	subo	1,LSW,g5	# mask to get last bytes to copy, and null pad
	and	g5,g1,g1	# last bytes to copy, and null pad rest of word
#endif
	st	g1,(g4)	

Lcase_1_zwloop:			# zero word loop
	cmpi	g2,4		# check for fewer than four bytes to move
	addo	4,g4,g4		# pre-increment dest addr
	 bl.f	Lcase_1_cloop.b	# branch if fewer than four bytes to copy
	subo	4,g2,g2		# decrease max_byte count by the 4 bytes moved
	 st	g14,(g4)	# store word in dest string
	 b	Lcase_1_zwloop

Lcase_3:				# src is word aligned; dest is not
	addo	8,g4,g4		# move dest word ptr to first word boundary
	 lda	(g0),g1		# copy dest byte ptr
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
	 be.f	Lexit_code	# Lexit if max_bytes is exhausted
	cmpo	0,g5		# check for null byte
	 stob	g5,(g1)		# store the byte in dest
	addo	1,g1,g1		# post-increment dest ptr
	 lda	0xff,g5		# re-initialize byte extraction mask
	 bne.t	1f		# drop thru if null byte reached (to pad)
	movl	0,g6		# blank out remainder of input buffer
1:
	cmpo	g1,g4		# have we reached word boundary in dest yet?
#if __i960_BIG_ENDIAN__
	 lda	-8(g14),g14	# augment the shift counter
	rotate	8,MSW,MSW	# move next byte into position for extraction
#else
	 lda	8(g14),g14	# augment the shift counter
	shro	8,MSW,MSW	# move next byte into position for extraction
#endif
	 bne.t	Lcase_3_cloop_at_start	# branch if reached word boundary?

	ld	(g3),MSW	# fetch msw of operand for double shift

Lcase_4:

#if __i960_BIG_ENDIAN__
	cmpobne	0,g14,Lcase_3_wloop # branch if src is still unaligned.

Lcase_3_wloop2:
	cmpi	g2,4		# less than four bytes to move?
	 lda	(LSW),g1	# extract 4 bytes of src
	lda	4(g3),g3	# post-increment src word addr
	 bl.f	Lcase_3_cloop.a	# branch if < four bytes left to move
	scanbyte 0,g1		# check for null byte
	 lda	(MSW),LSW	# move msw to lsw
	subi	4,g2,g2		# decrease max_byte count by the 4 bytes moved
	 ld	(g3),MSW	# pre-fetch msw of operand for double shift
	 bo.f	Lcase_3_cloop.c	# branch if word contains null byte
	st	g1,(g4)		# store 4 bytes to dest
	addo	4,g4,g4		# post-increment dest ptr
	 b	Lcase_3_wloop2

#endif

Lcase_3_wloop:
	cmpi	g2,4		# less than four bytes to move?
	eshro	g14,g6,g1	# extract 4 bytes of src
	 lda	4(g3),g3	# post-increment src word addr
	 bl.f	Lcase_3_cloop.a	# branch if < four bytes left to move
	scanbyte 0,g1		# check for null byte
	 lda	(MSW),LSW	# move msw to lsw
	subi	4,g2,g2		# decrease max_byte count by the 4 bytes moved
	 ld	(g3),MSW	# pre-fetch msw of operand for double shift
	 bo.f	Lcase_3_cloop.c	# branch if word contains null byte
	st	g1,(g4)		# store 4 bytes to dest
	addo	4,g4,g4		# post-increment dest ptr
	 b	Lcase_3_wloop

Lcase_245:
	cmpo	g0,g4		# check alignment of dest
	 ld	(g3),MSW	# pre-fetch second half
	and	3,g1,g1		# compute shift count
	 lda	0xff,g5		# load mask for byte extraction
#if __i960_BIG_ENDIAN__
	subo	g1,4,g14	# adjust shift count for big endian.
	shlo	3,g14,g14	
#else
	shlo	3,g1,g14	
#endif
	 be.t	Lcase_4		# branch if dest is word aligned
	or	g4,g1,g1	# is src earlier in word, later, or sync w/ dst
	cmpo    g0,g1		# < indicates first word of dest has more bytes
				/* than first word of source. */
	 lda	4(g4),g4	# move dest word addr to first word boundary
	eshro	g14,g6,g5	# extract four bytes
	 lda	(g0),g1
	 bg.f	1f
	mov	MSW,LSW
	 lda	4(g3),g3	# move src word addr to second word boundary
1:
	mov	g5,MSW
	 lda	0xff,g5
	 b	Lcase_25

/* end of strncpy */


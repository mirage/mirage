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

	.file "memcp_ca.s"
#ifdef	__PIC
	.pic
#endif
#ifdef	__PID
	.pid
#endif
/*
 * (c) copyright 1988,1992,1993 Intel Corp., all rights reserved
 */

/*
	procedure memmove  (optimized assembler version for the CA)
	procedure memcpy   (optimized assembler version for the CA)

	dest_addr = memmove (dest_addr, src_addr, len)
	dest_addr = memcpy  (dest_addr, src_addr, len)

	copy len bytes pointed to by src_addr to the space pointed to by 
	dest_addr.  Return the original dest_addr.

	Memcpy will fail if the source and destination string overlap 
	(in particular, if the end of the source is overlapped by the 
	beginning of the destination).  The behavior is undefined.
	This is acceptable according to the draft C standard.
	Memmove will not fail if overlap exists.

	Undefined behavior will also occur if the end of the source string
	(i.e. the terminating null byte) is in the last word of the program's
	allocated memory space.  This is so because, in several cases, the
	routine will fetch ahead one word.  Disallowing the fetch ahead would 
	impose a severe performance penalty.

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

	g0  dest ptr;  not modified, so that it may be returned
	g1  src ptr;  shift count
	g2  len
	g3  src ptr (word aligned)
	g4  dest ptr (word aligned)
	g5  -4 for Lbackwards move
	Little endian
		g6  lsw of double word for extraction of 4 bytes
		g7  msw of double word for extraction of 4 bytes
	Big endian
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

	.globl	_memmove, _memcpy
	.globl	__memmove, __memcpy
	.leafproc	_memmove, __memmove
	.leafproc	_memcpy,  __memcpy
	.align	2
_memcpy:
_memmove:
#ifndef __PIC
	lda 	Lrett,g14
#else
	lda 	Lrett-(.+8)(ip),g14
#endif
__memcpy:
__memmove:
	cmpibge.f 0,g2,Lquick_exit # Lexit if number of bytes to move is <= zero.
	cmpo	g0,g1		# if dest starts earlier than src ...
	 lda	(g14),g13	# preserve return address
	addo	g2,g1,g5	# compute addr of byte after last byte of src
	 be.f	Lexit_code	# no move necessary if src and dest are same
	concmpo	g5,g0		# ... or if dest starts after end of src ...
	notand	g1,3,g3		# extract word addr of start of src
	 bg.f	Lbackwards	# ... then drop thru, else do move backwards
	cmpo	g3,g1		# check alignment of src
	 ld	(g3),LSW	# fetch word containing at least first byte
	notand	g0,3,g4		# extract word addr of start of dest
	 lda	4(g3),g3	# advance src word addr
	 bne.f	Lcase_245	# branch if src is NOT word aligned

Lcase_13:
	cmpo	g0,g4		# check alignment of dest
	subo	4,g4,g4		# store is pre-incrementing;  back up dest addr
	 be.t	Lcase_1		# branch if dest word aligned

Lcase_3:				# src is word aligned; dest is not
	addo	8,g4,g4		# move dest word ptr to first word boundary
	 lda	(g0),g1		# copy dest byte ptr
	mov	LSW,MSW		# make copy of first word of src
	 lda	32,g14		# initialize shift count to zero (mod 32)

Lcase_25:
Lcase_3_cloop_at_start:		# character copying loop for start of dest str
	cmpdeci	0,g2,g2		# is max_bytes exhausted?
	be.f	Lexit_code	# Lexit if max_bytes is exhausted
#if __i960_BIG_ENDIAN__
	rotate	8,MSW,MSW	# move next byte into position for extraction
	subo	8,g14,g14	# augment the shift counter
	 stob	MSW,(g1)	# store the byte in dest
#else
	addo	8,g14,g14	# augment the shift counter
	 stob	MSW,(g1)	# store the byte in dest
	shro	8,MSW,MSW	# move next byte into position for extraction
#endif
	 lda	1(g1),g1	# post-increment dest ptr
	cmpobne.t g1,g4,Lcase_3_cloop_at_start # branch if reached word boundary

	ld	(g3),MSW	# fetch msw of operand for double shift

Lcase_4:
Lcase_3_wloop:
	cmpi	g2,4		# less than four bytes to move?
	 lda	4(g3),g3	# post-increment src word addr
	eshro	g14,g6,g1	# extract 4 bytes of src
	 bl.f	Lcase_3_cloop	# branch if < four bytes left to move
	mov	MSW,LSW		# move msw to lsw
	 ld	(g3),MSW	# pre-fetch msw of operand for double shift
	subi	4,g2,g2		# decrease max_byte count by the 4 bytes moved
	 st	g1,(g4)		# store 4 bytes to dest
	addo	4,g4,g4		# post-increment dest ptr
	 b	Lcase_3_wloop

Lcase_1_wloop:			# word copying loop
	subi	4,g2,g2		# decrease max_byte count by the 4 bytes moved
	 ld	(g3),LSW	# pre-fetch next word of src
	addo	4,g3,g3		# post-increment src addr
	 st	g1,(g4)		# store word in dest string
Lcase_1:				# src and dest are word aligned
	cmpi	g2,4		# check for fewer than four bytes to move
	addo	4,g4,g4		# pre-increment dest addr
	 lda	(LSW),g1	# keep a copy of the src word
	 bge.t	Lcase_1_wloop	# branch if at least four bytes to copy
Lcase_3_cloop:
	cmpibe.f 0,g2,Lexit_code	# Lexit if max_bytes is exhausted

Lcase_1_cloop:
#if __i960_BIG_ENDIAN__
	rotate	8,g1,g1		# move next byte into position for extraction
#endif
	subi	1,g2,g2
	 stob	g1,(g4)		# store the byte in dest
	cmpi	0,g2
	 lda	1(g4),g4	# post-increment dest byte addr
#if ! __i960_BIG_ENDIAN__
	shro	8,g1,g1		# move next byte into position for extraction
#endif
	 bne.t	Lcase_1_cloop	# Lexit if max_bytes is exhausted

Lexit_code:
	mov	0,g14		# conform to register conventions
	bx	(g13)		# g0 = addr of dest;  g14 = 0
Lrett:
	ret


Lcase_245:
	cmpo	g0,g4		# check alignment of dest
	 ld	(g3),MSW	# pre-fetch second half
	and	3,g1,g1		# compute shift count
	shlo	3,g1,g14	
#if __i960_BIG_ENDIAN__
	subo	g14,0,g14	# adjust shift count for big endian
#endif
	 be.t	Lcase_4		# branch if dest is word aligned
	or	g4,g1,g1	# is src earlier in word, later, or sync w/ dst
	cmpo    g0,g1		# < indicates first word of dest has more bytes
	 lda	4(g4),g4	# move dest word addr to first word boundary
	eshro	g14,g6,g5	# extract four bytes
	 lda	(g0),g1
#if __i960_BIG_ENDIAN__
	 bge.f	1f
#else
	 bg.f	1f
#endif
	mov	MSW,LSW
	 lda	4(g3),g3	# move src word addr to second word boundary
1:
	mov	g5,MSW
	 b	Lcase_25


Lbackwards:
	notand	g5,3,MSW	# extract word addr of byte after end of src
	cmpo	MSW,g5		# check alignment of end of src
	subo	4,MSW,g3	# retreat src word addr
	addo	g2,g0,g1	# compute addr of byte after end of dest
	notand	g1,3,g4		# extract word addr of start of dest
	 bne.f	Lcase.245	# branch if src is NOT word aligned

Lcase.13:
	cmpo	g1,g4		# check alignment of dest
	 ld	(g3),MSW	# fetch last word of src
	subo	4,g3,g3		# retreat src word addr
	 be.t	Lcase.1		# branch if dest word aligned

Lcase.3:			# src is word aligned; dest is not
	mov	MSW,LSW		# make copy of first word of src
	 lda	32,g14		# initialize shift count to zero (mod 32)

Lcase.25:
Lcase.3_cloop_at_start:		# character copying loop for start of dest str
	cmpdeci	0,g2,g2		# is max.bytes exhausted?
	 be.f	Lexit_code	# Lexit if max_bytes is exhausted
#if ! __i960_BIG_ENDIAN__
	rotate	8,LSW,LSW	# move next byte into position for storing
#endif
	 lda	-1(g1),g1	# pre-decrement dest ptr
	cmpo	g1,g4		# have we reached word boundary in dest yet?
	 stob	LSW,(g1)	# store the byte in dest
#if __i960_BIG_ENDIAN__
	shro	8,LSW,LSW	# move next byte into position for storing
	addo	8,g14,g14	# augment the shift counter
#else
	subo	8,g14,g14	# augment the shift counter
#endif
	 bne.t	Lcase.3_cloop_at_start	# branch if reached word boundary?

	ld	(g3),LSW	# fetch lsw of operand for double shift

#if __i960_BIG_ENDIAN__
	cmpobne	0,g14,Lcase.3_wloop
Lcase.3_wloop2:
	cmpi	g2,4		# less than four bytes to move?
	 lda	-4(g3),g3	# post-decrement src word addr
	mov	MSW,g1 		# extract 4 bytes of src
	 lda	(LSW),MSW	# move lsw to msw
	subo	4,g4,g4		# pre-decrement dest ptr
	 bl.f	Lcase.3_cloop	# branch if < four bytes left to move
	 ld	(g3),LSW	# pre-fetch lsw of operand for double shift
	subi	4,g2,g2		# decrease max.byte count by the 4 bytes moved
	 st	g1,(g4)		# store 4 bytes to dest
	 b	Lcase.3_wloop2
#endif

Lcase.4:
Lcase.3_wloop:
	cmpi	g2,4		# less than four bytes to move?
	 lda	-4(g3),g3	# post-decrement src word addr
	eshro	g14,g6,g1	# extract 4 bytes of src
	 lda	(LSW),MSW	# move lsw to msw
	subo	4,g4,g4		# pre-decrement dest ptr
	 bl.f	Lcase.3_cloop	# branch if < four bytes left to move
	ld	(g3),LSW	# pre-fetch lsw of operand for double shift
	subi	4,g2,g2		# decrease max.byte count by the 4 bytes moved
	 st	g1,(g4)		# store 4 bytes to dest
	 b	Lcase.3_wloop

Lcase.1_wloop:			# word copying loop
	subi	4,g2,g2		# decrease max.byte count by the 4 bytes moved
	 ld	(g3),MSW	# pre-fetch next word of src
	subo	4,g3,g3		# post-decrement src addr
	 st	g1,(g4)		# store word in dest string
Lcase.1:				# src and dest are word aligned
	cmpi	g2,4		# check for fewer than four bytes to move
	subo	4,g4,g4		# pre-decrement dest addr
	 lda	(MSW),g1	# keep a copy of the src word
	 bge.t	Lcase.1_wloop	# branch if at least four bytes to copy
Lcase.3_cloop:
	cmpibe.f 0,g2,Lexit_code	# Lexit if max_bytes is exhausted
#if ! __i960_BIG_ENDIAN__
	rotate	8,g1,g1		# move next byte into position for storing
#endif
	 lda	4(g4),g4	# pre-decremented dest addr 4 too much

Lcase.1_cloop:
	subi	1,g4,g4		# pre-decrement dest byte addr
	cmpi	g4,g0		# has dest ptr reached beginning of dest?
	 stob	g1,(g4)		# store the byte in dest
#if __i960_BIG_ENDIAN__
	shro	8,g1,g1		# move next byte into position for storing
#else
	rotate	8,g1,g1		# move next byte into position for storing
#endif
	 bne.t	Lcase.1_cloop	# Lexit if move is completed
	b	Lexit_code

Lcase.245:
	cmpo	g1,g4		# check alignment of dest
	 ld	(MSW),MSW	# pre-fetch word with at least last byte
	and	3,g5,g5		# compute shift count
	 ld	(g3),LSW	# pre-fetch second to last word
	shlo	3,g5,g14	
#if __i960_BIG_ENDIAN__
	subo	g14,0,g14	# adjust shift count for big endian
#endif
	 be.t	Lcase.4		# branch if dest is word aligned
	or	g4,g5,g5	# is src earlier in word, later, or sync w/ dst
	cmpo    g1,g5		# < indicates last word of dest has less bytes
	eshro	g14,g6,g5	# extract four bytes
	 bl.t	1f
	mov	LSW,MSW
#if ! __i960_BIG_ENDIAN__
	 be.t	1f
#endif
	subo	4,g3,g3		# move src word addr to second word boundary
1:
	mov	g5,LSW
	 b	Lcase.25


Lquick_exit:
	mov	g14,g13
	 b	Lexit_code

/* end of memmove */

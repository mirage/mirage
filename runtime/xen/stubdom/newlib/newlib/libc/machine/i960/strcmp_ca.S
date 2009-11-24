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

	.file "strcm_ca.s"
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
	procedure strcmp  (optimized assembler version for the CA)

	result = strcmp (src1_addr, src2_addr)

	compare the null terminated string pointed to by src1_addr to 
	the string space pointed to by src2_addr.  Return 0 iff the strings
	are equal, -1 if src1_addr is lexicly less than src2_addr, and 1
	if it is lexicly greater.

	Undefined behavior will occur if the end of either source string
	(i.e. the terminating null byte) is in the last word of the program's
	allocated memory space.  This is so because, in several cases, strcmp
	will fetch ahead one word.  Disallowing the fetch ahead would impose
	a severe performance penalty.

	This program handles five cases:

	1) both arguments start on a word boundary
	2) neither are word aligned, but they are offset by the same amount
	3) source1 is word aligned, source2 is not
	4) source2 is word aligned, source1 is not
	5) neither is word aligned, and they are offset by differing amounts

	At the time of this writing, only g0 thru g7 and g14 are available 
	for use in this leafproc;  other registers would have to be saved and
	restored.  These nine registers are sufficient to implement the routine.
	The registers are used as follows:

	g0  original src1 ptr;  return result
	g1  src2 ptr;  0xff  --  byte extraction mask
	g2  src1 word ptr
	g3  src2 word ptr 
	Little endian:
		g4  lsw of src1
		g5  msw of src1
		g6  src2 word
		g7  extracted src1
	Big endian:
		g4  msw of src1
		g5  lsw of src1
		g6  extracted src1
		g7  src2 word
	g13 return address
	g14 shift count
*/

#if __i960_BIG_ENDIAN__
#define MSW g4
#define LSW g5
#define SRC1 g6
#define SRC2 g7
#else
#define LSW g4
#define MSW g5
#define SRC2 g6
#define SRC1 g7
#endif

	.globl	_strcmp
	.globl	__strcmp
	.leafproc	_strcmp, __strcmp
	.align	2
_strcmp:
#ifndef __PIC
	lda 	Lrett,g14
#else
	lda 	Lrett-(.+8)(ip),g14
#endif

__strcmp:
Lrestart:
	notand	g0,3,g2		# extract word addr of start of src1
	 lda	(g14),g13	# preserve return address
#if __i960_BIG_ENDIAN__
	cmpo	g0,g2		# check alignment of src1
#endif
	 ld	(g2),LSW	# fetch word with at least first byte of src1
	notand	g1,3,g3		# extract word addr of start of src2
	 ld	4(g2),MSW	# fetch second word of src1
#if __i960_BIG_ENDIAN__
	 bne	Lsrc1_unaligned	# branch if src1 is unaligned
	cmpo	g3,g1		# check alignment of src2
	 ld	(g3),SRC2	# fetch word with at least first byte of src2
	mov	LSW,SRC1	# extract word of src1
	 lda	8(g2),g2	# advance src1 word addr
	 bne.f	Lsrc2_unaligned	# branch if src2 is NOT word aligned

				/* src2 is word aligned */

Lwloop2:				# word comparing loop
	cmpo	SRC2,SRC1	# compare src1 and src2 words
	 lda	0xff000000,g1	# byte extraction mask
	mov	MSW,LSW		# move msw of src1 to lsw
	 ld	(g2),MSW	# pre-fetch next msw of src1
	addo	4,g2,g2		# post-increment src1 addr
	 lda	4(g3),g3	# pre-increment src2 addr
	 bne.f	Lcloop		# branch if src1 and src2 unequal
	scanbyte 0,SRC1		# check for null byte in src1 word
	 ld	(g3),SRC2	# pre-fetch next word of src2
	mov	LSW,SRC1	# extract word of src1
	 lda	0,g0		# prepare to return zero, indicating equality
	bno.t	Lwloop2		# branch if null byte not encountered

				/* words were equal and contained null byte */

	mov	0,g14		# conform to register conventions
	 bx	(g13)		# return
	

Lsrc1_unaligned:
#endif
	cmpo	g3,g1		# check alignment of src2
	 ld	(g3),SRC2	# fetch word with at least first byte of src2
	shlo	3,g0,g14	# compute shift count for src1
#if __i960_BIG_ENDIAN__
	subo	g14,0,g14	# 32 - shift count for big endian.
#endif
	eshro	g14,g4,SRC1	# extract word of src1
	 lda	8(g2),g2	# advance src1 word addr
	 bne.f	Lsrc2_unaligned	# branch if src2 is NOT word aligned

				/* at least src2 is word aligned */

Lwloop:				# word comparing loop
	cmpo	SRC2,SRC1	# compare src1 and src2 words
#if __i960_BIG_ENDIAN__
	 lda	0xff000000,g1	# byte extraction mask
#else
	 lda	0xff,g1		# byte extraction mask
#endif
	mov	MSW,LSW		# move msw of src1 to lsw
	 ld	(g2),MSW	# pre-fetch next msw of src1
	addo	4,g2,g2		# post-increment src1 addr
	 lda	4(g3),g3	# pre-increment src2 addr
	 bne.f	Lcloop		# branch if src1 and src2 unequal
	scanbyte 0,SRC1		# check for null byte in src1 word
	 ld	(g3),SRC2	# pre-fetch next word of src2
	eshro	g14,g4,SRC1	# extract word of src1
	 lda	0,g0		# prepare to return zero, indicating equality
	bno.t	Lwloop		# branch if null byte not encountered

				/* words were equal and contained null byte */

	mov	0,g14		# conform to register conventions
	 bx	(g13)		# return
	
Lcloop_setup:			# setup for coming from Lsrc2_unaligned
	mov	LSW,SRC1	# restore extracted src1 word
#if __i960_BIG_ENDIAN__
	 lda	0xff000000,g1	# byte extraction mask
#else
	 lda	0xff,g1		# byte extraction mask
#endif

Lcloop:				# character comparing loop
	and	SRC2,g1,g3	# extract next char of src2
	and	SRC1,g1,g0	# extract next char of src1
	cmpobne.f g0,g3,.diff	# check for equality
	cmpo	0,g0		# check for null byte
#if __i960_BIG_ENDIAN__
	shro	8,g1,g1		# shift mask for next byte
#else
	shlo	8,g1,g1		# shift mask for next byte
#endif
	 bne.t	Lcloop		# branch if null not reached

				/* words are equal up thru null byte */

	mov	0,g14
	 bx	(g13)		# g0 = 0 (src1 == src2)
Lrett:
	ret

.diff:
	mov	0,g14
	 bl	Lless_than_exit
Lgreater_than_exit:
	mov	1,g0
	 bx	(g13)		# g0 = 1 (src1 > src2)
Lless_than_exit:
	subi	1,0,g0
	 bx	(g13)		# g0 = -1 (src1 < src2)

Lsrc2_unaligned:
	mov	SRC1,LSW	# retain src1 extracted word
	 ld	4(g3),SRC1	# fetch second word of src2
	shlo	3,g1,MSW	# compute shift count for src2
#if __i960_BIG_ENDIAN__
	subo	MSW,0,MSW	# 32 - shift count for big endian.
#endif
	eshro	MSW,g6,SRC2	# extract word of src2
	cmpo	LSW,SRC2	# compare src1 and src2 words
	notor	g1,3,MSW	# first step in computing new src1 ptr
	 lda	4(g3),g1	# set new src2 ptr
	 bne.f	Lcloop_setup	# first four bytes differ
	scanbyte 0,LSW		# check for null byte
	 lda	(g13),g14	# prepare return pointer for Lrestart
	subo	MSW,g0,g0	# second (final) step in computing new src1 ptr
	 bno.t	Lrestart		# if null byte not encountered, continue 
				/* with both string fetches shifted such that */
				/* src2 is now word aligned. */
	mov	0,g14		# conform to register conventions.
	 lda	0,g0		# return indicator of equality.
	bx	(g13)

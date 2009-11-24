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

	.file "strcp_ca.s"
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
	procedure strcpy  (optimized assembler version for the CA)     

	dest_addr = strcpy (dest_addr, src_addr)

	copy the null terminated string pointed to by src_addr to 
	the string space pointed to by dest_addr.  Return the original
	dest_addr.

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
	g2  dest ptr;  4 bytes of src
	g3  src ptr (word aligned)
	g4  dest ptr (word aligned)
	g5  0xff  --  byte extraction mask
	g6  lsw of double word for extraction of 4 bytes (little endian)
	    msw of double word for extraction of 4 bytes (big endian)
	g7  msw of double word for extraction of 4 bytes (little endian)
	    lsw of double word for extraction of 4 bytes (big endian)
	g13 return address
	g14 byte extracted.  When reaches null byte, which is zero, we will
	    be in conformance with register conventions, and can return to
	    the caller with a clear conscience.

	procedure strcat

	dest_addr = strcat (dest_addr, src_addr)

	Appends the string pointed to by src_addr to the string pointed
	to by dest_addr.  The first character of the source string is
	copied to the location initially occupied by the trailing null
	byte of the destination string.  Thereafter, characters are copied
	from the source to the destination up thru the null byte that
	trails the source string.
*/

#if __i960_BIG_ENDIAN__
#define MSW g6
#define LSW g7
#else
#define LSW g6
#define MSW g7
#endif

	.globl	_strcpy, _strcat
	.globl	__strcpy, __strcat
	.leafproc	_strcpy, __strcpy
	.leafproc	_strcat, __strcat
	.align	2
_strcat:
#ifndef __PIC
	lda	Lrett,g14
#else
	lda	Lrett-(.+8)(ip),g14
#endif
__strcat:
	notand	g0,3,g4		# extract word addr of start of dest
	lda	(g14),g13	# preserve return address
	and	g0,3,LSW	# extract byte offset of dest
	ld	(g4),MSW	# fetch word containing at least first byte
	shlo	3,LSW,g14	# get shift count for making mask for first word
	subi	1,0,LSW		# mask initially all ones
#if __i960_BIG_ENDIAN__
	shro	g14,LSW,LSW	# get mask for bytes needed from first word
	lda	0xff000000,g5	# byte extraction mask
#else
	shlo	g14,LSW,LSW	# get mask for bytes needed from first word
	lda	0xff,g5		# byte extraction mask
#endif
	notor	MSW,LSW,MSW	# set unneeded bytes to all ones
Lsearch_for_word_with_null:
	scanbyte 0,MSW		# check for null byte
	lda	4(g4),g4	# post-increment dest word pointer
	mov	MSW,LSW		# keep a copy of current word
	ld	(g4),MSW	# fetch next word of dest
	bno.t	Lsearch_for_word_with_null	# branch if null not found yet
	and	g5,LSW,g14	# extract byte
	cmpo	0,g14		# branch if null is first byte of word
	subo	4,g4,g4		# move dest word ptr back to word with null
	notand	g1,3,g3		# extract word addr of start of src
	lda	(g4),g2		# set dest byte ptr to 1st byte of word w/ null
	be.f	Lcase_14
Lsearch_for_null:
#if __i960_BIG_ENDIAN__
	shro	8,g5,g5		# move mask down to next byte
#else
	shlo	8,g5,g5		# move mask up to next byte
#endif
	lda	1(g2),g2	# move dest byte ptr to next byte
	and	g5,LSW,g14	# extract byte
	cmpobne.t 0,g14,Lsearch_for_null	# branch if null is not yet found
	lda	0xff,g5		# byte extraction mask
	b	Lcase_235.a

	
_strcpy:
#ifndef __PIC
	lda 	Lrett,g14
#else
	lda 	Lrett-(.+8)(ip),g14
#endif
__strcpy:
	notand	g0,3,g4		# extract word addr of start of dest
	lda	(g14),g13	# preserve return address
	cmpo	g0,g4		# check alignment of dest
	lda	0xff,g5		# load mask for byte extraction
	notand	g1,3,g3		# extract word addr of start of src
	bne.f	Lcase_235	# branch if dest is NOT word aligned

Lcase_14:
	cmpo	g3,g1		# check alignment of src
	ld	(g3),LSW	# fetch word containing at least first byte
	shlo	3,g1,g1		# compute shift count
	lda	4(g3),g3	# advance src word addr
#if __i960_BIG_ENDIAN__
	lda	0xff,g5		# byte extraction mask
#endif
	bne.f	Lcase_4		# branch if src is NOT word aligned

Lcase_1:				# src and dest are word aligned
	subo	4,g4,g4		# store is pre-incrementing;  back up dest addr
Lcase_1_wloop:			# word copying loop
	scanbyte 0,LSW		# check for null byte in src word
	lda	(LSW),g2	# keep a copy of the src word
	addo	4,g4,g4		# pre-increment dest addr
	ld	(g3),LSW	# pre-fetch next word of src
	addo	4,g3,g3		# post-increment src addr
	bo.f	Lcase_1_cloop	# branch if word contains null byte
	st	g2,(g4)		# store word in dest string
	b	Lcase_1_wloop

Lcase_3_cloop:
Lcase_1_cloop:			# character copying loop
#if __i960_BIG_ENDIAN__
	rotate	8,g2,g2		# move next byte into position for extraction
	and	g5,g2,g14	# extract next char
#else
	and	g5,g2,g14	# extract next char
	shro	8,g2,g2		# move next byte into position for extraction
#endif
	cmpo	0,g14		# check for null byte
	stob	g14,(g4)	# store the byte in dest
	lda	1(g4),g4	# post-increment dest byte addr
	bne.t	Lcase_1_cloop	# branch if null not reached

Lexit_code:
	bx	(g13)		# g0 = addr of dest;  g14 = 0
Lrett:
	ret

Lcase_3:				# src is word aligned; dest is not
	addo	4,g4,g4		# move dest word ptr to first word boundary
	mov	LSW,MSW		# make copy of first word of src
	lda	0,g1		# initialize shift count to zero

Lcase_25:
Lcase_3_cloop_at_start:		# character copying loop for start of dest str
#if __i960_BIG_ENDIAN__
	rotate	8,MSW,MSW	# move next byte into position for extraction
	and	g5,MSW,g14	# extract next char
#else
	and	g5,MSW,g14	# extract next char
	shro	8,MSW,MSW	# move next byte into position for extraction
#endif
	cmpo	0,g14		# check for null byte
	stob	g14,(g2)	# store the byte in dest
	lda	1(g2),g2	# post-increment dest ptr
	be.f	Lexit_code	# branch if null byte reached
	cmpo	g2,g4		# have we reached word boundary in dest?
	lda	8(g1),g1	# augment the shift counter
	bne.t	Lcase_3_cloop_at_start

Lcase_4:
	ld	(g3),MSW	# fetch msw of operand for double shift
#if __i960_BIG_ENDIAN__
	subo	g1,0,g1		# Adjust shift count for big endian.
#endif

Lcase_3_wloop:
	eshro	g1,g6,g2	# extract 4 bytes of src
	lda	4(g3),g3	# post-increment src word addr
	scanbyte 0,g2		# check for null byte
	lda	(MSW),LSW	# move msw to lsw
	ld	(g3),MSW	# pre-fetch msw of operand for double shift
	bo.f	Lcase_3_cloop	# branch if word contains null byte
	st	g2,(g4)		# store 4 bytes to dest
	addo	4,g4,g4		# post-increment dest ptr
	b	Lcase_3_wloop

Lcase_235:
	lda	(g0),g2		# copy dest ptr 
Lcase_235.a:
	cmpo	g3,g1		# check alignment of src
	ld	(g3),LSW	# fetch word containing at least first byte
	and	3,g1,g14	# compute shift count
	lda	4(g3),g3	# advance src word addr
	shlo	3,g14,g1	
	be.t	Lcase_3		# branch if dest is word aligned
	or	g4,g14,g14	# is src earlier in word, later, or sync w/ dst
	ld	(g3),MSW	# pre-fetch second half
        cmpo    g2,g14		# < indicates first word of dest has more bytes
	lda	4(g4),g4	# move dest word addr to first word boundary
				/* than first word of source. */
#if __i960_BIG_ENDIAN__
	subo	g1,0,g14	# Adjust shift count for big endian.
	eshro	g14,g6,g14	# extract four bytes
	bge.f	1f
#else
	eshro	g1,g6,g14	# extract four bytes
	bg.f	1f
#endif
	mov	MSW,LSW
	lda	4(g3),g3	# move src word addr to second word boundary
1:
	mov	g14,MSW
	b	Lcase_25

/* end of strcpy */


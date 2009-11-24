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

	.file "strncpy.s"
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
	procedure strncpy  (optimized assembler version for the 80960K Series)

	dest_addr = strncpy (dest_addr, src_addr, max_bytes)

	copy the null terminated string pointed to by src_addr to the 
	string pointed to by dest_addr.  Return the original dest_addr.
	If the source string is shorter than max_bytes, then null-pad 
	the destination string.  If it is longer than max_bytes, the 
	copy stops at max_bytes bytes (and no terminating null appears 
	in the destination string).

	This routine will fail if the source and destination string
	overlap (in particular, if the end of the source is overlapped
	by the beginning of the destination).  The behavior is undefined.
	This is acceptable according to the draft C standard.

	Undefined behavior will also occur if the end of the source string
	(i.e. the terminating null byte) is in the last two words of the 
	program's allocated memory space.  This is so because strncpy fetches
	ahead.  Disallowing the fetch ahead would impose a severe performance 
	penalty.

	Strategy:

	Fetch and store the strings by words and go to a character move loop 
	as soon as a null byte is encountered.  If max_bytes is exhausted
	first, then terminate after moving only max_bytes (with the last
	0, 1, 2, or 3 bytes moved as single bytes, not as a word).
	Otherwise, the character move loop moves the last bytes or the
	source string, and then null-pads the destination string until
	max_bytes is exhausted.

	Tactics:

	1) Do NOT try to fetch the words in a word aligned manner because,
	in my judgement, the performance degradation experienced due to 
	non-aligned accesses does NOT outweigh the time and complexity added
	by the preamble and convoluted body that would be necessary to assure 
	alignment.  

	2) When the null byte is encountered in a source word, null out the
	higher-numbered bytes in that word, store the word in the destination,
	and go to the word null-padder, which may eventually go to the byte
	null-padder.
*/

	.globl _strncpy
	.globl __strncpy
	.leafproc _strncpy,__strncpy
	.align    2
_strncpy:
#ifndef __PIC
 	lda	Lrett,g14
#else
 	lda	Lrett-(.+8)(ip),g14
#endif
__strncpy:	
	mov	g14, g13
	cmpibge	0,g2,Lexit	# quit early if max_bytes <= 0
	ld	(g1), g7	# fetch the first word of the source
	mov	g0, g5
	lda	0xff, g3	# byte extraction mask
	addo	g1, g2, g6
	addo	g2, g5, g2
Lwloop:				# word copying loop
	addo	4, g1, g1	# post-increment source ptr
	cmpo	g6, g1		# max_bytes < 4 ?
	mov	g7, g4		# keep a copy of source word
	bl	Lcloop.a		# if less than four bytes to go, go to char loop
	scanbyte 0, g4		# null byte found?
	ld	(g1), g7	# pre-fetch next word of the source
	be	Lcloop.c		# go to char loop if null encountered
	st	g4, (g5)	# store current word
	addo	4, g5, g5	# post-increment destination ptr
	b	Lwloop

Lcloop.a:			# character copying loop (max_bytes < 3)
	and	g3, g4, g14	# extract byte
Lcloop.b:
	cmpo	g2, g5		# max_bytes <= 0 ?
	shro	8, g4, g4	# position word to extract next byte
	be	Lexit		# exit if max_bytes exhausted
	cmpo	0, g14 		# is it null?
	stob	g14, (g5)	# store it
	addo	1, g5, g5	# post-increment dest ptr
	bne	Lcloop.a		# branch if we are NOT null padding
	b	Lcloop.b		# branch if we are null padding

Lexit:
	mov	0, g14
	bx	(g13)		# g0 = dest string address; g14 = 0
Lrett:	
	ret

Lcloop.c:			# character copying loop
	and	g3, g4, g14	# extract byte
	cmpo	0, g14 		# is it null?
	mov	g3, g7		# save mask
	shlo	8, g3, g3	# shift mask to next byte position
	bne	Lcloop.c		# loop until null found
	subo	1, g7, g3	# mask to null pad after null byte
	and	g3, g4, g4	# null-out stuff after null byte
	st	g4, (g5)	# store last part of src and first of null-pad
	subo	8,g2,g6		# adjust max_byte counter

Lzwloop:
	cmpo	g5, g6		# max_bytes < 4 ?
	addo	4, g5, g5	
	bg	Lcloop.b		# if so, goto character loop
	st	g14, (g5)	# store four null bytes
	b	Lzwloop

/* end of strncpy */

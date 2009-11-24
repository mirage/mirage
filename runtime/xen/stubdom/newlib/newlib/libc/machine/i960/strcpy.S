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

	.file "strcpy.s"
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
	procedure strcpy  (optimized assembler version for the 80960K series)
	procedure strcat  (optimized assembler version for the 80960K series)

	dest_addr = strcpy (dest_addr, src_addr)

	copy the null terminated string pointed to by src_addr to 
	the string space pointed to by dest_addr.  Return the original
	dest_addr.

	This routine will fail if the source and destination string
	overlap (in particular, if the end of the source is overlapped
	by the beginning of the destination).  The behavior is undefined.
	This is acceptable according to the draft C standard.

	Undefined behavior will also occur if the end of the source string
	(i.e. the terminating null byte) is in the last two words of the 
	program's allocated memory space.  This is so because strcpy fetches 
	ahead.  Disallowing the fetch ahead would impose a severe performance 
	penalty.

	Strategy:

	Fetch the source string and store the destination string by words
	until the null byte is encountered.  When the word with the null
	byte is reached, store it by bytes up through the null byte only.

	Tactics:

	1) Do NOT try to fetch and store the words in a word aligned manner 
	because, in my judgement, the performance degradation experienced due
 	to non-aligned accesses does NOT outweigh the time and complexity added
	by the preamble and convoluted body that would be necessary to assure 
	alignment.  This is supported by the intuition that most source and
	destination strings will be word aligned to begin with.


	procedure strcat

	dest_addr = strcat (dest_addr, src_addr)

	Appends the string pointed to by src_addr to the string pointed
	to by dest_addr.  The first character of the source string is
	copied to the location initially occupied by the trailing null
	byte of the destination string.  Thereafter, characters are copied
	from the source to the destination up thru the null byte that
	trails the source string.

	See the strcpy routine, above, for its caveats, as they apply here too.

	Strategy:

	Skip to the end (null byte) of the destination string, and then drop
	into the strcpy code.

	Tactics:

	Skipping to the null byte is Ldone by reading the destination string
	in long-words and scanbyte'ing them, then examining the bytes of the 
	word that contains the null byte, until the address of the null byte is
	known.  Then we drop into the strcpy routine.  It is probable (approx.
	three out of four times) that the destination string as strcpy sees
	it will NOT be word aligned (i.e. that the null byte won't be the
	last byte of a word).  But it is not worth the complication to that
	routine to force word aligned memory accesses to be gaurenteed.
*/
	.globl _strcpy, _strcat
	.globl __strcpy, __strcat
	.leafproc _strcpy,__strcpy
	.leafproc _strcat,__strcat
	.align    2
_strcat:
#ifndef __PIC
 	lda	Lrett,g14
#else
 	lda	Lrett-(.+8)(ip),g14
#endif
__strcat:
	mov	g14,g13		# preserve return address
	ldl	(g0),g4		# fetch first two words
	addo	8,g0,g2		# post-increment src word pointer
	lda	0xff,g3		# byte extraction mask

Lsearch_for_word_with_null_byte:
	scanbyte 0,g4		# check for null byte
	mov	g5,g7		# copy second word
	bo.f	Lsearch_for_null	# branch if null found 
	scanbyte 0,g7		# check for null byte
	ldl	(g2),g4		# fetch next pair of word of src
	addo	8,g2,g2		# post-increment src word pointer
	bno	Lsearch_for_word_with_null_byte	# branch if null not found yet

	subo	4,g2,g2		# back up the byte pointer
	mov	g7,g4		# move word with null to search word
Lsearch_for_null:
	subo	9,g2,g5		# back up the byte pointer
Lsearch_for_null.a:
	and	g4,g3,g6	# extract byte
	cmpo	0,g6		# is it null?
	addo	1,g5,g5		# bump src byte ptr
	shro	8,g4,g4		# shift word to position next byte
	bne	Lsearch_for_null.a
	b	Lend_of_dest_found

_strcpy:
#ifndef __PIC
 	lda	Lrett,g14
#else
 	lda	Lrett-(.+8)(ip),g14
#endif
__strcpy:
	mov	g0, g5
Lend_of_dest_found:
	ld	(g1), g2	# fetch first word of source 
	mov	g14,g6		# preserve return address
	lda	0xff, g3	# byte extraction mask = 0xff;
Lwloop:				# word copying loop
	addo	4, g1, g1	# post-increment source ptr
	scanbyte 0, g2		# does source word contain null byte?
	mov	g2, g4		# save a copy of the source word
	be	Lcloop		# branch if null present
	ld	(g1), g2	# pre-fetch next word of source
	st	g4, (g5)	# store current word
	addo	4, g5, g5	# post-increment dest ptr
	b	Lwloop

Lcloop:				# character copying loop
	and	g3, g4, g14	# extract next char
	shro	8, g4, g4	# position word for next byte extraction
	cmpo	0, g14 		# is it null?
	stob	g14, (g5)	# store the byte
	addo	1, g5, g5	# post-increment dest ptr
	bne	Lcloop		# quit if null encountered

	bx	(g6)		# g0 = dest string address; g14 = 0
Lrett:	
	ret

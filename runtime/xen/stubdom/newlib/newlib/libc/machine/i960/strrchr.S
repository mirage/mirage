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

	.file "strrchr.s"
#ifdef	__i960_BIG_ENDIAN__
#error	"This does not work in big-endian"
#endif

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
	procedure strrchr  (optimized assembler version for the 80960K series)

	src_addr = strrchr (src_addr, char)

	return a pointer to the last byte that contains the indicated
	byte in the source string.  Return null if the byte is not found.

	Undefined behavior will occur if the end of the source string (i.e. 
	the terminating null byte) is in the last two words of the program's
	allocated memory space.  This is so because strrchr fetches ahead.  
	Disallowing the fetch ahead would impose a severe performance penalty.

	Strategy:

	Fetch the source string by words and scanbyte the words for the 
	char until either a word with the byte is found or the null byte is
	encountered.  In the former case, move through the word to find the
	matching byte and save its memory address, then continue the search.  
	In the latter case, return the saved address, or zero (null) if none
	was ever found to save.

	Tactics:

	1) Do NOT try to fetch the words in a word aligned manner because,
	in my judgement, the performance degradation experienced due to 
	non-aligned accesses does NOT outweigh the time and complexity added 
	by the preamble that would be necessary to assure alignment.  This 
	is supported by the intuition that most source arrays (even more 
	true of most big source arrays) will be word aligned to begin with.
*/

	.globl	_strrchr
	.globl	__strrchr
	.leafproc	_strrchr, __strrchr
	.align	2
_strrchr:
#ifdef __PIC
	lda 	Lrett-(.+8)(ip),g14
#else
	lda 	Lrett,g14
#endif
__strrchr:

	ld	(g0),g4		# fetch first word
	lda	0xff,g7		# byte extraction mask
	and	g1,g7,g1	# make char an 8-bit ordinal
	shlo	8,g1,g2		# broadcast the char to four bytes
	or	g1,g2,g2
	shlo	16,g2,g5
	or	g2,g5,g3
	mov	g14,g13		# preserve return address
	addo	4,g0,g2		# post-increment src pointer
	mov	1,g0		# prepare to return null pointer
	mov 	g3,g6		# prepare to return null pointer

Lsearch_for_word_with_char_or_null:
	mov	g4,g5		# copy word
	scanbyte 0,g5		# check for null byte
	ld	(g2),g4		# fetch next word of src
	bo	Lword_has_null	# branch if null found 
	scanbyte g3,g5		# check for byte with char
	addo	4,g2,g2		# post-increment src pointer
	bno	Lsearch_for_word_with_char_or_null   # branch if no copy of char
	mov	g5,g6		# save word that has char in it (at least once)
	subo	4,g2,g0		# save addr of byte after word with char
	b	Lsearch_for_word_with_char_or_null

Lword_has_null:
	subo	4,g2,g2		# move src pointer back to word with null
Lfind_null:
	addo	1,g2,g2		# advance src pointer to byte after current
	and	g7,g5,g14	# extract next byte
	cmpo	g1,g14		# is current byte char?
	shro	8,g5,g5		# position next byte for extraction
	bne	1f		# skip if not char sought after
	mov	g2,g0		# save addr of byte after char
	mov	g3,g6		# save word of all char to short circuit search
1:	cmpobne	0,g14,Lfind_null	# is current byte null?

Lfind_last_char:
	rotate	8,g6,g6		# position next highest byte
	and	g7,g6,g5	# extract byte
	subo	1,g0,g0		# move pointer to that byte (or nullify)
	cmpobne	g5,g1,Lfind_last_char	# branch if not at char

	bx	(g13)		# g0 = addr of char in src (or null);  g14 = 0
Lrett:
	ret

/* end of strrchr */

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

/*
 * (c) copyright 1989,1993 Intel Corp., all rights reserved
 */

/*
	procedure strpbrk  (optimized assembler version: 80960K series, 80960CA)

	char_addr = strpbrk (string, brkset_string)

	Return the address of the first character in string that is NOT
	in the brkset_string.  Return NULL if none exists.

	At the time of this writing, only g0 thru g7 and g13 are available 
	for use in this leafproc;  other registers would have to be saved and
	restored.  These nine registers, plus tricky use of g14 are sufficient
	to implement the routine.

	This routine stays out of g3 and g4 altogether.  They may be used by 
	the strtok routine, which calls this routine in an incestuous way.
*/
#ifdef  __PIC
        .pic
#endif
#ifdef  __PID
        .pid
#endif

	.file "strprk.s"
	.globl	_strpbrk
	.globl	__strpbrk
	.leafproc	_strpbrk, __strpbrk
	.align	2

_strpbrk:
#ifdef __PIC
	lda	Lrett-(.+8)(ip),g14
	b	__strpbrk
#else
	lda	Lrett,g14
	b	__strpbrk
#endif

Lrett:	ret

__strpbrk:

Lnext_char_strpbrk:
	addo	1,g1,g2		# g2 will be the brkset ptr
	ldob	(g0),g7		# fetch next character of string
	ldob	(g1),g6		# fetch first character of brkset
	cmpobe.f 0,g7,Lexit_char_not_found	# quit if at end of string
Lscan_set_strpbrk:
	cmpo	g6,g7		# is brkset char equal to string char?
	ldob	(g2),g5		# fetch next brkset char
	addo	1,g2,g2		# bump brkset ptr
	be.f	Lexit_char_found
	cmpo	g6,0		# is brkset_string exhausted?
	lda	(g5),g6
	bne.t	Lscan_set_strpbrk # check next character of brkset
	addo	1,g0,g0		# check next character of string
	b	Lnext_char_strpbrk

Lexit_char_not_found:
	mov	0,g0		# return null if brkset char not found in string
Lexit_char_found:
	mov	g14,g13		# save return address
	lda	0,g14		# conform to register conventions
	bx	(g13)

/* end of strpbrk */

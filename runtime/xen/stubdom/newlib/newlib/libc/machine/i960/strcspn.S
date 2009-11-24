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

	.file "strcspn.s"
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
	procedure strcspn  (optimized assembler version: 80960K series, 80960CA)

	len = strcspn (string, charset)

	Return the number of characters in the maximum leading segment
	of string which consists solely of characters NOT from charset.

	At the time of this writing, only g0 thru g7 and g13 are available 
	for use in this leafproc;  other registers would have to be saved and
	restored.  These nine registers, plus tricky use of g14 are sufficient
	to implement the routine.
*/

	.globl	_strcspn
	.globl	__strcspn
	.leafproc	_strcspn, __strcspn
	.align	2

_strcspn:
#ifndef __PIC
	lda	Lrett,g14
#else
	lda	Lrett-(.+8)(ip),g14
#endif
__strcspn:
	mov	g14,g13		# save return address
	 lda	(g0),g3		# copy string pointer
	mov	0,g14		# conform to register conventions

Lnext_char:
	ldob	(g3),g7		# fetch next character of string
	addo	1,g1,g2		# g2 will be the charset ptr
	ldob	(g1),g6		# fetch first character of charset
	cmpobe.f 0,g7,Lexit	# quit if at end of string
Lscan_set:
	cmpo	g6,g7		# is charset char same as string char?
	ldob	(g2),g5		# fetch next charset char
	addo	1,g2,g2		# bump charset ptr
	be.f	Lexit
	cmpo	g6,0		# is charset exhausted?
	lda	(g5),g6
	bne.t	Lscan_set	# check next character of charset
	addo	1,g3,g3		# check next character of string
	b	Lnext_char

Lexit:
	subo	g0,g3,g0	# compute string length
	bx	(g13)
Lrett:	
	ret

/* end of strcspn */

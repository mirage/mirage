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

	.file "strdup.s"
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
	procedure strdup  (optimized assembler version: 80960K series, 80960CA)

	dest_addr = strdup (src_addr)

	Allocate memory and copy thereto the string pointed to by src_addr.
	Return the address of the copy, or null if unable to perform the
	operation.
*/

	.text
	.align	2
	.globl	_strdup
_strdup:
	mov	g0,r3		# Keep a copy of the original string addr
	callj	_strlen		# Determine how much to allocate
	addo	1,g0,g0		# Add one byte for the null byte at end
	callj	_malloc		# Allocate the storage
	cmpo	0,g0
	mov	r3,g1		# Original string addr is now src for copy
	bne.t	_strcpy		# Jump if allocation was successful
	ret			# Return the null ptr otherwise

/* end of strdup */

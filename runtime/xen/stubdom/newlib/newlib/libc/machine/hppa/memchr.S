/*
 *  (c) Copyright 1986 HEWLETT-PACKARD COMPANY
 *
 *  To anyone who acknowledges that this file is provided "AS IS"
 *  without any express or implied warranty:
 *      permission to use, copy, modify, and distribute this file
 *  for any purpose is hereby granted without fee, provided that
 *  the above copyright notice and this notice appears in all
 *  copies, and that the name of Hewlett-Packard Company not be
 *  used in advertising or publicity pertaining to distribution
 *  of the software without specific, written prior permission.
 *  Hewlett-Packard Company makes no representations about the
 *  suitability of this software for any purpose.
 */

/* SPECTRUM_ID: @(#)memchr.s	37.4     86/04/23 */
/*
 * memchr(s, c, n)
 *
 * returns pointer to first occurrence of char c
 * in first n characters of memory area s,
 * or null if c does not occur.
 */

#include "DEFS.h"

#define FROM	arg0
#define CHAR	arg1
#define COUNT	arg2
#define TEMP1	r19

ENTRY(memchr)
	comb,<=	COUNT,r0,memchrexit	/* return if count is zero */
	copy	r0,ret0			/* null if c not found in n chars */
	depi	0,23,24,CHAR		/* make char unsigned */

	ldbs,ma	1(FROM),TEMP1
memchrloop:
	comb,=,n	TEMP1,CHAR,memchrequal
	addib,<>	-1,COUNT,memchrloop
	ldbs,ma	1(FROM),TEMP1
	b,n	memchrexit

memchrequal:
	ldo	-1(FROM),ret0

memchrexit:
EXIT(memchr)

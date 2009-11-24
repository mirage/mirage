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

/* SPECTRUM_ID: @(#)memset.s	37.4     86/08/25 */
/*
 * memset(s, c, n)
 *
 * Sets first n chars in memory area s to value of character c.
 * Returns s.
 */
#ifndef _NAMESPACE_CLEAN
#define NOSECDEF   /* prevent _memset from being defined as entry */
#endif

#include "DEFS.h"

#define TO	arg0
#define FILLCHAR arg1
#define COUNT	arg2
#define TMP	r31

ENTRY(memset)
	comb,<=	COUNT,r0,msexit /* return if count not positive */
	copy	TO,ret0 	/* return value is start of copy */
	comibf,<,n	5,COUNT,msbyteloop /* be straightforward */

	dep	FILLCHAR,23,8,FILLCHAR	/* dup low byte  */
	dep	FILLCHAR,15,16,FILLCHAR /* into high bytes */

	add		TO,COUNT,TMP	/* TMP points just past fill area */
	stbys,m		FILLCHAR,0(TO)	/* fill out first word */
	/*
	 * If we're pointing to high-order byte, no fill will happen,
	 * but permissions will be checked.  We don't want this (we
	 * might be pointing at the beginning of a protected region),
	 * so we branch around stbys if neither low bits are set.
	 */
	bb,<,n		TMP,31,filend	/* if low bit is set, stbys */
	bb,>=,n		TMP,30,endfil	/* if next lowest bit isn't set */
					/*  (and lowest isn't, either) */
					/*  do not stbys */
filend:
	stbys,m,e	FILLCHAR,0(TMP)	/* fill out the last */
endfil:
	addi		4, TO, TO
	sub		TMP,TO,COUNT	/* will now divide by 4 */
	comb,=,n	COUNT,r0,msexit /* If count is zero ret. */

	extru,<>	COUNT,31,4,r1
	b		msquadloop
	depi		0,31,4,COUNT	/* will now divide by 16 */


mswordloop:
	addib,<>	-4,r1,mswordloop
	stws,ma 	FILLCHAR,4(TO)

	comb,=,n	COUNT,r0,msexit /* If count is zero ret. */

msquadloop:
	stws,ma 	FILLCHAR,4(TO)
	stws,ma 	FILLCHAR,4(TO)
	stws,ma 	FILLCHAR,4(TO)
	addib,<>	-16,COUNT,msquadloop
	stws,ma 	FILLCHAR,4(TO)
	b,n		msexit

msbyteloop:
	addib,<>	-1,COUNT,msbyteloop
	stbs,ma		FILLCHAR,1(TO)

msexit:
EXIT(memset)

/* setjmp/longjmp routines for M68HC11 & M68HC12.
 * Copyright (C) 1999, 2000, 2001, 2002 Stephane Carrez (stcarrez@nerim.fr)	
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

#if __INT__ == 32
# define val 4
# define INT32(X) X
#else
# define val 2
# define INT32(X)
#endif

#ifdef mc6811
# define REG(X) *X
#else
# define REG(X) X
#endif

	.sect .text
	.global setjmp
	.global longjmp

#ifdef mc6811
setjmp:
	xgdx
	tsy
	ldd	0,y
	std	0,x
	sty	2,x
	ldd	REG(_.frame)
	std	4,x
	ldd	REG(_.d1)
	std	6,x
	ldd	REG(_.d2)
	std	8,x
	ldd	REG(_.d3)
	std	10,x
	ldd	REG(_.d4)
	std	12,x
	ldd	REG(_.d5)
	std	14,x
	ldd	REG(_.d6)
	std	16,x
	ldd	REG(_.d7)
	std	18,x
	ldd	REG(_.d8)
	std	20,x
INT32(	ldx	#0)
	clra
	clrb
	rts
#else
setjmp:
	xgdx
	movw	0,sp,2,x+
	sts	2,x+
	movw	_.frame,2,x+
	movw	_.d1,2,x+
	movw	_.d2,2,x+
	movw	_.d3,2,x+
	movw	_.d4,2,x+
	movw	_.d5,2,x+
	movw	_.d6,2,x+
	movw	_.d7,2,x+
	movw	_.d8,2,x+
INT32(	ldx	#0)
	clra
	clrb
	rts
#endif

#ifdef mc6811
longjmp:
	xgdx
	tsy
	ldd	val,y
	bne	do_jump
	ldd	#1
do_jump:
	xgdy
	ldd	4,x
	std	REG(_.frame)
	ldd	6,x
	std	REG(_.d1)
	ldd	8,x
	std	REG(_.d2)
	ldd	10,x
	std	REG(_.d3)
	ldd	12,x
	std	REG(_.d4)
	ldd	14,x
	std	REG(_.d5)
	ldd	16,x
	std	REG(_.d6)
	ldd	18,x
	std	REG(_.d7)
	ldd	20,x
	std	REG(_.d8)
	ldd	0,x
	ldx	2,x
	txs
	std	0,x
INT32(	ldx	#0)
	xgdy
	rts
#else

longjmp:
	xgdx
	ldy	val,sp
	bne	do_jump
	ldy	#1
do_jump:
	ldd	4,x+
	movw	2,x+,_.frame
	movw	0,x,_.d1
	movw	2,x,_.d2
	movw	4,x,_.d3
	movw	6,x,_.d4
	movw	8,x,_.d5
	movw	10,x,_.d6
	movw	12,x,_.d7
	movw	14,x,_.d8
	ldx	-4,x
	txs
	std	0,x
INT32(	ldx	#0)
	xgdy
	rts
#endif
	

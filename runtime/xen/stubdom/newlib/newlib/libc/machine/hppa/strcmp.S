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

/*

	strcmp

	Jerry Huck
	Edgar Circenis

*/
/* 
 * strcmp(s1, s2)
 *
 * returns integer: < 0 iff s1 lexicographically less than s2
 * 		    > 0 iff s1 lexicographically greater than s2
 * 		    = 0 iff s1 lexicographically equal to s2
 */

#include "DEFS.h"

#define s1	 26
#define s2	 25
#define tmp1     19
#define s2word   20
#define tmp3     21
#define tmp7     22
#define s1word	 23
#define save	  1
#define tmp6	 24
#define tmp5	 28

ENTRY(strcmp)
	comb,=,n   s1,s2,samestring
	comib,=,n  0,s1,s1isnull
        comib,=,n  0,s2,s2isnull
/* Hope for word alignment.  Pick up low two bits of each adress */
        extru,<>   s1,31,2,tmp1
        ldwm       4(s1),s1word
        dep,=      s2,29,2,tmp1
        b,n        case_analysis

/* Start looping until null is found in s1 or they mis-compare */
loop:
        ldwm       4(s2),s2word
loop_plus:
        uxor,nbz   s1word,r0,r0   /* Null in this? */
        b,n        nullins1
        comb,=,n   s1word,s2word,loop
        ldwm       4(s1),s1word

/* The words do not compare equal and s1 does not have a null.
   Need to treat words as unsigned and generate either a positive
   or negative return value */
wordcomparereturn:
        comclr,>>  s1word,s2word,ret0    /*Set ret0 to 0 and skip if greater*/
        ldi        -2,ret0           /*Set ret0 to -2 when less */
        bv         r0(rp)
        addi       1,ret0,ret0           /*Fix return value to be -1 or +1 */

/* s1 has a null.  s2 has not been checked. */
nullins1:
        /*If s2 has no nulls this is simple, but assume that it might
          and fix up s1 to allow the word comparision to work by
          scanning s1 and duplicating all the bytes in s2 below that byte into
          the remainder of s1.  A remainder only exists if the zero byte
          is found in the upper three bytes */
        extru,<>   s1word,7,8,r0         /*in the first byte? */
        dep,tr     s2word,31,24,s1word   /*copy low 3 bytes of *s2 into *s1 */
        extru,<>   s1word,15,8,r0         /*in the second byte? */
        dep,tr     s2word,31,16,s1word   /*copy low 2 bytes of *s2 into *s1 */
        extru,<>   s1word,23,8,r0         /*in the third byte? */
        dep        s2word,31,8,s1word   /*copy low 1 byte of *s2 into *s1 */
        /* Do the normal unsigned compare and return */
        comclr,<>  s1word,s2word,ret0    /*Set ret0 to 0 and skip if not equal */
	bv,n	   r0(rp)
        comclr,>>  s1word,s2word,ret0    /*Set ret0 to 0 and skip if greater*/
        ldi        -2,ret0           /*Set ret0 to -2 when less */
        bv         r0(rp)
        addi       1,ret0,ret0           /*Fix return value to be -1 or +1 */

/* s1 and s2 are the same string and therefore equal */
samestring:
        bv      r0(rp)
        copy    r0,ret0
/* s1 is null.  Treat as string of nulls.  Therefore return
   the negative of s2's first byte.  s2 cannot be zero. */
s1isnull:
	ldbs	0(0,s2),ret0
        bv      r0(rp)
	sub	0,ret0,ret0
/* s2 is null.  Treat as string of nulls.  Therefore return 
   s1's first byte.  s1 cannot be zero. */
s2isnull:
        bv      r0(rp)
	ldbs	0(0,s1),ret0

case_analysis:
	blr	tmp1,r0
	nop

	/*
	   Case statement for non-aligned cases (we've already
	   checked the aligned case.
	   NOTE: for non-aligned cases, the absolute shift value
	   gets loaded into tmp3.
	*/

				/* S2 S1 */
	nop			/* 00 00 can't happen */
	nop
	b	shifts2		/* 00 01 */
	ldi	8,tmp3		/* load shift count (delay slot) */
	b	shifts2		/* 00 10 */
	ldi	16,tmp3		/* load shift count (delay slot) */
	b	shifts2		/* 00 11 */
	ldi	24,tmp3		/* load shift count (delay slot) */
	b	shifts1_0	/* 01 00 */
	ldi	8,tmp3		/* load shift count (delay slot) */
	b	eq_align1	/* 01 01 */
	ldbs,ma	1(s1),s1word
	b	shifts2		/* 01 10 */
	ldi	8,tmp3		/* load shift count (delay slot) */
	b	shifts2		/* 01 11 */
	ldi	16,tmp3		/* load shift count (delay slot) */
	b	shifts1_0	/* 10 00 */
	ldi	16,tmp3		/* load shift count (delay slot) */
	b	shifts1		/* 10 01 */
	ldi	8,tmp3		/* load shift count (delay slot) */
	b	eq_align2	/* 10 10 */
	ldhs,ma	2(s1),s1word
	b	shifts2		/* 10 11 */
	ldi	8,tmp3		/* load shift count (delay slot) */
	b	shifts1_0	/* 11 00 */
	ldi	24,tmp3		/* load shift count (delay slot) */
	b	shifts1		/* 11 01 */
	ldi	16,tmp3		/* load shift count (delay slot) */
	b	shifts1		/* 11 10 */
	ldi	8,tmp3		/* load shift count (delay slot) */
	ldbs,ma	1(s1),s1word	/* 11 11 */
	ldbs,ma 1(s2),s2word
	sub,=	s1word,s2word,ret0	/* if not equal, we can return now */
	bv,n	r0(rp)
	comclr,<>	s1word,r0,ret0
	bv,n	r0(rp)			
	b	loop			/* fall into main loop */
	ldwm	4(s1),s1word

eq_align1:
	ldbs,ma 1(s2),s2word
	sub,=	s1word,s2word,ret0	/* if not equal, we can return now */
	bv,n	r0(rp)
	comclr,<>	s1word,r0,ret0
	bv,n	r0(rp)			
	/* fall through to half-word aligned case */
	ldhs,ma	2(s1),s1word		/* load next halfword */
eq_align2:
	ldhs,ma	2(s2),s2word		/* load next halfword */
	/* form the mask: 0xffff0000 and mask leading nulls in s1word and s2word
	   so that we can fall into the main loop with word aligned data */
	ldi	16,save	
	mtctl	save,r11
	zvdepi	-2,32,save
	or	save,s1word,s1word
	b	loop_plus		/* fall into main loop */
	or	save,s2word,s2word

/* s2's alignment is greater than s1's alignment, so we will shift s1 */
shifts1_0:
	addi	-4,s1,s1		/* fix up s1 due to earlier read */
shifts1:
        extru   s1,31,2,tmp1
        extru   s2,31,2,tmp5
	dep	r0,31,2,s1		/* Compute word address of s1 */
	dep	r0,31,2,s2		/* Compute word address of s2 */
	ldwm	4(s1),s1word		/* get first word of s1 */
	ldwm	4(s2),s2word		/* get first word of s2 */
	combt,=,n	r0,tmp1,masks2	/* Do we need to mask beginning of s1 */
	sh3add	tmp1,r0,save		/* save now has number of bits to mask */
	mtctl	save,r11
	zvdepi	-2,32,save		/* load save with proper mask */
	or	save,s1word,s1word
masks2:
	sh3add	tmp5,r0,save		/* save now has number of bits to mask */
	mtctl	save,r11
	zvdepi	-2,32,save		/* load save with proper mask */
	or	save,s2word,s2word
	ldi	-1,tmp7			/* load tmp7 with 0xffffffff */
	mtctl	tmp3,r11		/* Move shift amount to CR11 */
more:	uxor,nbz	s1word,r0,r0	/* Is there a null in s1? */
	b	ends1
	vshd	tmp7,s1word,save
	combf,=,n	save,s2word,cmps1
	ldwm	4(s1),tmp7
	ldwm	4(s2),s2word
	uxor,nbz	tmp7,r0,r0	/* is there a null in s1? */
	b	ends1_0
	vshd	s1word,tmp7,save
	combf,=,n	save,s2word,cmps1
	ldwm	4(s1),s1word
	b	more
	ldwm	4(s2),s2word

cmps1:	movb,tr		save,s1word,wordcomparereturn
	nop

ends1_0:
	copy	tmp7,s1word			/* move tmp7 to s1word */
ends1:
	combf,=,n	save,s2word,nullins1	/* branch if no match */
	copy	save,s1word			/* delay slot */
/* At this point, we know that we've read a null */
/* from s1, so we can't read more from s1 */
	uxor,nbz	save,r0,r0		/* are the strings equal? */
	b,n	samestring
	vshd	s1word,r0,s1word
	b	nullins1
	ldwm	4(s2),s2word

/* s1's alignment is greater than s2's alignment, so we will shift s2 */
shifts2:
        extru   s1,31,2,tmp1
        extru   s2,31,2,tmp5
	dep	r0,31,2,s1		/* Compute word address of s1 */
	dep	r0,31,2,s2		/* Compute word address of s2 */
	ldwm	4(s2),s2word		/* get first word of s2 */
	ldwm	4(s1),s1word		/* get first word of s1 */
	combt,=,n	r0,tmp5,masks1	/* Do we need to mask beginning of s2 */
	sh3add	tmp5,r0,save		/* save now has number of bits to mask */
	mtctl	save,r11
	zvdepi	-2,32,save		/* load save with proper mask */
	or	save,s2word,s2word
masks1:
	sh3add	tmp1,r0,save		/* save now has number of bits to mask */
	mtctl	save,r11
	zvdepi	-2,32,save		/* load save with proper mask */
	or	save,s1word,s1word
	ldi	-1,tmp7			/* load tmp7 with 0xffffffff */
	mtctl	tmp3,r11		/* Move shift amount to CR11 */
more1:	uxor,nbz	s2word,r0,r0	/* is there a null in s2? */
	b	ends2
	vshd	tmp7,s2word,save
	combf,=,n	s1word,save,cmps2
	ldwm	4(s2),tmp7
	ldwm	4(s1),s1word
	uxor,nbz	tmp7,r0,r0	/* is there a null in s2? */
	b	ends2_0
	vshd	s2word,tmp7,save
	combf,=,n	s1word,save,cmps2
	ldwm	4(s2),s2word
	b	more1
	ldwm	4(s1),s1word

cmps2:	movb,tr		save,s2word,wordcomparereturn
	nop

ends2_0:
	copy	tmp7,s2word			/* move tmp7 to s2word */
ends2:
	combf,=,n	s1word,save,nullins1	/* branch if no match */
	copy	save,s2word			/* delay slot */
/* At this point, we know that we've read a null */
/* from s2, so we can't read more from s2 */
	uxor,nbz	save,r0,r0		/* are the strings equal? */
	b,n	samestring
	vshd	s2word,r0,s2word
	b	nullins1
	ldwm	4(s1),s1word

EXIT(strcmp)

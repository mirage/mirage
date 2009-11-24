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

/* memcmp(s1, s2, n) */
/* returns integer: < 0 iff s1 lexicographically less than s2 */
/* 		    > 0 iff s1 lexicographically greater than s2 */
/* 		    = 0 iff s1 lexicographically equal to s2 */
/*  		    = 0 iff s1 lexicographically equal to s2 */
/*		    quit after n charachters */
#ifndef _NAMESPACE_CLEAN
#define NOSECDEF   /* prevents _memcmp from becoming primary entry */
#endif

#include "DEFS.h"

#define s1 26
#define s2 25
#define tmp1 19
#define s2word 20
#define tmp3 21
#define tmp7 22
#define s1word 29
#define save 1
#define tmp6 23
#define tmp5 28
#define count 24

ENTRY(memcmp)
	combt,<,n	r0,count,search	/*N <= 0 yields equality */
	b	done			/**/
	copy	0,ret0			/*return 0 (DELAY SLOT) */
search:	combf,=,n 	s1,s2,findout 	/*s1 != s2? */
        b	done
        copy 	0,ret0			/*return 0 (delay slot) 	 */
findout:
        comibf,=,n 	0,s1,checks1	/*s1 == NULL? 	 */
	ldbs	0(0,s2),ret0		/**/
        b	done 			/*quit	 */
	sub	0,ret0,ret0		/*ret0 <- -*s2 */
checks1:
        comibf,=,n 	0,s2,checkitout	/*s2 == NULL? 	 */
        b	done 			/* quit	 */
        ldbs 	0(0,s1),28 		/* return *s1 */

checkitout:
        extru	s2,31,2,tmp1		/* Extract the low two bits of the s2. */
        extru	s1,31,2,tmp5		/* Extract the low two bits of the s1 */
        sub,=	tmp5,tmp1,tmp3		/* Are s1 & s2 aligned with each other? */
	b	not_aligned		/* It's more complicated (not_aligned) */
	dep	0,31,2,s1		/* Compute word address of s1 (DELAY SLOT) */
	dep	0,31,2,s2		/* Compute word address of s2 */
	ldwm	4(0,s1),s1word		/* get next s1 word  s1+=4 */
	combt,=	tmp5,r0,skipmask	/* skip masking, if we can */
	ldwm	4(0,s2),s2word		/* get next s2 word  s2+=4 (DELAY SLOT) */
	add	tmp5,count,count	/* bump count by the number of bytes */
					/*  we are going to mask */
	sh3add	tmp5,r0,save		/* save now has number of bits to mask */
	mtctl	save,11
	zvdepi	-2,32,save		/* load save with proper mask */
	or	save,s1word,s1word	/* mask s1word (s1) */
	or	save,s2word,s2word	/* mask s2word (s2) */
 	

skipmask:
	combt,=,n	s1word,s2word,checkN	/* We may be done */

checkbyte:
	extru	s1word,7,8,tmp3		/* get first byte (character) */
ckbyte2:	extru	s2word,7,8,tmp7		/* get first byte (character) */
	combf,=	tmp3,tmp7,done		/* quit if first byte is not equal */
	sub	tmp3,tmp7,ret0		/* return difference (delay slot) */
	addibt,<=,n	-1,count,done	/* have we checked N chars? ret0 == 0 */
	extru	s1word,15,8,tmp3	/* get second byte (character) */
	extru	s2word,15,8,tmp7	/* get second byte (character)	 */
	combf,=	tmp3,tmp7,done		/* quit if second byte is not equal */
	sub	tmp3,tmp7,ret0		/* return difference (delay slot) */
	addibt,<=,n	-1,count,done	/* have we checked N chars? */
	extru	s1word,23,8,tmp3	/* get third byte (character) */
	extru	s2word,23,8,tmp7	/* get third byte (character)	 */
	combf,=	tmp3,tmp7,done		/* done if third byte is not equal */
	sub	tmp3,tmp7,ret0		/* return difference (delay slot) */
	addibt,<=,n	-1,count,done	/* have we checked N chars? */
	extru	s1word,31,8,tmp3	/* get last byte (character) */
	extru	s2word,31,8,tmp7	/* get last byte (character)	 */
	b	done			/* if we reach this point we know that */
	sub	tmp3,tmp7,ret0		/*  the last character in the word is */
					/*   where the  difference is, so return */
					/*    the difference and we're outta here */


checkN:
	addibt,<=,n	-4,count,zero	/* have we checked N chars? */
	ldwm	4(0,s2),s2word		/* get next s2 word  s2+=4 */
	b	skipmask		/* keep checking */
	ldwm	4(0,s1),s1word		/* get next s1 word  s1+=4 */


not_aligned:
	dep	r0,31,2,s2		/* Compute word address of s2 */
	combt,<,n	r0,tmp3,shifts1	/* Do we shift s1 or s2 */
	sh3add	tmp3,r0,tmp3		/* eight bits per byte so mul by 8 */
	ldwm	4(0,s1),s1word		/* get first word of s1 */
	ldwm	4(0,s2),s2word		/* get first word or s2 */
	combt,=,n	r0,tmp5,masks2	/* Do we need to mask beginning of s1 */
	add	tmp5,count,count	/* bump count by the number of bytes */
					/*  we are going to mask */
	sh3add	tmp5,r0,save		/* save now has number of bits to mask */
	mtctl	save,11
	zvdepi	-2,32,save		/* load save with proper mask */
	or	save,s1word,s1word	/**/
masks2:	sh3add	tmp1,r0,save		/* save now has number of bits to mask */
	mtctl	save,11
	zvdepi	-2,32,save		/* load save with proper mask */
	or	save,s2word,s2word	/**/
	subi	4,tmp1,tmp1		/* tmp1 now has the number of byte that */
					/* are valid in s2word before the vshd */
	mtctl	tmp3,11			/* Move shift amount to CR11 */
more:	combt,<=,n	count,tmp1,chunk1	/* Can we do the vshd? */
	ldwm	4(0,s2),tmp7		/* load second word to enable us to shift */
	vshd	s2word,tmp7,s2word	/**/
	combf,=,n	s1word,s2word,ckbyte2	/**/
	extru	s1word,7,8,tmp3		/* get first byte (DELAY SLOT) */
	addibt,<=,n	-4,count,zero	/* have we checked N chars? */
	copy	tmp7,s2word		/**/
	b	more			/* keep checking */
	ldwm	4(0,s1),s1word		/* get next s1 (DELAY SLOT) */

chunk1:
	vshd	s2word,r0,s2word	/* do an arithmetic shift left to position data */
	b	ckbyte2			/**/
	extru	s1word,7,8,tmp3		/**/


shifts1:
	sh3add	tmp3,r0,tmp3		/* eight bits per byte so mul by 8 */
	sub	r0,tmp3,tmp3		/* Get negative value for left shift */
	dep	r0,31,2,s2		/* Compute word address of s2 */
	ldwm	4(0,s2),s2word		/* get first word of s2 */
	ldwm	4(0,s1),s1word		/* get first word or s1 */
	combt,=,n	r0,tmp1,masks1	/*Do we need to mask beginning of s2 */
	add	tmp1,count,count	/*bump count by the number of bytes */
					/* we are going to mask */
	sh3add	tmp1,r0,save		/*save now has number of bits to mask */
	mtctl	save,11
	zvdepi	-2,32,save		/*load save with proper mask */
	or	save,s2word,s2word	/**/
masks1:	sh3add	tmp5,r0,save		/*save now has number of bits to mask */
	mtctl	save,11
	zvdepi	-2,32,save		/*load save with proper mask */
	or	save,s1word,s1word	/**/
	subi	4,tmp5,tmp5		/*tmp5 now has the number of byte that */
					/*are valid in s1word before the vshd */
	mtctl	tmp3,11			/*Move shift amount to CR11 */
more1:	combt,<=,n	count,tmp5,chunk2	/*Can we do the vshd? */
	ldwm	4(0,s1),tmp7		/*load second word to enable us to shift */
	vshd	s1word,tmp7,s1word	/**/
	combf,=,n	s2word,s1word,ckbyte2	/**/
	extru	s1word,7,8,tmp3		/*get first byte (DELAY SLOT) */
	addibt,<=,n	-4,count,zero	/*have we checked N chars? */
	copy	tmp7,s1word		/**/
	b	more1			/*keep checking */
	ldwm	4(0,s2),s2word		/*get next s2 (DELAY SLOT) */

chunk2:	
	vshd	s1word,r0,s1word	/**/
	b	ckbyte2			/**/
	extru	s1word,7,8,tmp3		/**/

zero:	copy 	r0,ret0
done:
EXIT(memcmp)

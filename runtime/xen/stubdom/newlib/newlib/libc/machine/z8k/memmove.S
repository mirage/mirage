/*
 * memmove routine for Z8000
 * Copyright (C) 2004 Christian Groessler <chris@groessler.org>
 *
 * Permission to use, copy, modify, and distribute this file
 * for any purpose is hereby granted without fee, provided that
 * the above copyright notice and this notice appears in all
 * copies.
 *
 * This file is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

/* void *memmove(void *dest, const void *src, size_t length);
 */

	name	"memmove.S"

	.text
	even
global	_memmove

_memmove:

#ifdef __Z8001__
	segm

#ifdef __STD_CALL__
	ldl	rr6,rr14(#4)
	ldl	rr4,rr14(#8)
	ldl	rr2,rr14(#12)
#else
	pushl	@rr14,rr6
#endif

/* rr2  - length	(high word ignored)
 * rr4  - src
 * rr6  - dest
 */

	testl	rr2
	jr	z,finish

/*  check for destructive overlap (src < dest && dest < src + length) */

	cpl	rr6,rr4
	jp	ule,memmove_entry	/* non-destructive, let memcpy do the work */
	ldl	rr0,rr2
	addl	rr0,rr4			/* rr0 = src + length */
	cpl	rr0,rr6
	jp	ult,memmove_entry	/* non-destructive, let memcpy do the work */

/* set-up pointers to copy backwards, add (length - 1) */
	addl	rr4,rr2			/* src + length */
	addl	rr6,rr2			/* dest + length */
	subl	rr4,#1
	subl	rr6,#1

/* check alignment */
	bitb	rl7,#0		/* odd destination address? */
	jr	z,testsrc
	bitb	rl5,#0		/* odd source address? */
	jr	z,odd_copy
	jr	even_copy

testsrc:
	bitb	rl5,#0
	jr	nz,odd_copy	/* src even, dest odd */
	lddb	@rr6,@rr4,r3
	jr	ov,finish	/* jump if r5 is zero now */

/* copy words */
even_copy:
	ld	r2,r3			/* remember length */
	srl	r3,#1
/*	jr	z,no_words	   it cannot be zero here */

	dec	r5,#1
	dec	r7,#1
	lddr	@rr6,@rr4,r3

no_words:
	bitb	rl2,#0		/* odd length? */
	jr	z,finish
	inc	r5,#1
	inc	r7,#1
	lddb	@rr6,@rr4,r2	/* yes, copy last byte */
	jr	finish

/* copy bytes */
odd_copy:
	lddrb	@rr6,@rr4,r3

finish:
#ifdef __STD_CALL__
	ldl	rr6,rr14(#4)
#else
	popl	rr2,@rr14
#endif


#else		/* above Z8001, below Z8002 */


	unsegm

#ifdef __STD_CALL__
	ld	r7,r15(#2)
	ld	r6,r15(#4)
	ld	r5,r15(#6)
#else
	ld	r2,r7		/* buffer pointer return value */
#endif

/* r5  - length
 * r6  - src
 * r7  - dest
 */
	test	r5
	jr	z,finish

/*  check for destructive overlap (src < dest && dest < src + length) */

	cp	r7,r6
	jp	ule,memmove_entry	/* non-destructive, let memcpy do the work */
	ld	r0,r5
	add	r0,r6			/* r0 = src + length */
	cp	r0,r7
	jp	ult,memmove_entry	/* non-destructive, let memcpy do the work */

/* set-up pointers to copy backwards, add (length - 1) */
	add	r6,r5			/* src + length */
	add	r7,r5			/* dest + length */
	dec	r6,#1
	dec	r7,#1

/* check alignment */
	bitb	rl7,#0		/* odd destination address? */
	jr	z,testsrc
	bitb	rl6,#0		/* odd source address? */
	jr	z,odd_copy
	jr	even_copy

testsrc:
	bitb	rl6,#0
	jr	nz,odd_copy	/* src even, dest odd */
	lddb	@r7,@r6,r5
	jr	ov,finish	/* jump if r5 is zero now */

/* copy words */
even_copy:
	ld	r4,r5		/* remember length */
	srl	r5,#1
/*	jr	z,no_words	   it cannot be zero here */

	dec	r6,#1
	dec	r7,#1
	lddr	@r7,@r6,r5

no_words:
	bitb	rl4,#0		/* odd length? */
	jr	z,finish
	inc	r6,#1
	inc	r7,#1
	lddb	@r7,@r6,r4	/* yes, copy last byte */
	jr	finish

/* copy bytes */
odd_copy:
	lddrb	@r7,@r6,r5

finish:
#ifdef __STD_CALL__
	ld	r7,r15(#2)
#endif

#endif	/* Z8002 */

	ret
	.end

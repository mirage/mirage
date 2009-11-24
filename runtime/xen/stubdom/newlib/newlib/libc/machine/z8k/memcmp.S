/*
 * memcmp routine for Z8000
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

/* int memcmp(const void *b1, const void *b2, size_t length);
 */

	name	"memcmp.S"

	.text
	even
global	_memcmp

_memcmp:

#ifdef __Z8001__
	segm

#ifdef __STD_CALL__
	ldl	rr6,rr14(#4)
	ldl	rr4,rr14(#8)
	ldl	rr2,rr14(#12)
#endif

/* rr2  - length	(high word ignored)
 * rr4  - b2
 * rr6  - b1
 */

	clr	r1		/* initialize return value */
	testl	rr2
	jr	z,finish

	bitb	rl7,#0		/* odd b1? */
	jr	nz,testb2
	bitb	rl5,#0		/* odd b2? */
	jr	nz,odd_cmp	/* b1 even, b2 odd */
	jr	t,even_cmp

testb2:
	bitb	rl5,#0
	jr	z,odd_cmp	/* b2 even, b1 odd */

	cpsib	@rr6,@rr4,r3,eq
	jr	z,beq		/* bytes are the same */
	jr	t,byte_diff

beq:	jr	ov,finish	/* jump if r3 is zero now */

/* compare words */
even_cmp:
	ld	r2,r3		/* remember length */
	srl	r3,#1
	jr	z,no_words

	cpsir	@rr6,@rr4,r3,ne
	jr	nz,no_words

	dec	r7,#2
	dec	r5,#2		/* point to different bytes */
	ldk	r3,#2
	jr	t,odd_cmp

no_words:
	bitb	rl2,#0		/* odd length? */
	jr	z,finish

	cpsib	@rr6,@rr4,r3,eq
	jr	z,finish	/* last bytes are the same */
	jr	t,byte_diff

/* compare bytes */
odd_cmp:
	cpsirb	@rr6,@rr4,r3,ne
	jr	nz,finish

byte_diff:
	dec	r7,#1
	dec	r5,#1		/* point to different bytes */

	ldb	rl1,@rr6
	clr	r0
	ldb	rl0,@rr4
	sub	r1,r0

finish:				/* set return value */
#ifdef __STD_CALL__
	ld	r7,r1
#else
	ld	r2,r1
#endif


#else		/* above Z8001, below Z8002 */


	unsegm

#ifdef __STD_CALL__
	ld	r7,r15(#2)
	ld	r6,r15(#4)
	ld	r5,r15(#6)
#endif

/* r5  - length
 * r6  - b2
 * r7  - b1
 */

	clr	r1		/* initialize return value */
	test	r5
	jr	z,finish

	bitb	rl7,#0		/* odd destination address? */
	jr	nz,testb2
	bitb	rl6,#0		/* odd source address? */
	jr	nz,odd_cmp	/* b1 even, b2 odd */
	jr	t,even_cmp

testb2:
	bitb	rl6,#0
	jr	z,odd_cmp	/* b2 even, b1 odd */

	cpsib	@r7,@r6,r5,eq
	jr	z,beq		/* bytes are the same */
	jr	t,byte_diff

beq:	jr	ov,finish	/* jump if r3 is zero now */

/* compare words */
even_cmp:
	ld	r4,r5		/* remember length */
	srl	r5,#1
	jr	z,no_words

	cpsir	@r7,@r6,r5,ne
	jr	nz,no_words

	dec	r7,#2
	dec	r6,#2		/* point to different bytes */
	ldk	r5,#2
	jr	t,odd_cmp

no_words:
	bitb	rl4,#0		/* odd length? */
	jr	z,finish

	cpsib	@r7,@r6,r4,eq
	jr	z,finish	/* last bytes are the same */
	jr	t,byte_diff

/* compare bytes */
odd_cmp:
	cpsirb	@r7,@r6,r5,ne
	jr	nz,finish

byte_diff:
	dec	r7,#1
	dec	r6,#1		/* point to different bytes */

	ldb	rl1,@r7
	clr	r0
	ldb	rl0,@r6
	sub	r1,r0

finish:
#ifdef __STD_CALL__
	ld	r7,r1
#else
	ld	r2,r1
#endif

#endif	/* Z8002 */

	ret
	.end

/*
 * memcpy routine for Z8000
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

/* void *memcpy(void *dest, const void *src, size_t length);
 */

	name	"memcpy.S"

	.text
	even
global	_memcpy
global	memmove_entry

_memcpy:

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

memmove_entry:		/* external entry point from memmove */

	bitb	rl7,#0		/* odd destination address? */
	jr	nz,testsrc
	bitb	rl5,#0		/* odd source address? */
	jr	nz,odd_copy
	jr	t,even_copy	/* dest even, src odd */

testsrc:
	bitb	rl5,#0
	jr	z,odd_copy	/* src even, dest odd */
	ldib	@rr6,@rr4,r3
	jr	ov,finish	/* jump if r3 is zero now */

/* copy words */
even_copy:
	ld	r2,r3		/* remember length */
	srl	r3,#1
	jr	z,no_words

	ldir	@rr6,@rr4,r3

no_words:
	bitb	rl2,#0		/* odd length? */
	jr	z,finish
	ldib	@rr6,@rr4,r2	/* yes, copy last byte */
	jr	finish

/* copy bytes */
odd_copy:
	ldirb	@rr6,@rr4,r3

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

memmove_entry:		/* external entry point from memmove */

	bitb	rl7,#0		/* odd destination address? */
	jr	nz,testsrc
	bitb	rl6,#0		/* odd source address? */
	jr	nz,odd_copy
	jr	t,even_copy	/* dest even, src odd */

testsrc:
	bitb	rl6,#0
	jr	z,odd_copy	/* src even, dest odd */
	ldib	@r7,@r6,r5
	jr	ov,finish	/* jump if r5 is zero now */

/* copy words */
even_copy:
	ld	r4,r5		/* remember length */
	srl	r5,#1
	jr	z,no_words

	ldir	@r7,@r6,r5

no_words:
	bitb	rl4,#0		/* odd length? */
	jr	z,finish
	ldib	@r7,@r6,r4	/* yes, copy last byte */
	jr	finish

/* copy bytes */
odd_copy:
	ldirb	@r7,@r6,r5

finish:
#ifdef __STD_CALL__
	ld	r7,r15(#2)
#endif

#endif	/* Z8002 */

	ret
	.end

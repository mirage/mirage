/*
 * memset routine for Z8000
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

/* void *memset(void *buffer, int value, size_t length);
 */

	name	"memset.S"

	.text
	even
global	_memset

_memset:

#ifdef __Z8001__
	segm

#ifdef __STD_CALL__
	ldl	rr6,rr14(#4)
	ld	r5,rr14(#8)
	ldl	rr2,rr14(#10)
#else
	pushl	@rr14,rr6
#endif

/* rr2  - length
 * rl5  - value
 * rr6  - buffer
 */
	testl	rr2
	jr	z,finish

	ldb	rh5,rl5
	ld	r1,r5		/* r1 contains value */
	bit	r7,#0
	jr	z,not_odd

	ldb	@rr6,rl1
	inc	r7,#1
	subl	rr2,#1
	jr	z,finish

not_odd:ld	r0,r3		/* remember length */
	srl	r3,#1
	jr	z,no_words

	ldl	rr4,rr6
	ld	@rr6,r1
	inc	r7,#2
	dec	r3,#1
	jr	z,no_words

	ldir	@rr6,@rr4,r3	/* fill words */

no_words:
	bit	r0,#0		/* one byte remaining? */
	jr	z,finish

	ldb	@rr6,rl1

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
 * r6  - value
 * r7  - buffer
 */
	test	r5
	jr	z,finish

	ldb	rh6,rl6
	ld	r1,r6		/* r1 contains value */
	bit	r7,#0
	jr	z,not_odd

	ldb	@r7,rl1
	inc	r7,#1
	dec	r5,#1
	jr	z,finish

not_odd:ld	r0,r5		/* remember length */
	srl	r5,#1
	jr	z,no_words

	ld	r4,r7
	ld	@r7,r1
	inc	r7,#2
	dec	r5,#1
	jr	z,no_words

	ldir	@r7,@r4,r5	/* fill words */

no_words:
	bit	r0,#0		/* one byte remaining? */
	jr	z,finish

	ldb	@r7,rl1

finish:
#ifdef __STD_CALL__
	ld	r7,r15(#2)
#endif

#endif	/* Z8002 */

	ret
	.end

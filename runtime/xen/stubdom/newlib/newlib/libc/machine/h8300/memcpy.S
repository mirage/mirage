#include "setarch.h"

#include "defines.h"

#ifdef __H8300SX__

	.global _memcpy
_memcpy:
	stm.l	er4-er6,@-er7

	; Set up source and destination pointers for movmd.
	mov.l	er0,er6
	mov.l	er1,er5

	; See whether the copy is long enough to use the movmd.l code.
	; Although the code can handle anything longer than 6 bytes,
	; it can be more expensive than movmd.b for small moves.
	; It's better to use a higher threshold to account for this.
	;
	; Note that the exact overhead of the movmd.l checks depends on
	; the alignments of the length and pointers.  They are faster when
	; er0 & 3 == er1 & 3 == er2 & 3, faster still when these values
	; are 0.  This threshold is a compromise between the various cases.
	cmp	#16,LEN(r2)
	blo	simple

	; movmd.l only works for even addresses.  If one of the addresses
	; is odd and the other is not, fall back on a simple move.
	bld	#0,r5l
	bxor	#0,r6l
	bcs	simple

	; Make the addresses even.
	bld	#0,r5l
	bcc	word_aligned
	mov.b	@er5+,@er6+
	sub	#1,LEN(r2)

word_aligned:
	; See if copying one word would make the first operand longword
	; aligned.  Although this is only really worthwhile if it aligns
	; the second operand as well, it's no worse if doesn't, so it
	; hardly seems worth the overhead of a "band" check.
	bld	#1,r6l
	bcc	fast_copy
	mov.w	@er5+,@er6+
	sub	#2,LEN(r2)

fast_copy:
	; Set (e)r4 to the number of longwords to copy.
	mov	LEN(r2),LEN(r4)
	shlr	#2,LEN(r4)

#ifdef __NORMAL_MODE__
	; 16-bit pointers and size_ts: one movmd.l is enough.  This code
	; is never reached with r4 == 0.
	movmd.l
	and.w	#3,r2
simple:
	mov.w	r2,r4
	beq	quit
	movmd.b
quit:
	rts/l	er4-er6
#else
	; Skip the first iteration if the number of longwords is divisible
	; by 0x10000.
	mov.w	r4,r4
	beq	fast_loop_next

	; This loop copies r4 (!= 0) longwords the first time round and 65536
	; longwords on each iteration after that.
fast_loop:
	movmd.l
fast_loop_next:
	sub.w	#1,e4
	bhs	fast_loop

	; Mop up any left-over bytes.  We could just fall through to the
	; simple code after the "and" but the version below is quicker
	; and only takes 10 more bytes.
	and.w	#3,r2
	beq	quit
	mov.w	r2,r4
	movmd.b
quit:
	rts/l	er4-er6

simple:
	; Simple bytewise copy.  We need to handle all lengths, including zero.
	mov.w	r2,r4
	beq	simple_loop_next
simple_loop:
	movmd.b
simple_loop_next:
	sub.w	#1,e2
	bhs	simple_loop
	rts/l	er4-er6
#endif

#else

	.global _memcpy
_memcpy:
;	MOVP	@(2/4,r7),A0P	; dst
;	MOVP	@(4/8,r7),A1P	; src
;	MOVP	@(6/12,r7),A2P	; len

	MOVP	A0P,A3P	; keep copy of final dst
	ADDP	A2P,A0P	; point to end of dst
	CMPP	A0P,A3P	; see if anything to do
	beq	quit

	ADDP	A2P,A1P	; point to end of src

	; lets see if we can do this in words
	or	A0L,A2L	; or in the dst address
	or	A3L,A2L	; or the length 
	or	A1L,A2L	; or the src address
	btst	#0,A2L	; see if the lsb is zero
	bne	byteloop

wordloop:
#ifdef __NORMAL_MODE__
	sub	#2,A1P
#else
	subs	#2,A1P		; point to word
#endif
	mov.w	@A1P,A2		; get word
	mov.w	A2,@-A0P	; save word
	CMPP	A0P,A3P		; at the front again ?
	bne 	wordloop
	rts

byteloop:
#ifdef __NORMAL_MODE__
	sub	#1,A1P
#else
	subs	#1,A1P		; point to byte
#endif
	mov.b	@A1P,A2L	; get byte
	mov.b	A2L,@-A0P	; save byte
	CMPP	A0P,A3P 	; at the front again ?
	bne 	byteloop

	; return with A0 pointing to dst
quit:	rts

#endif

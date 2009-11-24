#include "setarch.h"

#include "defines.h"

#if defined (__H8300SX__)

	.global	_memset
_memset:
	; Use er3 is a temporary since er0 must remain unchanged on exit.
	mov.l	er0,er3

	; Fill er1 with the byte to copy.
	mov.b	r1l,r1h
	mov.w	r1,e1

	; Account for any excess bytes and words that will be copied after
	; the main loop.  r2 >= 0 if there is a longword to copy.
	sub	#4,LEN(r2)
	blo	longs_done

	; Copy one byte if doing so will make er3 word-aligned.
	; This isn't needed for correctness but it makes the main loop
	; slightly faster.
	bld	#0,r3l
	bcc	word_aligned
	mov.b	r1l,@er3+
	sub	#1,LEN(r2)
	blo	longs_done

word_aligned:
	; Likewise one word for longword alignment.
	bld	#1,r3l
	bcc	long_copy
	mov.w	r1,@er3+
	sub	#2,LEN(r2)
	blo	longs_done

long_copy:
	; Copy longwords.
	mov.l	er1,@er3+
	sub	#4,LEN(r2)
	bhs	long_copy

longs_done:
	; At this point, we need to copy r2 & 3 bytes.  Copy a word
	; if necessary.
	bld	#1,r2l
	bcc	words_done
	mov.w	r1,@er3+

words_done:
	; Copy a byte.
	bld	#0,r2l
	bcc	bytes_done
	mov.b	r1l,@er3+

bytes_done:
	rts

#else

; A0P pointer to cursor
; A1P thing to copy
	.global	_memset

_memset:

;	MOVP	@(2/4,r7),A2P	; dst
;	MOVP	@(4/8,r7),A1	; src thing
;	MOVP	@(6/12,r7),A3P	; len

	MOVP	A2P,A2P
	beq	quit

	; A3 points to the end of the area
	MOVP	A0P,A3P
	ADDP	A2P,A3P

	; see if we can do it in words
	; by oring in the start of the buffer to the end address

	or	A0L,A2L
	btst	#0,A2L
	bne	byteloop
	
	; we can do it a word at a time

	mov.b	A1L,A1H	

wordloop:
	mov.w	A1,@-A3P
	CMPP	A3P,A0P
	bne	wordloop
quit:	rts	

byteloop:
	mov.b	A1L,@-A3P
	CMPP	A3P,A0P
	bne	byteloop
	rts

#endif

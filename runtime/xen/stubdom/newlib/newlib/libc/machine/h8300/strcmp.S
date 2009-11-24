#include "setarch.h"

#include "defines.h"

#if defined (__H8300SX__)
	.global _strcmp
_strcmp:
	mov.l	er0,er2
loop:
	mov.b	@er2+,r0l
	beq	eos
	sub.b	@er1+,r0l
	beq	loop
	exts.l	#2,er0
	rts
eos:
	sub.b	@er1,r0l
	exts.l	#2,er0
	rts
#else
	.section .text
	.align 2
	.global _strcmp
_strcmp:
	MOVP	A0P,A2P
	MOVP	A1P,A3P
.L5:
	mov.b	@A2P+,A1L
	beq	.L3
	mov.b	@A3P+,A0L
	cmp.b	A0L,A1L
	beq	.L5
#ifdef __NORMAL_MODE__
	sub	#1,A3P
#else
	subs	#1,A3P
#endif
.L3:
	mov.b	@(-1,A2P),A0L
	mov.b	@A3P,A1L
	sub.b	A1L,A0L
	; We have to sign extend the result to 32bits just in case
	; we are using 32bit integers.
#ifdef __H8300H__
	exts.w	r0
	exts.l	er0
#else
#ifdef __H8300S__
	exts.w	r0
	exts.l	er0
#else
	bld	#7,r0l
	subx	r0h,r0h
	subx	r1l,r1l
	subx	r1h,r1h
#endif
#endif
	rts
	.end
#endif

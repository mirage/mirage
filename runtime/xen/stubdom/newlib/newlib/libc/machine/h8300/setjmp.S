#include "setarch.h"

	.file "setjmp.S"

	.section .text
	.align	2
	.global	_setjmp
_setjmp:
#if defined(__H8300SX__)
	mov.l	er7,@er0+
	mov.l	er6,@er0+
	mov.l	er5,@er0+
	mov.l	er4,@er0+
	mov.l	@sp,@er0
	sub.l   er0,er0
#elif defined(__H8300H__) || defined(__H8300S__)
	mov.l	er7,@er0
	mov.l	er6,@(4,er0)
	mov.l	er5,@(8,er0)
	mov.l	er4,@(12,er0)
	mov.l	@sp,er1
	mov.l	er1,@(16,er0)
	sub.l   er0,er0
#else
	mov.w	r7,@r0
	mov.w	r6,@(2,r0)
	mov.w	r5,@(4,r0)
	mov.w	r4,@(6,r0)
	mov.w   @sp,r1
	mov.w	r1,@(8,r0)
	sub.w	r0,r0
#endif
	rts

	.global	_longjmp
_longjmp:
#if defined(__H8300H__) || defined (__H8300S__) || defined (__H8300SX__)
	mov.l	@er0+,er7
	mov.l	@er0+,er6
	mov.l	@er0+,er5
	mov.l	@er0+,er4
#if defined(__H8300SX__)
	mov.l	@er0,@sp
#else
	mov.l	@er0,er2
	mov.l	er2,@sp
#endif
#if (__INT_MAX__ <= 32767)
	mov.w	r1,r0
#else
	mov.l   er1,er0
#endif
	bne	.L1
	sub	er0,er0
	adds	#1,er0
#else
	mov.w	@r0+,r7
	mov.w	@r0+,r6
	mov.w	@r0+,r5
	mov.w	@r0+,r4
	mov.w	@r0,r2
	mov.w	r2,@sp
	mov.w	r1,r0
	bne	.L1
	mov.w	#1,r0
#endif
.L1:
	rts

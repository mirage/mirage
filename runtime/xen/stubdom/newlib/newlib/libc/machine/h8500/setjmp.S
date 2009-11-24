!
	.file	"setjmp.S"
	.section .text

	.global	_setjmp
_setjmp:
	mov.w	r7,@r0+
	mov.w	r6,@r0+
	mov.w	r5,@r0+
	mov.w	@sp,r1
	mov.w	r1,@r0
	clr.w	r0
	rts

	.global	_longjmp
_longjmp:
	mov.w	@r0+,r7
	mov.w	@r0+,r6
	mov.w	@r0+,r5
	mov.w	@r0,r2
	mov.w	r2,@sp
	mov.w	r1,r0
	tst.w	r0
	bne	.L1
	mov.w	#1,r0
.L1:
	rts

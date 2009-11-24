	.file "setjmp.S"

	.section .text
	.align 1
	.global _setjmp
_setjmp:
	mov d0,a0
	movx d2,(0,a0)
	movx d3,(4,a0)
	mov a1,(8,a0)
	mov a2,(12,a0)
	mov a3,(16,a0)
	movx (0,a3),d0
	movx d0,(20,a0)
	sub d0,d0
	rts

	.global _longjmp
_longjmp:
	mov d0,a0
	movx (0,a0),d2
	movx (4,a0),d3
	mov (8,a0),a1
	mov (12,a0),a2
	mov (16,a0),a3
	movx (20,a0),d0
	movx d0,(0,a3)
	cmp 0,d1
	bne L1
	mov 1,d1
L1:
	mov d1,d0
	rts

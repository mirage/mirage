;;  xstormy16
;;   Copyright (C) 2001 by  Red Hat, Incorporated. All rights reserved.
;; 
;; Permission to use, copy, modify, and distribute this software
;; is freely granted, provided that this notice is preserved.
;; 
	.file "setjmp.S"

	.section .text
	.align 1
	.global setjmp
	.type setjmp,@function
setjmp:
	mov r0,r10
	mov (r2++),r0
	mov r0,r11
	mov (r2++),r0
	mov r0,r12
	mov (r2++),r0
	mov r0,r13
	mov (r2++),r0
	pop r0			; PC high word
	pop r1			; PC low word
	mov (r2++), r0
	mov (r2++), r1
	mov r3,sp
	mov (r2++),r3
	mov.w r2,#0
	mov r8, r0
	mov r9, r1
	jmp r8, r9
	.size setjmp,.-setjmp

	.global longjmp
	.type longjmp,@function
longjmp:
	mov r0,(r2++)
	mov r10,r0
	mov r0,(r2++)
	mov r11,r0
	mov r0,(r2++)
	mov r12,r0
	mov r0,(r2++)
	mov r13,r0
	mov r0,(r2++)
	mov r8, r0
	mov r1,(r2++)
	mov r9, r1
	mov r4,(r2++)
	mov sp,r4
;; status arg (r3) to longjmp is return value
;; if it's zero, return 1
	bnz r3, #0, 0f
	mov.w r3,#1
0:	mov r2, r3
	jmp r8,r9
	.size longjmp,.-longjmp

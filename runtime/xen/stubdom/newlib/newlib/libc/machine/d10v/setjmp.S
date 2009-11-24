; setjmp/longjmp for D10V.  The jmpbuf looks like this:
;
; Register		jmpbuf offset
; R6			0x00
; R7			0x02
; R8			0x04
; R9			0x06
; R10			0x08
; R11			0x0a
; R13 (return address)	0x0c
; R15 (SP)		0x0E

	.text
	.globl	setjmp
	.type	setjmp,@function
	.stabs	"setjmp.S",100,0,0,setjmp
	.stabs	"int:t(0,1)=r(0,1);-65536;65535;",128,0,0,0
	.stabs	"setjmp:F(0,1)",36,0,1,setjmp

setjmp:
; Address of jmpbuf is passed in R0.  Save the appropriate registers.
	st2w	r6, @r0+
	st2w	r8, @r0+
	st2w	r10, @r0+
	st	r13, @r0+
	st	r15, @r0+

; Return 0 to caller
	ldi	r0, 0
	jmp	r13
.Lsetjmp:
	.size	setjmp,.Lsetjmp-setjmp
	.stabs	"",36,0,0,.Lsetjmp-setjmp

	.globl	longjmp
	.type	longjmp,@function
	.stabs	"longjmp:F(0,1)",36,0,1,longjmp
longjmp:
; Address of jmpbuf is in R0.  Restore the registers.
	ld2w	r6, @r0+
	ld2w	r8, @r0+
	ld2w	r10, @r0+
	ld	r13, @r0+
	ld	r15, @r0+

; Value to return to caller is in R1.  If caller attemped to return 0,
; return 1 instead.

	mv	r0, r1
	cmpeqi	r0, 0
	exef0t || ldi r0,1
	jmp	r13
.Llongjmp:
	.size	longjmp,.Llongjmp-longjmp
	.stabs	"",36,0,0,.Llongjmp-longjmp

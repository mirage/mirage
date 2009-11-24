# setjmp/longjmp for m32r.  The jmpbuf looks like this:
#
# Register	jmpbuf offset
# reserved	0x00	
# R8		0x04
# R9		0x08
# R10		0x0c
# R11		0x10
# R12		0x14
# R13 (FP)	0x18
# R14 (LR)	0x1c
# R15 (SP)	0x20
# reserved	0x24

	.text
	.global	setjmp
setjmp:
	;addi	r0, #-4		; commented out as first word is reserved
	;st	r1, @+r0
	st	r8, @+r0
	st	r9, @+r0
	st	r10, @+r0
	st	r11, @+r0
	st	r12, @+r0
	st	r13, @+r0
	st	r14, @+r0
	st	r15, @+r0

# Return 0 to caller.
	ldi	r0, #0
	jmp	lr

	.global	longjmp
longjmp:
	addi	r0, #4		; first word is reserved
	;ld	r1, @r0+
	ld	r8, @r0+
	ld	r9, @r0+
	ld	r10, @r0+
	ld	r11, @r0+
	ld	r12, @r0+
	ld	r13, @r0+
	ld	r2, @r0+	; return address
	ld	r15, @r0+

# If caller attempted to return 0, return 1 instead.

	mv	r0, r1
	bnez	r0, .Lnonzero
	ldi	r0, #1
.Lnonzero:
	jmp	r2

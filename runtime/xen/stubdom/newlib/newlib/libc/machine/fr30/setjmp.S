# setjmp/longjmp for FR30.  The jmpbuf looks like this:
#	
# Register	jmpbuf offset
# R8		0x00
# R9		0x04
# R10		0x08
# R11		0x0c
# R12		0x10
# R13		0x14
# R14 (FP)	0x18
# R15 (SP)	0x1c
# RP            0x20
	
.macro save reg
	st	\reg,@r4
	add	#4,r4
.endm
	
.macro restore reg
	ld	@r4,\reg
	add	#4,r4
.endm


	.text
	.global	setjmp
setjmp:
	save	r8
	save	r9
	save	r10
	save	r11
	save	r12
	save	r13
	save	r14
	save	r15
	mov	RP,r5
	st	r5,@r4

# Return 0 to caller.
	ldi:8	#0,r4
	ret

	.global	longjmp
longjmp:
	restore	r8
	restore	r9
	restore	r10
	restore	r11
	restore	r12
	restore	r13
	restore	r14
	restore	r15
	ld	@r4,r4
	mov	r4,RP

# If caller attempted to return 0, return 1 instead.

	mov	r5,r4
	or	r4,r4
	bne	1f
	ldi:8	#1,r4
    1:
	ret
	
# setjmp/longjmp for mt.
# 
# The jmpbuf looks like this:
#	
# Register	jmpbuf offset
# R0		---		--
# R1		0x4		 4
# R2		0x8		 8
# R3		0xc		12
# R4		0x10		16
# R5		0x14		20
# R6		0x18		24
# R7		0x1c		28
# R8		0x20		32
# R9		----		--
# R10		----		--
# R11		0x2c		44
# R12		0x30		48
# R13		0x34		52
# R14		0x38		56
# R15		0x3c		60
#
# R1 contains the pointer to jmpbuf
	.text
	.global	setjmp
	.type	setjmp ,@function
setjmp:

	stw	r1, r1, #4
	or	r0, r0, r0
	stw	r2, r1, #8
	or	r0, r0, r0
	stw	r3, r1, #12
	or	r0, r0, r0
	stw	r4, r1, #16
	or	r0, r0, r0
	stw	r5, r1, #20
	or	r0, r0, r0
	stw	r6, r1, #24
	or	r0, r0, r0
	stw	r7, r1, #28
	or	r0, r0, r0
	stw	r8, r1, #32
	or	r0, r0, r0
	stw	r11, r1, #44
	or	r0, r0, r0
	stw	r12, r1, #48
	or	r0, r0, r0
	stw	r13, r1, #52
	or	r0, r0, r0
	stw	r14, r1, #56
	or	r0, r0, r0
	stw	r15, r1, #60

	jal	r0, r14
	addi	r11, r0, #0
.Lend1:
	.size	setjmp,.Lend1-setjmp

	.global	longjmp
	.type	longjmp,@function
longjmp:
	or	r9, r1, r1
	or	r11, r2, r2
	ldw	r1, r1, #4
	or	r0, r0, r0
	ldw	r2, r1, #8
	or	r0, r0, r0
	ldw	r3, r1, #12
	or	r0, r0, r0
	ldw	r4, r1, #16
	or	r0, r0, r0
	ldw	r5, r1, #20
	or	r0, r0, r0
	ldw	r6, r1, #24
	or	r0, r0, r0
	ldw	r7, r1, #28
	or	r0, r0, r0
	ldw	r8, r1, #32
	or	r0, r0, r0


	ldw	r12, r1, #48
	or	r0, r0, r0
	ldw	r13, r1, #52
	or	r0, r0, r0
	ldw	r14, r1, #56
	or	r0, r0, r0
	ldw	r15, r1, #60

	brne	r0, r11, .L01
	or	r0, r0, r0

	addi	r11, r0, #1
.L01:
	jal	r0, r14
	or	r0, r0, r0
.Lend2:
	.size	longjmp,.Lend2-longjmp2

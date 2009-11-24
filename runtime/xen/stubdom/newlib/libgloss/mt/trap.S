;;
;;  The errno will be in r5 if r11 is -1.
;;
	.text
	.global __trap0
__trap0:
	;; non-leaf function so need to create stack frame to
	;; store ra and fp
	subi	sp, sp, #16
	stw	ra, sp, #12
	or	r0, r0, r0		;; nop
	stw	fp, sp, #8
	or	fp, sp, sp
	stw	r5, sp, #4
	or	r0, r0, r0		;; nop
	stw	r6, sp, #0
	addi	r6, r0, #$-1
	si	r14
	or	r0, r0, r0		;; nop
	brne	r11, r6, .L0
	ldui	r6, #%hi16(errno)
	addui	r6, r6, #%lo16(errno)
	stw	r5, r6, #0
	or	r0, r0, r0		;; nop
.L0:
	ldw	r6, sp, #0
	or	r0, r0, r0		;; nop
	ldw	r5, sp, #4
	or	r0, r0, r0		;; nop
	ldw	ra, sp, #12
	or	r0, r0, r0		;; nop
	ldw	fp, sp, #8
	jal	r0, r14
	addi	sp, sp, #16

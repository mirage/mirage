; crt0_2.s - Startup code for the mrisc1. This code initializes the C
;              run-time model.
;
; Copyright 2001, 2002, 2003, 2004 Free Software Foundation, Inc.
;
;  The authors hereby grant permission to use, copy, modify, distribute,
;  and license this software and its documentation for any purpose, provided
;  that existing copyright notices are retained in all copies and that this
;  notice is included verbatim in any distributions. No written agreement,
;  license, or royalty fee is required for any of the authorized uses.
;  Modifications to this software may be copyrighted by their authors
;  and need not follow the licensing terms described here, provided that
;  the new terms are clearly indicated on the first page of each file where
;  they apply.
;

	; Create a label for the start of the eh_frame section.
	.section .eh_frame
__eh_frame_begin:

	.text
	.global	_start
_start:
	;; Initialize the stack pointer
	ldui	sp, #%hi16(__stack)
	addui	sp, sp, #%lo16(__stack)
	or	fp, sp, sp
	;; Zero the bss space
	ldui	r9, #%hi16(__bss_start)
	addui	r9, r9, #%lo16(__bss_start)
	ldui	r10, #%hi16(__bss_end)
	addui	r10, r10, #%lo16(__bss_end)
	or	r0, r0, r0
	brle	r10, r9, .Lnext1
	or	r0, r0, r0
.Lcpy0:	
	stw	r0, r9, #0
	addi	r9, r9, #4
	or	r0, r0, r0	; nop
	brle	r9, r10, .Lcpy0
	or	r0, r0, r0	; nop

.Lnext1:
	;; Copy data from ROM to Frame Buffer (on-chip memory)
	ldui	r9, #%hi16(_fbdata_start)
	ori	r9, r9, #%lo16(_fbdata_start)
	ldui	r10, #%hi16(_fbdata_end)
	ori	r10, r10, #%lo16(_fbdata_end)
	ldui	r11, #%hi16(_fbdata_vma)
	brle	r10, r9, .Lnext2
	ori	r11, r11, #%lo16(_fbdata_vma)
.Lcpy1:
	ldw	r5, r9, #$0
	addi	r9, r9, #$4
	stw	r5, r11, #$0
	brlt	r9, r10, .Lcpy1
	addi	r11, r11, #$4

.Lnext2:
	;; Zero the frame buffer bss section
        ldui    r9, #%hi16(_fbbss_start)
        ori     r9, r9, #%lo16(_fbbss_start)
        ldui    r10, #%hi16(_fbbss_end)
        ori     r10, r10, #%lo16(_fbbss_end)
	or	r0, r0, r0
	brle	r10, r9, .Lnext3
	or	r0, r0, r0
.Lcpy2:
        stw     r0, r9, #$0
        addi    r9, r9, #$4
        or      r0, r0, r0
        brle    r9, r10, .Lcpy2
        or      r0, r0, r0

.Lnext3:
	;; Call global and static constructors
	ldui	r10, #%hi16(_init)
	ori	r10, r10, #%lo16(_init)
	or	r0, r0, r0	; nop
	jal	r14, r10
	or	r0, r0, r0	; nop

	;; Call main
	ldui	r10, #%hi16(main)
	ori	r10, r10, #%lo16(main)
	or	r0, r0, r0	; nop
	jal	r14, r10
	or	r0, r0, r0	; nop

	;; DJK - Added 12Nov01. Pass main's return value to exit.
	or	r1, r11, r0

	;; Jump to exit
	ldui	r10, #%hi16(exit)
	ori	r10, r10, #%lo16(exit)
	or	r0, r0, r0	; nop
	jal	r14, r10
	or	r0, r0, r0	; nop

	;; Exit does not return, however, this code is to catch an
	;;   error if it does. Set the processor into sleep mode.
	ori	r1, r0, #$1
	stw	r1, r0, #%lo16(_DEBUG_HALT_REG)
	or	r0, r0, r0
	or	r0, r0, r0
	or	r0, r0, r0
	or	r0, r0, r0
	or	r0, r0, r0
.Lend:
	jmp .Lend
	or	r0, r0, r0

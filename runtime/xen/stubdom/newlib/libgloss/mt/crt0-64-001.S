; crt0_2.s - Startup code for the mrisc1. This code initializes the C
;              run-time model.
;
; 12Nov01 (DJK) - The return code from main was not being passed to exit().
;                   Now it is passed as a parameter in R1.
;
; 10Sep01 (DJK) - The function exit() does not return. However, in the
;                   the case of device error (if the halt bit does not
;                   function properly, for instance), then a catch loop
;                   has been added.
;
;
; Copyright 2001, 2002, 2003, 2004 Morpho Technologies, Inc.
;

	; Create a label for the start of the eh_frame section.
	.section .eh_frame
__eh_frame_begin:

	.equ	HALT_REG, 0x300
	.section .text
	.global	_start
_start:
	;; Initialize the stack pointer
	ldui	sp, #%hi16(__stack)
	addui	sp, sp, #%lo16(__stack)
	or	fp, sp, sp

	;; Copy data from ROM to Frame Buffer (on-chip memory)
	ldui	r9, #%hi16(_fbdata_start)
	ori	r9, r9, #%lo16(_fbdata_start)
	ldui	r10, #%hi16(_fbdata_end)
	ori	r10, r10, #%lo16(_fbdata_end)
	ldui	r11, #%hi16(__FRAME_BUFFER_START)
	brle	r10, r9, .Lnext1
	ori	r11, r11, #%lo16(__FRAME_BUFFER_START)
.Lcpy0:
	ldw	r5, r9, #$0
	addi	r9, r9, #$4
	stw	r5, r11, #$0
	brlt	r9, r10, .Lcpy0
	addi	r11, r11, #$4

.Lnext1:
	;; Copy data from ROM to External Memory (off-chip memory)
	ldui	r9, #%hi16(_extdata_start)
	ori	r9, r9, #%lo16(_extdata_start)
	ldui	r10, #%hi16(_extdata_end)
	ori	r10, r10, #%lo16(_extdata_end)
	ldui	r11, #%hi16(__EXTERNAL_MEMORY_START)
	brle	r10, r9, .Lnext2
	ori	r11, r11, #%lo16(__EXTERNAL_MEMORY_START)
.Lcpy1:
	ldw	r5, r9, #$0
	addi	r9, r9, #$4
	stw	r5, r11, #$0
	brlt	r9, r10, .Lcpy1
	addi	r11, r11, #$4


.Lnext2:
	;; Zero the bss space
	ldui	r9, #%hi16(__bss_start)
	addui	r9, r9, #%lo16(__bss_start)
	ldui	r10, #%hi16(__bss_end)
	addui	r10, r10, #%lo16(__bss_end)
	or	r0, r0, r0
	brle	r10, r9, .Lnext3
	or	r0, r0, r0
.Lcpy2:	
	stw	r0, r9, #0
	addi	r9, r9, #4
	or	r0, r0, r0	; nop
	brle	r9, r10, .Lcpy2
	or	r0, r0, r0	; nop

.Lnext3:
	;; Zero the external memory bss section
        ldui    r9, #%hi16(_extbss_start)
        ori     r9, r9, #%lo16(_extbss_start)
        ldui    r10, #%hi16(_extbss_end)
        ori     r10, r10, #%lo16(_extbss_end)
	or	r0, r0, r0
	brle	r10, r9, .Lnext4
	or	r0, r0, r0
.Lcpy3:
        stw     r0, r9, #$0
        addi    r9, r9, #$4
        or      r0, r0, r0
        brle    r9, r10, .Lcpy3
        or      r0, r0, r0

.Lnext4:
	;; Call global and static constructors
	ldui	r10, #%hi16(_init)
	ori	r10, r10, #%lo16(_init)
	or	r0, r0, r0	; nop
	jal	r14, r10
	or	r0, r0, r0	; nop

	;;  Setup destructors to be called from exit.
	;;  (Just in case main never returns....)
	ldui	r10, #%hi16(atexit)
	ori	r10, r10, #%lo16(atexit)
	ldui	r1, #%hi16(_fini)
	ori	r1, r1, #%lo16(_fini)
	or	r0, r0, r0	; nop
	jal	r14, r10
	or	r0, r0, r0	; nop

	;;  Initialise argc, argv and envp to empty
	addi	r1, r0, #0
	addi	r2, r0, #0
	addi	r3, r0, #0

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
	stw	r1, r0, #HALT_REG
	or	r0, r0, r0
	or	r0, r0, r0
	or	r0, r0, r0
	or	r0, r0, r0
	or	r0, r0, r0
.Lend:
	jmp .Lend
	or	r0, r0, r0

# Startup Code for the Morpho mt

# Create a label for the start of the eh_frame section.
	.section .eh_frame
__eh_frame_begin:

	.section .text
	.global	_start
_start:
	
	;; Initialise the stack pointer
	ldui	sp, #%hi16(__stack)
	addui	sp, sp, #%lo16(__stack)
	or	fp, sp, sp

	;; Zero the data space
	ldui	r9, #%hi16(_edata)
	addui	r9, r9, #%lo16(_edata)
	ldui	r10, #%hi16(_end)
	addui	r10, r10, #%lo16(_end)
	addi	r5,  r0, #0

.L0:	
	stw	r5, r9, #0
	addi	r9, r9, #4
	or	r0, r0, r0	; nop
	brle	r9, r10, .L0
	or	r0, r0, r0	; nop

	;; Call global and static constructors
	ldui	r10, #%hi16(_init)
	addui	r10, r10, #%lo16(_init)
	or	r0, r0, r0	; nop
	jal	r14, r10
	or	r0, r0, r0	; nop
	;;  Setup destructors to be called from exit.
	;;  (Just in case main never returns....)
	ldui	r10, #%hi16(atexit)
	addui	r10, r10, #%lo16(atexit)
	ldui	r1, #%hi16(_fini)
	addui	r1, r1, #%lo16(_fini)
	or	r0, r0, r0	; nop
	jal	r14, r10
	or	r0, r0, r0	; nop

	;;  Initialise argc, argv and envp to empty
	addi	r1, r0, #0
	addi	r2, r0, #0
	addi	r3, r0, #0

	;; Call main
	ldui	r10, #%hi16(main)
	addui	r10, r10, #%lo16(main)
	or	r0, r0, r0	; nop
	jal	r14, r10
	or	r0, r0, r0	; nop

	;; Jump to exit
	ldui	r10, #%hi16(exit)
	addui	r10, r10, #%lo16(exit)
	or	r0, r0, r0	; nop
	jal	r14, r10
	or	r0, r0, r0	; nop

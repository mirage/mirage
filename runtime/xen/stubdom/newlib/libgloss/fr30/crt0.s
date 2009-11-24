# FR30 startup code

	.section .text
	.global	_start
_start:
	
	;; Initialise the stack pointer
	ldi:32	__stack, r0
	mov	r0, sp
	mov	r0, fp

	;; Zero the data space
	ldi:32	#_edata, r0
	ldi:32	#_end,   r1
	ldi:8	#0,	 r2
.L0:	
	st	r2, @r0
	add	#4, r0
	cmp	r1, r0
	blt	.L0

	;; Call global and static constructors
	ldi:32	_init, r0
	call	@r0
	
	;;  Setup destrcutors to be called from exit.
	;;  (Just in case main never returns....)
	ldi:32	atexit, r0
	ldi:32	_fini, r4
	call	@r0
	
	;;  Initialise argc, argv and envp to empty
	ldi:8	#0, r4
	ldi:8	#0, r5
	ldi:8	#0, r6

	;; Call main
	ldi:32	main, r0
	call	@r0

	;; Jump to exit
	ldi:32	exit, r0
	call	@r0

	;; Should never reach here
	int	#9

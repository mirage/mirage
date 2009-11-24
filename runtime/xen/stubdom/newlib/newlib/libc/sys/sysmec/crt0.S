#ifdef __mn10300__
	.section .text
	.global	_start
_start:
	mov _stack-8,a0		# Load up the stack pointer
	mov a0,sp

	mov _edata,a0		# Get the start/end of bss
	mov _end,a1

	cmp a0,a1		# If no bss, then do nothing
	beq .L0

	clr d0			# clear d0

.L1:
	movbu d0,(a0)		# Clear a byte and bump pointer
	inc a0
	cmp a0,a1
	bne .L1

.L0:
	call ___main,[],0	# Call __main to run ctors/dtors
	clr d0
	clr d1
	mov d0,(4,sp)
	call _main,[],0		# Call main program
	call _exit,[],0		# All done, no need to return or
				# deallocate our stack.

	.section ._stack
_stack:	.long 	1
#else
	.section .text
	.global	_start
_start:
	mov _stack-4,a3		# Load up the stack pointer and allocate
				# our current frame.

	mov _edata,a0		# Get the start/end of bss
	mov _end,a1

	cmp a0,a1		# If no bss, then do nothing
	beqx .L0

	sub d0,d0		# clear d0

.L1:
	movb d0,(a0)		# Clear a byte and bump pointer
	add 1,a0
	cmp a0,a1
	bnex .L1

.L0:
	jsr ___main
	sub d0,d0
	mov d0,d1
	mov d0,(a3)
	jsr _main		# Call main program
	jmp _exit		# All done, no need to return or
				# deallocate our stack.

	.section ._stack
_stack:	.long 	1
#endif

##==============================================================================
##
##	crt0.S
##
##	MN10200 startup code
##
##==============================================================================
##
## Copyright (c) 1995, 1996, 1997, 1998 Cygnus Solutions
## 
## The authors hereby grant permission to use, copy, modify, distribute,
## and license this software and its documentation for any purpose, provided
## that existing copyright notices are retained in all copies and that this
## notice is included verbatim in any distributions. No written agreement,
## license, or royalty fee is required for any of the authorized uses.
## Modifications to this software may be copyrighted by their authors
## and need not follow the licensing terms described here, provided that
## the new terms are clearly indicated on the first page of each file where
## they apply.
##
	
##------------------------------------------------------------------------------
	
	.file	"crt0.S"

##------------------------------------------------------------------------------
## Startup code
	.section .text
	.global	_start
_start:
	mov _stack,a3		# Load up the stack pointer and allocate
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

	.section .stack
_stack:	.long 	1

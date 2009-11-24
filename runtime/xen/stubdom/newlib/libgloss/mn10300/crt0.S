##==============================================================================
##
##	crt0.S
##
##	MN10300 startup code
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

	.section .stack
_stack:	.long 	1

##==============================================================================
##
##	crt0.S
##
##	IQ2000 startup code
##
##==============================================================================
##
## Copyright (c) 2000, Cygnus Solutions, A Red Hat Company
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
	lui %29,%hi(__stack)
	ori %29,%29,%lo(__stack)

	lui %24,%hi(_edata)	# get start of bss
	ori %24,%24,%lo(_edata)

	lui %25,%hi(_end)	# get end of bss
	ori %25,%25,%lo(_end)

	beq	%24,%25,.L0	# check if end and start are the same
				# do nothing if no bss
	
.L1:
	sb %0,0(%24)		#  clear a byte and bump pointer
	addi %24,%24,1
	bne %24,%25,.L1
	nop
	
.L0:
	jal  _main		# call _main to run ctors/dtors
	nop
	xor %4,%4,%4
	jal main		# call main program
	xor %5,%5,%5
	jal exit		# all done, no need to return or
	or %4,%0,%2		# exit with main's return value

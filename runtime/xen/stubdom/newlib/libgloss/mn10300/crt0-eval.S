##==============================================================================
##
##	crt0-eval.S
##
##	MN10300 Series Evaluation Board C startup code
##
##==============================================================================
######COPYRIGHTBEGIN####
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
######COPYRIGHTEND####
	
##------------------------------------------------------------------------------
	
	.file	"crt0-eval.S"

##------------------------------------------------------------------------------
## Startup code
			
	.equ	DRAM_TOP,0x48100000

	.text

	.globl	__start
__start:
	# Set up stack.  Leave 4K at top for use by Cygmon.

	mov	DRAM_TOP - 0x1000,a0
	sub	8,a0
	mov	a0,sp

	# Clear BSS

	mov	__bss_start,a0
	mov	_end,a1

	cmp	a0,a1
	beq	8f
	clr	d0
1:	
	movbu	d0,(a0)
	inc	a0
	cmp	a0,a1
	bne	1b	
8:	
	# Call constructors

	.extern	___main
	call	___main,[],0

	# Call main
	clr	d0
	clr	d1
	mov	d0,(4,sp)

9:	
 	or	0x0800,psw	# Enable interrupts
	
	.extern	_main
	call	_main,[],0

	.extern	__exit
	call	__exit,[],0

#	bra	9b		# Loop if we return

	
			
##------------------------------------------------------------------------------		
## end of crt0-eval.S


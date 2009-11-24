
	.globl	_exit
_exit:	
	movl	$1, %eax
	lcall	$7,$0


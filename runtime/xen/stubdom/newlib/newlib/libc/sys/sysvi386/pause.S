	.globl	_pause
_pause:	
	movl	$0x1d, %eax
	lcall	$7,$0
	jb	_cerror
	ret

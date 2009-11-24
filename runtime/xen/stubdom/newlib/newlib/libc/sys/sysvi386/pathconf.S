	.globl	pathconf
pathconf:
	movl	$0x2e28, %eax
	lcall	$7,$0
	jb	_cerror
	ret

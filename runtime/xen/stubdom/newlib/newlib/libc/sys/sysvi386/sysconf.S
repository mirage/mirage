	.globl	sysconf
sysconf:
	movl	$0x2d28, %eax
	lcall	$7,$0
	jb	_cerror
	ret

	.globl	_time
	.globl	time
_time:
time:
	movl	$0xd, %eax
	lcall	$7,$0
	jb	_cerror
	ret

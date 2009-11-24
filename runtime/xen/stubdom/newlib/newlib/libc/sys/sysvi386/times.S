	.globl	_times
	.globl	times
_times:
times:
	movl	$0x2b, %eax
	lcall	$7,$0
	jb	_cerror
	ret

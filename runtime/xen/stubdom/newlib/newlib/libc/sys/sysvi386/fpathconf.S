	.globl	fpathconf
fpathconf:
	movl	$0x2f28, %eax
	lcall	$7,$0
	jb	_cerror
	ret

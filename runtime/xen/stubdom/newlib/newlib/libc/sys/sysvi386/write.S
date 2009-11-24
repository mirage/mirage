	.globl	_write
	.globl	write
_write:
write:
	movl	$4, %eax
	lcall	$7,$0
	jb	_cerror
	ret

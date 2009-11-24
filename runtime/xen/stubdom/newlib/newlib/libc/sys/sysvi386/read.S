	.globl	_read
	.globl	read
_read:
read:
	movl	$3, %eax
	lcall	$7,$0
	jb	_cerror
	ret

	.globl	_getgid
	.globl	getgid
_getgid:
getgid:
	movl	$0x2f, %eax
	lcall	$7,$0
	jb	_cerror
	ret

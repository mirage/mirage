	.globl	_getgroups
	.globl	getgroups
_getgroups:
getgroups:
	movl	$0x2b28, %eax
	lcall	$7,$0
	jb	_cerror
	ret

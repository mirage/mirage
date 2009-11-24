
	.globl	_getpid
	.globl	getpid
_getpid:
getpid:
	movl	$0x14, %eax
	lcall	$7,$0
	jb	_cerror
	ret

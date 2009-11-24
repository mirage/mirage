	.globl	_getuid
	.globl	getuid
_getuid:
getuid:
	movl	$0x18, %eax
	lcall	$7,$0
	jb	_cerror
	ret

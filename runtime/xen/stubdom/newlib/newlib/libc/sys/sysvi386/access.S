	.globl	_access
	.globl	access
access:
_access:
	movl	$0x21, %eax
	lcall	$7, $0
	jb	_cerror
	ret

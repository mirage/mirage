	.globl	_getdents
_getdents:
	movl	$0x51, %eax
	lcall	$7,$0
	jb	_cerror
	ret

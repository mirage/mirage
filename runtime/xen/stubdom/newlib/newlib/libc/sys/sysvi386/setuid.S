	.globl	_setuid
	.globl	setuid
_setuid:
setuid:
	movl	$0x17, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax,%eax
	ret

	.globl	_setgid
	.globl	setgid
_setgid:
setgid:
	movl	$0x2e, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax,%eax
	ret

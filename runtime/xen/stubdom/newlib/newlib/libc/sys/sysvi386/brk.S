
	.globl	_brk
_brk:
	movl	$0x11, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax,%eax
	ret

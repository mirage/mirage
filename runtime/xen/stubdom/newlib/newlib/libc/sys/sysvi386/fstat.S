	.globl	_fstat
	.globl	fstat
_fstat:
fstat:	
	movl	$0x1c, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax,%eax
	ret

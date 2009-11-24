	.globl	_chmod
	.globl	chmod
_chmod:
chmod:	
	movl	$0xf, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax, %eax
	ret

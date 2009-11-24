	.globl	_unlink
	.globl	unlink
_unlink:
unlink:	
	movl	$0xa, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax, %eax
	ret

	.globl	_link
	.globl	link
_link:
link:	
	movl	$0x9, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax, %eax
	ret

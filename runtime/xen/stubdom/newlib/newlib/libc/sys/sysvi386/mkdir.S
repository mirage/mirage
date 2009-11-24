	.globl	_mkdir
	.globl	mkdir
_mkdir:
mkdir:	
	movl	$0x50, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax, %eax
	ret

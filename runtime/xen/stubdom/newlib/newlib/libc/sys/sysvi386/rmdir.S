	.globl	_rmdir
	.globl	rmdir
_rmdir:
rmdir:	
	movl	$0x4f, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax, %eax
	ret

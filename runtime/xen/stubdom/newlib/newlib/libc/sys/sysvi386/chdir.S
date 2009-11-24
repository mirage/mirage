	.globl	_chdir
	.globl	chdir
_chdir:
chdir:	
	movl	$0xc, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax, %eax
	ret

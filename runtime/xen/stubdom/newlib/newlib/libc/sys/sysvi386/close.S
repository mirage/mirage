	.globl	_close
	.globl	close
_close:
close:	
	movl	$6, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax, %eax
	ret

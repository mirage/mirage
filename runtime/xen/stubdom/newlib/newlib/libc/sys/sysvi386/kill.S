	.globl	_kill
	.globl	kill
_kill:
kill:	
	movl	$0x25, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax, %eax
	ret

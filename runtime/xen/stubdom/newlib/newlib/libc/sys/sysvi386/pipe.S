	.globl	_pipe
	.globl	pipe
_pipe:
pipe:	
	movl	$0x2a, %eax
	lcall	$7,$0
	jb	_cerror
	movl	4(%esp), %ecx
	movl	(%ecx), %eax
	movl	4(%ecx), %edx
	xor	%eax, %eax
	ret

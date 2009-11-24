	.globl	_waitpid
	.globl	waitpid
_waitpid:
waitpid:	
	pushfl
	popl	%eax
	orl	$0x8c4,%eax
	pushl	%eax
	popfl
	movl	$0x7, %eax
	lcall	$7,$0
	jb	_cerror
	movl	8(%esp), %ecx
	testl	%ecx, %ecx
	je	bye
	movl	%edx, (%ecx)
bye:
	ret

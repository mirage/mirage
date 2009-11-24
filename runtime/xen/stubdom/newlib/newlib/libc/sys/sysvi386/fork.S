	.globl	_fork
	.globl	fork
_fork:
fork:
	movl	$2, %eax
	lcall	$7,$0
	jb	_cerror
	testl	%edx, %edx
	je	bye
	xorl	%eax,%eax
bye:
	ret

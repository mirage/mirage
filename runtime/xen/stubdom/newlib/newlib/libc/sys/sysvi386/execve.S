	.globl	_execve
	.globl	execve
_execve:
execve:
	movl	$0x3b, %eax
	lcall	$7,$0
	jb	_cerror

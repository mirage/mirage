	.globl	_cerror
_cerror:	
	movl	%eax, errno
	movl	$-1, %eax
	ret
	.data
	.globl	errno
errno:	.long 0



	.globl	_fcntl
	.globl	fcntl
_fcntl:
fcntl:	
	movl	$0x3e, %eax
	lcall	$7,$0
	jb	_cerror
	ret

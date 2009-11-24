
	.globl	_ioctl
	.globl	ioctl
_ioctl:
ioctl:	
	movl	$0x36, %eax
	lcall	$7,$0
	jb	_cerror
	ret

	.globl	_utime
	.globl	utime
_utime:
utime:	
	movl	$0x1e, %eax
	lcall	$7,$0
	jb	_cerror
	ret

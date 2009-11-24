	.globl	_lseek
	.globl	lseek
_lseek:
lseek:
	movl	$0x13, %eax
	lcall	$7,$0
	jb	_cerror
	ret


	.globl	_open
	.globl	open
_open:
open:
	movl	$5, %eax
	lcall	$7,$0
	jb	_cerror
	ret

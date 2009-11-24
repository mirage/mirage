	.globl	_stat
	.globl	stat
_stat:
stat:	
	movl	$0x12, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax,%eax
	ret

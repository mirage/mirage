	.globl	_rename
	.globl	rename
_rename:
rename:	
	movl	$0x3028, %eax
	lcall	$7,$0
	jb	_cerror
	xor	%eax, %eax
	ret

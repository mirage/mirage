	.globl	_geteuid
	.globl	geteuid
_geteuid:
geteuid:
	movl	$0x18, %eax
	lcall	$7,$0
	movl	%edx,%eax
	jb	_cerror
	ret

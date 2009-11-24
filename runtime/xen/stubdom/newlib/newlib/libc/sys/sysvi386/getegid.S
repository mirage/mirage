	.globl	_getegid
	.globl	getegid
_getegid:
getegid:
	movl	$0x2f, %eax
	lcall	$7,$0
	movl	%edx,%eax
	jb	_cerror
	ret

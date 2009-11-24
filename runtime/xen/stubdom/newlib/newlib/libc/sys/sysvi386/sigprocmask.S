/
/ The SCO signal stuff seems to be weird.  The POSIX stuff appears to
/ "extended" system calls, and use values in eax and edx.
/
	.globl	sigprocmask
sigprocmask:
	movl	$0x2828, %eax
	lcall	$7,$0
	jb	_cerror
	ret
	addl	$4, %esp
	lcall	$0xf,$0

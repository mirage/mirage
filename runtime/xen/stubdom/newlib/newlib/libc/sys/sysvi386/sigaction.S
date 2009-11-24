/
/ The SCO signal stuff seems to be weird.  The POSIX stuff appears to
/ "extended" system calls, and use values in eax and edx.
/ Like most of the other signal routines, it takes a function pointer
/ in %edx.  Since this function is terribly small, I am including it
/ in all of the ones that need it, for now at least.  Seems silly to include
/ a whole file for two instructions.

sigret:
	addl	$4, %esp
	lcall	$0xf, $0
	.globl	sigaction
sigaction:
	movl	$0x2728, %eax
	movl	sigret, %edx
	lcall	$7,$0
	jb	_cerror
	ret
	addl	$4, %esp
	lcall	$0xf,$0

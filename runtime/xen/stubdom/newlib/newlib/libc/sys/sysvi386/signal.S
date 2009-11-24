/ According to the iBCS2 book, signal() has 0x30 in %eax, and the address
/ of a function in %edx.  This function is where a signal handler will
/ return to; it should just adjust the stack pointer, and call $f,$0.
/ Strange but true.
	.globl	signal

sigret:
	addl	$4, %esp
	lcall	$0xf, $0
signal:
	movl	$0x30, %eax
	movl	sigret, %edx
	lcall	$7,$0
	jb	_cerror
/ The iBCS2 book also clears out %eax here, which seems to be broken.
	ret

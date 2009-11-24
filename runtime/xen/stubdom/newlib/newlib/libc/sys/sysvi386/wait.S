	.globl	_wait
	.globl	wait
_wait:
wait:	
	movl	$0x7, %eax
	lcall	$7,$0
	jb	_cerror
	movl	4(%esp), %ecx
	testl	%ecx, %ecx
	je	bye
	movl	%edx, (%ecx)
bye:
	ret

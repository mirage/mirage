	.globl	_alarm
_alarm:
	movl	$0x1b, %eax
	lcall	$7,$0
	ret


	.globl	__ioctl
	.globl	_ioctl
__ioctl:
_ioctl:	chlvl	#0,#0x36
	jnl	ok	
	jmp	cerror
ok:	ret	#0


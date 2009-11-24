	.globl	_sysv60
_sysv60:
	chlvl	#0,#0x32
	jnl	ok
	jmp	cerror
ok:	xor.w	r0,r0
	ret	#0

	

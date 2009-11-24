
	.globl	__fstat
	.globl	_fstat
__fstat:
_fstat:	chlvl	#0,#0x1c
	jnl	ok	
	jmp	cerror
ok:	xor.w	r0,r0
	ret	#0



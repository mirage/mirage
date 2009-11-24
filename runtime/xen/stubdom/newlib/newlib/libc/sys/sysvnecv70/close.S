
	.globl	__close
	.globl	_close
__close:
_close:	chlvl	#0,#6
	jnl	ok	
	jmp	cerror
ok:	xor.w	r0,r0
	ret	#0


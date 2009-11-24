
	.globl	__open
	.globl	_open
__open:
_open:	chlvl	#0,#5
	jnl	ok	
	jmp	cerror
ok:	xor.w	r0,r0
	ret	#0


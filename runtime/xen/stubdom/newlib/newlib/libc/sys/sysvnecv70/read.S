
	.globl	__read
	.globl	_read
__read:
_read:	chlvl	#0,#3
	jnl	ok	
	jmp	cerror
ok:	ret	#0


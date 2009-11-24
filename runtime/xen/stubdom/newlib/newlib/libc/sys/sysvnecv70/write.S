
	.globl	__write
	.globl	_write
__write:
_write:	chlvl	#0,#4
	jnl	ok	
	jmp	cerror
ok:	ret	#0


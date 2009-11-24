
	.globl	__exit
__exit:	chlvl	#0,#1
	jnl	ok	
	jmp	cerror
ok:	ret	#0


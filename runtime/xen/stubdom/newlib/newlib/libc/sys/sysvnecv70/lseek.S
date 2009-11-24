
	.globl	__lseek
	.globl	_lseek
__lseek:
_lseek:	chlvl	#0,#0x13
	jnl	ok	
	jmp	cerror
ok:	ret	#0


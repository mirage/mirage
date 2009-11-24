
	.globl	_sbrk
	.globl	__sbrk
_sbrk:
__sbrk:
	mov.w	  tptr,r0
	 test.w	  [ap]
	 je	   justreport 
	 add.w	  r0,[ap]
	 push	  [ap]
	 mov.w	  ap,r3
	 mov.w	  sp,ap
	 chlvl	  #0x0,#0x11
	 jnl	 ok 
	 add.w	  #0x4,sp
	 jmp	  cerror
ok:	 add.w	  #0x4,sp
	 mov.w	  tptr,r0
	 mov.w	  [r3],tptr
justreport:
	ret	  #0x0

	.globl	_brk
	.globl	__brk
__brk:
_brk:	 chlvl	  #0x0,#0x11
	 jnl	 ok1
	 jmp	 cerror 
ok1:	 mov.w	  [ap],63
	 xor.w	  r0,r0
	 ret	  #0x0
	
		.data
tptr:	.word	_end

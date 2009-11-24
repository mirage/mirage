	.globl	_isatty
	.globl	__isatty
	
_isatty:
__isatty:
	 prepare  #0x14
	 movea.w  -0x12[fp],[-sp]
	push	  #0x5401
	 push	  [ap]
	 call	  _ioctl,[sp]
	add.w	  #0xc,sp
	 test.w	  r0
	 jge	  ret1
	 mov.w	  #0x0,r0
	 dispose
	 ret	  #0x0
ret1:	 mov.w	  #0x1,r0
	dispose
	ret	#0

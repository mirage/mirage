	.globl	_fpgetsticky
_fpgetsticky:
	getpsw	  r0
	and.w	  #0x1f00,r0
	shl.w	  #0xf8,r0
	ret	  #0x0


	.globl	_fpsetsticky	
_fpsetsticky:
	 getpsw	  r0
	 mov.w	  [ap],r1
	 shl.w	  #0x8,r1
	 updpsw.h r1,#0x1f00
	 trapfl
	 and.w	  #0x1f00,r0
	 shl.w	  #0xf8,r0
	 ret	  #0x0

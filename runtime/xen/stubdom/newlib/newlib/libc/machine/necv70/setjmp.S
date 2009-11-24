	.globl	_setjmp
_setjmp:
	mov.w	[ap],r0
	mov.d	r15,[r0+]
	mov.d	r17,[r0+]
	mov.d	r19,[r0+]
	mov.d	r21,[r0+]
	mov.d	r23,[r0+]
	mov.w	-0x4[ap],[r0+]
	mov.w	fp,[r0+]
	mov.w	ap,[r0+]
	mov.w	-0x8[ap],[r0]
	xor.w	r0,r0
	ret	#0x0

	.globl	_longjmp
_longjmp:
	 mov.w	  0x4[ap],r0
	 mov.w	  [ap],r1
	 mov.d	  [r1+],r15
	 mov.d	  [r1+],r17
	 mov.d	  [r1+],r19
	 mov.d	  [r1+],r21
	 mov.d	  [r1+],r23
	 mov.d	  [r1+],ap
	 mov.w	  [r1+],sp
	 test.w	  r0
	 jne	  noz
	 mov.w	  #0x1,r0
noz:	 jmp	  [0x0[r1]]


	

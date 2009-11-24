	.globl	start
start:
	sub.w	#0x8,sp
	mov.w	0x8[sp],[sp]
	movea.w	0xc[sp],r0
	mov.w	r0,0x4[sp]
tloop:	test.w	[r0+]
	jne	tloop	
	cmp.w	r0,[0x4[sp]]
	jge	l1
	sub.w	#0x4,r0
l1:	mov.w	r0,0x8[sp]
	mov.w	r0,_environ


	call	_main,[sp]
	add.w	#0xc,sp
	push	r0
	call	_exit,[sp]
	add.w	#0x4,sp
	chlvl	#0,#1

	.data

	.globl	_environ
_environ:
	.word	0


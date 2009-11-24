	.globl	cerror
cerror:	mov.w	r0,_errno
	neg.w	#1,r0
	ret	#0

	.data
	.globl	_errno
_errno:	.word 0


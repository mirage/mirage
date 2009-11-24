	.text
	.global	___trap0
___trap0:
	syscall
	cmp	0,d0
	beq	noerr
	mov	d0,(_errno)
noerr:
	rts

	.text
	.global	___trap0
___trap0:
	syscall
	cmp 0,d0
	beq .L0
	mov d0,(_errno)
.L0:
#ifdef __mn10300__
	rets
#else
	rts
#endif

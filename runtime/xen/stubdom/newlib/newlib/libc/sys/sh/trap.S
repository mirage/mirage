#if __SH5__
	.mode	SHmedia
#if __SH5__ == 32 && __SHMEDIA__
	.section	.text..SHmedia32, "ax"
#else
	.text
#endif
	.global ___trap34
___trap34:
	movi	34, r0
	trapa	r0
	pt/l	ret, tr1
	ptabs/l	r18, tr0
	beqi	r1, 0, tr1
#if __SH5__ == 64
	movi	((_errno >> 48) & 65535), r0
	shori	((_errno >> 32) & 65535), r0
	shori	((_errno >> 16) & 65535), r0
#else
	movi	((_errno >> 16) & 65535), r0
#endif
	shori	(_errno & 65535), r0
	stx.l	r0, r63, r1
ret:
	blink	tr0, r63
	
#else
	.text
	.global	___trap34
___trap34:
	trapa	#34
	tst	r1,r1	! r1 is errno
	bt	ret
	mov.l	perrno,r2
	mov.l	r1,@r2
ret:
	rts
	nop
	
	.align	2
perrno:
	.long	_errno
#endif /* ! __SH5__ */

#include "setarch.h"

#include "defines.h"

	; dst A0
	; src A1
	; len A2

	.global ___reg_memset
___reg_memset:
	MOVP	A0P,A3P
	MOVP	A2P,A2P
	beq	noset

memloop:
	mov.b	A1L,@A0P
#ifdef __NORMAL_MODE__
	add	#1,A0P
	sub	#1,A2P
#else
	adds	#1,A0P
	subs	#1,A2P
#endif
	MOVP	A2P,A2P
	bne	memloop

noset:
	MOVP	A3P,A0P
	rts


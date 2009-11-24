#include "setarch.h"

#include "defines.h"

	; dst A0
	; src A1
	; len A2
	.global ___reg_memcpy
___reg_memcpy:

	MOVP	A0P,A3P	; keep copy of result
	ADDP	A2P,A0P	; point to end of dst
	ADDP	A2P,A1P	; point to end of src
	CMPP	A0P,A3P	; see if anything to do
	beq	quit

loop:
#ifdef __NORMAL_MODE__
	sub     #1,A1P		; point to byte
#else
	subs    #1,A1P          ; point to byte
#endif
	mov.b	@A1P,A2L	; get byte
	mov.b	A2L,@-A0P	; save byte
	CMPP	A0P,A3P 	; at the front again ?
	bne 	loop

	; return with A0 pointing to dst
quit:	rts


; This file exists to provide a movsd implementation of strcpy().
; Continue to use the generic version for targets other than h8sx.
#ifdef __H8300SX__
#include "setarch.h"

	.global _strcpy
_strcpy:
	stm.l	er4-er6,@-er7
	mov.l	er0,er6
	mov.l	er1,er5
1:	movsd	2f
	bra	1b
2:	rts/l	er4-er6
#endif

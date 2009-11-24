;int close(int fd);
;Integer arguments have to be zero extended.

#include "setarch.h"

	.section .text
	.align 2
	.global __close
__close:
#if defined(__H8300H__) || defined(__H8300S__) || defined (__H8300SX__)
#if __INT_MAX__ == 32767
	extu.l er0
#endif
#endif
	jsr @@0xc9
	rts
	.end

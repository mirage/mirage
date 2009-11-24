;ssize_t write(int fd, const void *buf, size_t count);
;Integer arguments have to be zero extended.

#include "setarch.h"

	.section .text
	.align 2
	.global __write
__write:
#if defined(__H8300H__) || defined(__H8300S__) || defined (__H8300SX__)
#if __INT_MAX__ == 32767
	extu.l	er0
#endif
#endif
	jsr @@0xc7
	rts
	.end

;ssize_t read(int fd, void *buf, size_t count);
;Integer arguments have to be zero extended.

#include "setarch.h"

	.section .text
	.align 2
	.global __read
__read:
#if defined(__H8300H__) || defined(__H8300S__) || defined (__H8300SX__)
#if __INT_MAX__ == 32767
	extu.l  er0
#endif
#endif
	jsr @@0xc6
	rts
	.end
									

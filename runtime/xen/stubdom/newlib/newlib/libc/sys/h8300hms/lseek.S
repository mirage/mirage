;off_t lseek(int fildes, off_t offset, int whence);
;Integer arguments have to be zero extended.

#include "setarch.h"

	.section .text
	.align 2
	.global __lseek
__lseek:
#if defined(__H8300H__) || defined(__H8300S__) || defined (__H8300SX__)
#if __INT_MAX__ == 32767
	extu.l er0
	extu.l er2
#endif
#endif
	jsr @@0xc8
	rts
	.end

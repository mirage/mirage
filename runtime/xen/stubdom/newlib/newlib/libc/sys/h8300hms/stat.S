;int stat(const char *file_name, struct stat *buf);

#include "setarch.h"

	.section .text
	.align 2
	.global __stat
__stat:
	jsr @@0xca
	rts
	.end
									

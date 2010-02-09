.section ".bss"
.align 8
#include <endian.h>

.type environ,object
.weak environ
.type __environ,object
.weak __environ
__environ:
environ:
#if __WORDSIZE == 64
	.quad 0
#else
	.long 0
#endif
.size environ,.-environ
.size __environ,.-__environ

#ifndef __DIETREFDEF_H__
#include <endian.h>

#if (__WORDSIZE == 64)
#define __DIETREFDEF_H__ ".quad"
#else
#define __DIETREFDEF_H__ ".long"
#endif

#define __dietref(name) \
__asm__(".section .note\n" \
	"\t.long 4\n" \
	"\t.long 2f-1f\n" \
	"\t.long 0\n" \
	"\t.ascii \"diet\"\n" \
	"1:\t" __DIETREFDEF_H__ " " name "\n2:" \
	".previous")

#endif

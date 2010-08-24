/* diet includes this file to create linker dependencies on the diet
 * libc, so trying to link an object file compiled with diet against
 * glibc will fail. */

#ifndef NODIETREF
#ifdef __ASSEMBLER__
#include <endian.h>
.section .note
.long	4
.long	2f-1f
.long	0
.ascii	"diet"
1:
#if (__WORDSIZE == 64)
.quad __you_tried_to_link_a_dietlibc_object_against_glibc
#else
.long __you_tried_to_link_a_dietlibc_object_against_glibc
#endif
2:
.previous
#else
#include <dietrefdef.h>
__dietref("__you_tried_to_link_a_dietlibc_object_against_glibc");
#endif
#endif

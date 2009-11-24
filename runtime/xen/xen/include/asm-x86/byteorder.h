#ifndef __ASM_X86_BYTEORDER_H__
#define __ASM_X86_BYTEORDER_H__

#include <asm/types.h>
#include <xen/compiler.h>

static inline __attribute_const__ __u32 ___arch__swab32(__u32 x)
{
    asm("bswap %0" : "=r" (x) : "0" (x));
    return x;
}

static inline __attribute_const__ __u64 ___arch__swab64(__u64 val)
{ 
    union { 
        struct { __u32 a,b; } s;
        __u64 u;
    } v;
    v.u = val;
    asm("bswapl %0 ; bswapl %1 ; xchgl %0,%1" 
        : "=r" (v.s.a), "=r" (v.s.b) 
        : "0" (v.s.a), "1" (v.s.b)); 
    return v.u;
} 

/* Do not define swab16.  Gcc is smart enough to recognize "C" version and
   convert it into rotation or exhange.  */

#define __arch__swab64(x) ___arch__swab64(x)
#define __arch__swab32(x) ___arch__swab32(x)

#define __BYTEORDER_HAS_U64__

#include <xen/byteorder/little_endian.h>

#endif /* __ASM_X86_BYTEORDER_H__ */

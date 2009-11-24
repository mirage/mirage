#ifndef __I386_DIV64
#define __I386_DIV64

#include <xen/types.h>

#if BITS_PER_LONG == 64

#define do_div(n,base) ({                       \
    uint32_t __base = (base);                   \
    uint32_t __rem;                             \
    __rem = ((uint64_t)(n)) % __base;           \
    (n) = ((uint64_t)(n)) / __base;             \
    __rem;                                      \
})

#else

/*
 * do_div() is NOT a C function. It wants to return
 * two values (the quotient and the remainder), but
 * since that doesn't work very well in C, what it
 * does is:
 *
 * - modifies the 64-bit dividend _in_place_
 * - returns the 32-bit remainder
 *
 * This ends up being the most efficient "calling
 * convention" on x86.
 */
#define do_div(n,base) ({                                       \
    unsigned long __upper, __low, __high, __mod, __base;        \
    __base = (base);                                            \
    asm ( "" : "=a" (__low), "=d" (__high) : "A" (n) );         \
    __upper = __high;                                           \
    if ( __high )                                               \
    {                                                           \
        __upper = __high % (__base);                            \
        __high = __high / (__base);                             \
    }                                                           \
    asm ( "divl %2"                                             \
          : "=a" (__low), "=d" (__mod)                          \
          : "rm" (__base), "0" (__low), "1" (__upper) );        \
    asm ( "" : "=A" (n) : "a" (__low), "d" (__high) );          \
    __mod;                                                      \
})

#endif

#endif

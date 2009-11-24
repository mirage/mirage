#ifndef __X86_STRING_H__
#define __X86_STRING_H__

#include <xen/config.h>

static inline void *__variable_memcpy(void *to, const void *from, size_t n)
{
    long d0, d1, d2;
    __asm__ __volatile__ (
        "   rep ; movs"__OS"\n"
        "   mov %4,%3       \n"
        "   rep ; movsb     \n"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n/BYTES_PER_LONG), "r" (n%BYTES_PER_LONG), "1" (to), "2" (from)
        : "memory" );
    return to;
}

/*
 * This looks horribly ugly, but the compiler can optimize it totally,
 * as the count is constant.
 */
static always_inline void * __constant_memcpy(
    void * to, const void * from, size_t n)
{
    switch ( n )
    {
    case 0:
        return to;
    case 1:
        *(u8 *)to = *(const u8 *)from;
        return to;
    case 2:
        *(u16 *)to = *(const u16 *)from;
        return to;
    case 3:
        *(u16 *)to = *(const u16 *)from;
        *(2+(u8 *)to) = *(2+(const u8 *)from);
        return to;
    case 4:
        *(u32 *)to = *(const u32 *)from;
        return to;
    case 5:
        *(u32 *)to = *(const u32 *)from;
        *(4+(u8 *)to) = *(4+(const u8 *)from);
        return to;
    case 6:
        *(u32 *)to = *(const u32 *)from;
        *(2+(u16 *)to) = *(2+(const u16 *)from);
        return to;
    case 7:
        *(u32 *)to = *(const u32 *)from;
        *(2+(u16 *)to) = *(2+(const u16 *)from);
        *(6+(u8 *)to) = *(6+(const u8 *)from);
        return to;
    case 8:
        *(u64 *)to = *(const u64 *)from;
        return to;
    case 12:
        *(u64 *)to = *(const u64 *)from;
        *(2+(u32 *)to) = *(2+(const u32 *)from);
        return to;
    case 16:
        *(u64 *)to = *(const u64 *)from;
        *(1+(u64 *)to) = *(1+(const u64 *)from);
        return to;
    case 20:
        *(u64 *)to = *(const u64 *)from;
        *(1+(u64 *)to) = *(1+(const u64 *)from);
        *(4+(u32 *)to) = *(4+(const u32 *)from);
        return to;
    }
#define COMMON(x)                                       \
    __asm__ __volatile__ (                              \
        "rep ; movs"__OS                                \
        x                                               \
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)            \
        : "0" (n/BYTES_PER_LONG), "1" (to), "2" (from)  \
        : "memory" );
    {
        long d0, d1, d2;
        switch ( n % BYTES_PER_LONG )
        {
        case 0: COMMON(""); return to;
        case 1: COMMON("\n\tmovsb"); return to;
        case 2: COMMON("\n\tmovsw"); return to;
        case 3: COMMON("\n\tmovsw\n\tmovsb"); return to;
        case 4: COMMON("\n\tmovsl"); return to;
        case 5: COMMON("\n\tmovsl\n\tmovsb"); return to;
        case 6: COMMON("\n\tmovsl\n\tmovsw"); return to;
        case 7: COMMON("\n\tmovsl\n\tmovsw\n\tmovsb"); return to;
        }
    }
#undef COMMON
    return to;
}

#define __HAVE_ARCH_MEMCPY
/* align source to a 64-bit boundary */
static always_inline
void *__var_memcpy(void *t, const void *f, size_t n)
{
    int off = (unsigned long)f & 0x7;
    /* just do alignment if needed and if size is worth */
    if ( (n > 32) && off ) {
        size_t n1 = 8 - off;
        __variable_memcpy(t, f, n1);
        __variable_memcpy(t + n1, f + n1, n - n1);
        return t;
    } else {
            return (__variable_memcpy(t, f, n));
    }
}

#define memcpy(t,f,n) (__memcpy((t),(f),(n)))
static always_inline
void *__memcpy(void *t, const void *f, size_t n)
{
    return (__builtin_constant_p(n) ?
            __constant_memcpy((t),(f),(n)) :
            __var_memcpy((t),(f),(n)));
}

/* Some version of gcc don't have this builtin. It's non-critical anyway. */
#define __HAVE_ARCH_MEMMOVE
extern void *memmove(void *dest, const void *src, size_t n);

static inline void *__memset_generic(void *s, char c, size_t count)
{
    long d0, d1;
    __asm__ __volatile__ (
        "rep ; stosb"
        : "=&c" (d0), "=&D" (d1) : "a" (c), "1" (s), "0" (count) : "memory" );
    return s;
}

/* we might want to write optimized versions of these later */
#define __constant_count_memset(s,c,count) __memset_generic((s),(c),(count))

/*
 * memset(x,0,y) is a reasonably common thing to do, so we want to fill
 * things 32 bits at a time even when we don't know the size of the
 * area at compile-time..
 */
static inline void *__constant_c_memset(void *s, unsigned long c, size_t count)
{
    long d0, d1;
    __asm__ __volatile__(
        "   rep ; stos"__OS"\n"
        "   mov  %3,%4      \n"
        "   rep ; stosb     \n"
        : "=&c" (d0), "=&D" (d1)
        : "a" (c), "r" (count%BYTES_PER_LONG),
          "0" (count/BYTES_PER_LONG), "1" (s)
        : "memory" );
    return s;
}

/*
 * This looks horribly ugly, but the compiler can optimize it totally,
 * as we by now know that both pattern and count is constant..
 */
static always_inline void *__constant_c_and_count_memset(
    void *s, unsigned long pattern, size_t count)
{
    switch ( count )
    {
    case 0:
        return s;
    case 1:
        *(u8 *)s = pattern;
        return s;
    case 2:
        *(u16 *)s = pattern;
        return s;
    case 3:
        *(u16 *)s = pattern;
        *(2+(u8 *)s) = pattern;
        return s;
    case 4:
        *(u32 *)s = pattern;
        return s;
    case 5:
        *(u32 *)s = pattern;
        *(4+(u8 *)s) = pattern;
        return s;
    case 6:
        *(u32 *)s = pattern;
        *(2+(u16 *)s) = pattern;
        return s;
    case 7:
        *(u32 *)s = pattern;
        *(2+(u16 *)s) = pattern;
        *(6+(u8 *)s) = pattern;
        return s;
    case 8:
        *(u64 *)s = pattern;
        return s;
    }
#define COMMON(x)                                               \
    __asm__  __volatile__ (                                     \
        "rep ; stos"__OS                                        \
        x                                                       \
        : "=&c" (d0), "=&D" (d1)                                \
        : "a" (pattern), "0" (count/BYTES_PER_LONG), "1" (s)    \
        : "memory" )
    {
        long d0, d1;
        switch ( count % BYTES_PER_LONG )
        {
        case 0: COMMON(""); return s;
        case 1: COMMON("\n\tstosb"); return s;
        case 2: COMMON("\n\tstosw"); return s;
        case 3: COMMON("\n\tstosw\n\tstosb"); return s;
        case 4: COMMON("\n\tstosl"); return s;
        case 5: COMMON("\n\tstosl\n\tstosb"); return s;
        case 6: COMMON("\n\tstosl\n\tstosw"); return s;
        case 7: COMMON("\n\tstosl\n\tstosw\n\tstosb"); return s;
        }
    }
#undef COMMON
    return s;
}

#define __constant_c_x_memset(s, c, count) \
(__builtin_constant_p(count) ? \
 __constant_c_and_count_memset((s),(c),(count)) : \
 __constant_c_memset((s),(c),(count)))

#define __var_x_memset(s, c, count) \
(__builtin_constant_p(count) ? \
 __constant_count_memset((s),(c),(count)) : \
 __memset_generic((s),(c),(count)))

#ifdef CONFIG_X86_64
#define MEMSET_PATTERN_MUL 0x0101010101010101UL
#else
#define MEMSET_PATTERN_MUL 0x01010101UL
#endif

#define __HAVE_ARCH_MEMSET
#define memset(s, c, count) (__memset((s),(c),(count)))
#define __memset(s, c, count) \
(__builtin_constant_p(c) ? \
 __constant_c_x_memset((s),(MEMSET_PATTERN_MUL*(unsigned char)(c)),(count)) : \
 __var_x_memset((s),(c),(count)))

#endif /* __X86_STRING_H__ */

#ifndef __X86_64_SYSTEM_H__
#define __X86_64_SYSTEM_H__

#define cmpxchg(ptr,o,n)                                                \
    ((__typeof__(*(ptr)))__cmpxchg((ptr),(unsigned long)(o),            \
                                   (unsigned long)(n),sizeof(*(ptr))))

/*
 * This function causes value _o to be changed to _n at location _p.
 * If this access causes a fault then we return 1, otherwise we return 0.
 * If no fault occurs then _o is updated to the value we saw at _p. If this
 * is the same as the initial value of _o then _n is written to location _p.
 */
#define __cmpxchg_user(_p,_o,_n,_isuff,_oppre,_regtype)                 \
    asm volatile (                                                      \
        "1: " LOCK_PREFIX "cmpxchg"_isuff" %"_oppre"2,%3\n"             \
        "2:\n"                                                          \
        ".section .fixup,\"ax\"\n"                                      \
        "3:     movl $1,%1\n"                                           \
        "       jmp 2b\n"                                               \
        ".previous\n"                                                   \
        ".section __ex_table,\"a\"\n"                                   \
        "       .align 8\n"                                             \
        "       .quad 1b,3b\n"                                          \
        ".previous"                                                     \
        : "=a" (_o), "=r" (_rc)                                         \
        : _regtype (_n), "m" (*__xg((volatile void *)_p)), "0" (_o), "1" (0) \
        : "memory");

#define cmpxchg_user(_p,_o,_n)                                          \
({                                                                      \
    int _rc;                                                            \
    switch ( sizeof(*(_p)) ) {                                          \
    case 1:                                                             \
        __cmpxchg_user(_p,_o,_n,"b","b","q");                           \
        break;                                                          \
    case 2:                                                             \
        __cmpxchg_user(_p,_o,_n,"w","w","r");                           \
        break;                                                          \
    case 4:                                                             \
        __cmpxchg_user(_p,_o,_n,"l","k","r");                           \
        break;                                                          \
    case 8:                                                             \
        __cmpxchg_user(_p,_o,_n,"q","","r");                            \
        break;                                                          \
    }                                                                   \
    _rc;                                                                \
})

static inline void atomic_write64(uint64_t *p, uint64_t v)
{
    *p = v;
}

#define mb()                    \
    asm volatile ( "mfence" : : : "memory" )

#endif /* __X86_64_SYSTEM_H__ */

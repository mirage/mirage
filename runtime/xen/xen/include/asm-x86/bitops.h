#ifndef _X86_BITOPS_H
#define _X86_BITOPS_H

/*
 * Copyright 1992, Linus Torvalds.
 */

#include <xen/config.h>

#ifdef CONFIG_SMP
#define LOCK_PREFIX "lock ; "
#else
#define LOCK_PREFIX ""
#endif

/*
 * We specify the memory operand as both input and output because the memory
 * operand is both read from and written to. Since the operand is in fact a
 * word array, we also specify "memory" in the clobbers list to indicate that
 * words other than the one directly addressed by the memory operand may be
 * modified. We don't use "+m" because the gcc manual says that it should be
 * used only when the constraint allows the operand to reside in a register.
 */

#define ADDR (*(volatile long *) addr)
#define CONST_ADDR (*(const volatile long *) addr)

extern void __bitop_bad_size(void);
#define bitop_bad_size(addr) (sizeof(*(addr)) < 4)

/**
 * set_bit - Atomically set a bit in memory
 * @nr: the bit to set
 * @addr: the address to start counting from
 *
 * This function is atomic and may not be reordered.  See __set_bit()
 * if you do not require the atomic guarantees.
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 */
static inline void set_bit(int nr, volatile void *addr)
{
    asm volatile (
        LOCK_PREFIX
        "btsl %1,%0"
        : "=m" (ADDR)
        : "Ir" (nr), "m" (ADDR) : "memory");
}
#define set_bit(nr, addr) ({                            \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    set_bit(nr, addr);                                  \
})

/**
 * __set_bit - Set a bit in memory
 * @nr: the bit to set
 * @addr: the address to start counting from
 *
 * Unlike set_bit(), this function is non-atomic and may be reordered.
 * If it's called on the same region of memory simultaneously, the effect
 * may be that only one operation succeeds.
 */
static inline void __set_bit(int nr, volatile void *addr)
{
    asm volatile (
        "btsl %1,%0"
        : "=m" (ADDR)
        : "Ir" (nr), "m" (ADDR) : "memory");
}
#define __set_bit(nr, addr) ({                          \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    __set_bit(nr, addr);                                \
})

/**
 * clear_bit - Clears a bit in memory
 * @nr: Bit to clear
 * @addr: Address to start counting from
 *
 * clear_bit() is atomic and may not be reordered.  However, it does
 * not contain a memory barrier, so if it is used for locking purposes,
 * you should call smp_mb__before_clear_bit() and/or smp_mb__after_clear_bit()
 * in order to ensure changes are visible on other processors.
 */
static inline void clear_bit(int nr, volatile void *addr)
{
    asm volatile (
        LOCK_PREFIX
        "btrl %1,%0"
        : "=m" (ADDR)
        : "Ir" (nr), "m" (ADDR) : "memory");
}
#define clear_bit(nr, addr) ({                          \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    clear_bit(nr, addr);                                \
})

/**
 * __clear_bit - Clears a bit in memory
 * @nr: Bit to clear
 * @addr: Address to start counting from
 *
 * Unlike clear_bit(), this function is non-atomic and may be reordered.
 * If it's called on the same region of memory simultaneously, the effect
 * may be that only one operation succeeds.
 */
static inline void __clear_bit(int nr, volatile void *addr)
{
    asm volatile (
        "btrl %1,%0"
        : "=m" (ADDR)
        : "Ir" (nr), "m" (ADDR) : "memory");
}
#define __clear_bit(nr, addr) ({                        \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    __clear_bit(nr, addr);                              \
})

#define smp_mb__before_clear_bit() ((void)0)
#define smp_mb__after_clear_bit()  ((void)0)

/**
 * __change_bit - Toggle a bit in memory
 * @nr: the bit to set
 * @addr: the address to start counting from
 *
 * Unlike change_bit(), this function is non-atomic and may be reordered.
 * If it's called on the same region of memory simultaneously, the effect
 * may be that only one operation succeeds.
 */
static inline void __change_bit(int nr, volatile void *addr)
{
    asm volatile (
        "btcl %1,%0"
        : "=m" (ADDR)
        : "Ir" (nr), "m" (ADDR) : "memory");
}
#define __change_bit(nr, addr) ({                       \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    __change_bit(nr, addr);                             \
})

/**
 * change_bit - Toggle a bit in memory
 * @nr: Bit to clear
 * @addr: Address to start counting from
 *
 * change_bit() is atomic and may not be reordered.
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 */
static inline void change_bit(int nr, volatile void *addr)
{
    asm volatile (
        LOCK_PREFIX
        "btcl %1,%0"
        : "=m" (ADDR)
        : "Ir" (nr), "m" (ADDR) : "memory");
}
#define change_bit(nr, addr) ({                         \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    change_bit(nr, addr);                               \
})

/**
 * test_and_set_bit - Set a bit and return its old value
 * @nr: Bit to set
 * @addr: Address to count from
 *
 * This operation is atomic and cannot be reordered.  
 * It also implies a memory barrier.
 */
static inline int test_and_set_bit(int nr, volatile void *addr)
{
    int oldbit;

    asm volatile (
        LOCK_PREFIX
        "btsl %2,%1\n\tsbbl %0,%0"
        : "=r" (oldbit), "=m" (ADDR)
        : "Ir" (nr), "m" (ADDR) : "memory");
    return oldbit;
}
#define test_and_set_bit(nr, addr) ({                   \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    test_and_set_bit(nr, addr);                         \
})

/**
 * __test_and_set_bit - Set a bit and return its old value
 * @nr: Bit to set
 * @addr: Address to count from
 *
 * This operation is non-atomic and can be reordered.  
 * If two examples of this operation race, one can appear to succeed
 * but actually fail.  You must protect multiple accesses with a lock.
 */
static inline int __test_and_set_bit(int nr, volatile void *addr)
{
    int oldbit;

    asm volatile (
        "btsl %2,%1\n\tsbbl %0,%0"
        : "=r" (oldbit), "=m" (ADDR)
        : "Ir" (nr), "m" (ADDR) : "memory");
    return oldbit;
}
#define __test_and_set_bit(nr, addr) ({                 \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    __test_and_set_bit(nr, addr);                       \
})

/**
 * test_and_clear_bit - Clear a bit and return its old value
 * @nr: Bit to set
 * @addr: Address to count from
 *
 * This operation is atomic and cannot be reordered.  
 * It also implies a memory barrier.
 */
static inline int test_and_clear_bit(int nr, volatile void *addr)
{
    int oldbit;

    asm volatile (
        LOCK_PREFIX
        "btrl %2,%1\n\tsbbl %0,%0"
        : "=r" (oldbit), "=m" (ADDR)
        : "Ir" (nr), "m" (ADDR) : "memory");
    return oldbit;
}
#define test_and_clear_bit(nr, addr) ({                 \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    test_and_clear_bit(nr, addr);                       \
})

/**
 * __test_and_clear_bit - Clear a bit and return its old value
 * @nr: Bit to set
 * @addr: Address to count from
 *
 * This operation is non-atomic and can be reordered.  
 * If two examples of this operation race, one can appear to succeed
 * but actually fail.  You must protect multiple accesses with a lock.
 */
static inline int __test_and_clear_bit(int nr, volatile void *addr)
{
    int oldbit;

    asm volatile (
        "btrl %2,%1\n\tsbbl %0,%0"
        : "=r" (oldbit), "=m" (ADDR)
        : "Ir" (nr), "m" (ADDR) : "memory");
    return oldbit;
}
#define __test_and_clear_bit(nr, addr) ({               \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    __test_and_clear_bit(nr, addr);                     \
})

/* WARNING: non atomic and it can be reordered! */
static inline int __test_and_change_bit(int nr, volatile void *addr)
{
    int oldbit;

    asm volatile (
        "btcl %2,%1\n\tsbbl %0,%0"
        : "=r" (oldbit), "=m" (ADDR)
        : "Ir" (nr), "m" (ADDR) : "memory");
    return oldbit;
}
#define __test_and_change_bit(nr, addr) ({              \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    __test_and_change_bit(nr, addr);                    \
})

/**
 * test_and_change_bit - Change a bit and return its new value
 * @nr: Bit to set
 * @addr: Address to count from
 *
 * This operation is atomic and cannot be reordered.  
 * It also implies a memory barrier.
 */
static inline int test_and_change_bit(int nr, volatile void *addr)
{
    int oldbit;

    asm volatile (
        LOCK_PREFIX
        "btcl %2,%1\n\tsbbl %0,%0"
        : "=r" (oldbit), "=m" (ADDR)
        : "Ir" (nr), "m" (ADDR) : "memory");
    return oldbit;
}
#define test_and_change_bit(nr, addr) ({                \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    test_and_change_bit(nr, addr);                      \
})

static inline int constant_test_bit(int nr, const volatile void *addr)
{
    return ((1U << (nr & 31)) &
            (((const volatile unsigned int *)addr)[nr >> 5])) != 0;
}

static inline int variable_test_bit(int nr, const volatile void *addr)
{
    int oldbit;

    asm volatile (
        "btl %2,%1\n\tsbbl %0,%0"
        : "=r" (oldbit)
        : "m" (CONST_ADDR), "Ir" (nr) : "memory" );
    return oldbit;
}

#define test_bit(nr, addr) ({                           \
    if ( bitop_bad_size(addr) ) __bitop_bad_size();     \
    (__builtin_constant_p(nr) ?                         \
     constant_test_bit((nr),(addr)) :                   \
     variable_test_bit((nr),(addr)));                   \
})

extern unsigned int __find_first_bit(
    const unsigned long *addr, unsigned int size);
extern unsigned int __find_next_bit(
    const unsigned long *addr, unsigned int size, unsigned int offset);
extern unsigned int __find_first_zero_bit(
    const unsigned long *addr, unsigned int size);
extern unsigned int __find_next_zero_bit(
    const unsigned long *addr, unsigned int size, unsigned int offset);

static inline unsigned int __scanbit(unsigned long val, unsigned long max)
{
    asm ( "bsf %1,%0 ; cmovz %2,%0" : "=&r" (val) : "r" (val), "r" (max) );
    return (unsigned int)val;
}

/**
 * find_first_bit - find the first set bit in a memory region
 * @addr: The address to start the search at
 * @size: The maximum size to search
 *
 * Returns the bit-number of the first set bit, not the number of the byte
 * containing a bit.
 */
#define find_first_bit(addr,size)                               \
((__builtin_constant_p(size) && (size) <= BITS_PER_LONG ?       \
  (__scanbit(*(const unsigned long *)addr, size)) :             \
  __find_first_bit(addr,size)))

/**
 * find_next_bit - find the first set bit in a memory region
 * @addr: The address to base the search on
 * @offset: The bitnumber to start searching at
 * @size: The maximum size to search
 */
#define find_next_bit(addr,size,off)                                     \
((__builtin_constant_p(size) && (size) <= BITS_PER_LONG ?                \
  ((off) + (__scanbit((*(const unsigned long *)addr) >> (off), size))) : \
  __find_next_bit(addr,size,off)))

/**
 * find_first_zero_bit - find the first zero bit in a memory region
 * @addr: The address to start the search at
 * @size: The maximum size to search
 *
 * Returns the bit-number of the first zero bit, not the number of the byte
 * containing a bit.
 */
#define find_first_zero_bit(addr,size)                          \
((__builtin_constant_p(size) && (size) <= BITS_PER_LONG ?       \
  (__scanbit(~*(const unsigned long *)addr, size)) :            \
  __find_first_zero_bit(addr,size)))

/**
 * find_next_zero_bit - find the first zero bit in a memory region
 * @addr: The address to base the search on
 * @offset: The bitnumber to start searching at
 * @size: The maximum size to search
 */
#define find_next_zero_bit(addr,size,off)                                   \
((__builtin_constant_p(size) && (size) <= BITS_PER_LONG ?                   \
  ((off)+(__scanbit(~(((*(const unsigned long *)addr)) >> (off)), size))) : \
  __find_next_zero_bit(addr,size,off)))


/**
 * find_first_set_bit - find the first set bit in @word
 * @word: the word to search
 * 
 * Returns the bit-number of the first set bit. The input must *not* be zero.
 */
static inline unsigned int find_first_set_bit(unsigned long word)
{
    asm ( "bsf %1,%0" : "=r" (word) : "r" (word) );
    return (unsigned int)word;
}

/**
 * ffs - find first bit set
 * @x: the word to search
 *
 * This is defined the same way as the libc and compiler builtin ffs routines.
 */
static inline int ffs(unsigned long x)
{
    long r;

    asm ( "bsf %1,%0\n\t"
          "jnz 1f\n\t"
          "mov $-1,%0\n"
          "1:" : "=r" (r) : "rm" (x));
    return (int)r+1;
}

/**
 * fls - find last bit set
 * @x: the word to search
 *
 * This is defined the same way as ffs.
 */
static inline int fls(unsigned long x)
{
    long r;

    asm ( "bsr %1,%0\n\t"
          "jnz 1f\n\t"
          "mov $-1,%0\n"
          "1:" : "=r" (r) : "rm" (x));
    return (int)r+1;
}

/**
 * hweightN - returns the hamming weight of a N-bit word
 * @x: the word to weigh
 *
 * The Hamming Weight of a number is the total number of bits set in it.
 */
#define hweight64(x) generic_hweight64(x)
#define hweight32(x) generic_hweight32(x)
#define hweight16(x) generic_hweight16(x)
#define hweight8(x) generic_hweight8(x)

#endif /* _X86_BITOPS_H */

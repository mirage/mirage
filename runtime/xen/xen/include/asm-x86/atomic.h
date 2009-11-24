#ifndef __ARCH_X86_ATOMIC__
#define __ARCH_X86_ATOMIC__

#include <xen/config.h>
#include <asm/system.h>

#ifdef CONFIG_SMP
#define LOCK "lock ; "
#else
#define LOCK ""
#endif

/*
 * NB. I've pushed the volatile qualifier into the operations. This allows
 * fast accessors such as _atomic_read() and _atomic_set() which don't give
 * the compiler a fit.
 */
typedef struct { int counter; } atomic_t;

#define ATOMIC_INIT(i)	{ (i) }

/**
 * atomic_read - read atomic variable
 * @v: pointer of type atomic_t
 * 
 * Atomically reads the value of @v.
 */
#define _atomic_read(v)		((v).counter)
#define atomic_read(v)		(*(volatile int *)&((v)->counter))

/**
 * atomic_set - set atomic variable
 * @v: pointer of type atomic_t
 * @i: required value
 * 
 * Atomically sets the value of @v to @i.
 */ 
#define _atomic_set(v,i)	(((v).counter) = (i))
#define atomic_set(v,i)		(*(volatile int *)&((v)->counter) = (i))

/**
 * atomic_add - add integer to atomic variable
 * @i: integer value to add
 * @v: pointer of type atomic_t
 * 
 * Atomically adds @i to @v.
 */
static __inline__ void atomic_add(int i, atomic_t *v)
{
	asm volatile(
		LOCK "addl %1,%0"
		:"=m" (*(volatile int *)&v->counter)
		:"ir" (i), "m" (*(volatile int *)&v->counter));
}

/**
 * atomic_sub - subtract the atomic variable
 * @i: integer value to subtract
 * @v: pointer of type atomic_t
 * 
 * Atomically subtracts @i from @v.
 */
static __inline__ void atomic_sub(int i, atomic_t *v)
{
	asm volatile(
		LOCK "subl %1,%0"
		:"=m" (*(volatile int *)&v->counter)
		:"ir" (i), "m" (*(volatile int *)&v->counter));
}

/**
 * atomic_sub_and_test - subtract value from variable and test result
 * @i: integer value to subtract
 * @v: pointer of type atomic_t
 * 
 * Atomically subtracts @i from @v and returns
 * true if the result is zero, or false for all
 * other cases.
 */
static __inline__ int atomic_sub_and_test(int i, atomic_t *v)
{
	unsigned char c;

	asm volatile(
		LOCK "subl %2,%0; sete %1"
		:"=m" (*(volatile int *)&v->counter), "=qm" (c)
		:"ir" (i), "m" (*(volatile int *)&v->counter) : "memory");
	return c;
}

/**
 * atomic_inc - increment atomic variable
 * @v: pointer of type atomic_t
 * 
 * Atomically increments @v by 1.
 */ 
static __inline__ void atomic_inc(atomic_t *v)
{
	asm volatile(
		LOCK "incl %0"
		:"=m" (*(volatile int *)&v->counter)
		:"m" (*(volatile int *)&v->counter));
}

/**
 * atomic_dec - decrement atomic variable
 * @v: pointer of type atomic_t
 * 
 * Atomically decrements @v by 1.
 */ 
static __inline__ void atomic_dec(atomic_t *v)
{
	asm volatile(
		LOCK "decl %0"
		:"=m" (*(volatile int *)&v->counter)
		:"m" (*(volatile int *)&v->counter));
}

/**
 * atomic_dec_and_test - decrement and test
 * @v: pointer of type atomic_t
 * 
 * Atomically decrements @v by 1 and
 * returns true if the result is 0, or false for all other
 * cases.
 */ 
static __inline__ int atomic_dec_and_test(atomic_t *v)
{
	unsigned char c;

	asm volatile(
		LOCK "decl %0; sete %1"
		:"=m" (*(volatile int *)&v->counter), "=qm" (c)
		:"m" (*(volatile int *)&v->counter) : "memory");
	return c != 0;
}

/**
 * atomic_inc_and_test - increment and test 
 * @v: pointer of type atomic_t
 * 
 * Atomically increments @v by 1
 * and returns true if the result is zero, or false for all
 * other cases.
 */ 
static __inline__ int atomic_inc_and_test(atomic_t *v)
{
	unsigned char c;

	asm volatile(
		LOCK "incl %0; sete %1"
		:"=m" (*(volatile int *)&v->counter), "=qm" (c)
		:"m" (*(volatile int *)&v->counter) : "memory");
	return c != 0;
}

/**
 * atomic_add_negative - add and test if negative
 * @v: pointer of type atomic_t
 * @i: integer value to add
 * 
 * Atomically adds @i to @v and returns true
 * if the result is negative, or false when
 * result is greater than or equal to zero.
 */ 
static __inline__ int atomic_add_negative(int i, atomic_t *v)
{
	unsigned char c;

	asm volatile(
		LOCK "addl %2,%0; sets %1"
		:"=m" (*(volatile int *)&v->counter), "=qm" (c)
		:"ir" (i), "m" (*(volatile int *)&v->counter) : "memory");
	return c;
}

static __inline__ atomic_t atomic_compareandswap(
	atomic_t old, atomic_t new, atomic_t *v)
{
	atomic_t rc;
	rc.counter = 
		__cmpxchg(&v->counter, old.counter, new.counter, sizeof(int));
	return rc;
}

/* Atomic operations are already serializing on x86 */
#define smp_mb__before_atomic_dec()	barrier()
#define smp_mb__after_atomic_dec()	barrier()
#define smp_mb__before_atomic_inc()	barrier()
#define smp_mb__after_atomic_inc()	barrier()

#endif /* __ARCH_X86_ATOMIC__ */

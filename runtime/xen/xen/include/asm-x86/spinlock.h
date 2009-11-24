#ifndef __ASM_SPINLOCK_H
#define __ASM_SPINLOCK_H

#include <xen/config.h>
#include <xen/lib.h>
#include <asm/atomic.h>

typedef struct {
    volatile s16 lock;
} raw_spinlock_t;

#define _RAW_SPIN_LOCK_UNLOCKED /*(raw_spinlock_t)*/ { 1 }

#define _raw_spin_is_locked(x) ((x)->lock <= 0)

static always_inline void _raw_spin_unlock(raw_spinlock_t *lock)
{
    ASSERT(_raw_spin_is_locked(lock));
    asm volatile (
        "movw $1,%0" 
        : "=m" (lock->lock) : : "memory" );
}

static always_inline int _raw_spin_trylock(raw_spinlock_t *lock)
{
    s16 oldval;
    asm volatile (
        "xchgw %w0,%1"
        :"=r" (oldval), "=m" (lock->lock)
        :"0" (0) : "memory" );
    return (oldval > 0);
}

typedef struct {
    volatile int lock;
} raw_rwlock_t;

#define RW_LOCK_BIAS 0x01000000
#define _RAW_RW_LOCK_UNLOCKED /*(raw_rwlock_t)*/ { RW_LOCK_BIAS }

static always_inline void _raw_read_lock(raw_rwlock_t *rw)
{
    asm volatile (
        "1:  lock; decl %0         \n"
        "    jns 3f                \n"
        "    lock; incl %0         \n"
        "2:  rep; nop              \n"
        "    cmpl $1,%0            \n"
        "    js 2b                 \n"
        "    jmp 1b                \n"
        "3:"
        : "=m" (rw->lock) : : "memory" );
}

static always_inline void _raw_write_lock(raw_rwlock_t *rw)
{
    asm volatile (
        "1:  lock; subl %1,%0      \n"
        "    jz 3f                 \n"
        "    lock; addl %1,%0      \n"
        "2:  rep; nop              \n"
        "    cmpl %1,%0            \n"
        "    jne 2b                \n"
        "    jmp 1b                \n"
        "3:"
        : "=m" (rw->lock) : "i" (RW_LOCK_BIAS) : "memory" );
}

static always_inline int _raw_write_trylock(raw_rwlock_t *rw)
{
    int rc;

    asm volatile (
        "    lock; subl %2,%0      \n"
        "    jz 1f                 \n"
        "    lock; addl %2,%0      \n"
        "    dec %1                \n"
        "1:"
        : "=m" (rw->lock), "=r" (rc) : "i" (RW_LOCK_BIAS), "1" (1)
        : "memory" );

    return rc;
}

static always_inline void _raw_read_unlock(raw_rwlock_t *rw)
{
    asm volatile (
        "lock ; incl %0"
        : "=m" ((rw)->lock) : : "memory" );
}

static always_inline void _raw_write_unlock(raw_rwlock_t *rw)
{
    asm volatile (
        "lock ; addl %1,%0"
        : "=m" ((rw)->lock) : "i" (RW_LOCK_BIAS) : "memory" );
}

#define _raw_rw_is_locked(x) ((x)->lock < RW_LOCK_BIAS)
#define _raw_rw_is_write_locked(x) ((x)->lock <= 0)

#endif /* __ASM_SPINLOCK_H */

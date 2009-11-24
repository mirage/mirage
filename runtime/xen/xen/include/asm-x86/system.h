#ifndef __ASM_SYSTEM_H
#define __ASM_SYSTEM_H

#include <xen/lib.h>
#include <asm/bitops.h>

#define read_segment_register(name)                             \
({  u16 __sel;                                                  \
    asm volatile ( "movw %%" STR(name) ",%0" : "=r" (__sel) );  \
    __sel;                                                      \
})

#define wbinvd() \
    asm volatile ( "wbinvd" : : : "memory" )

#define clflush(a) \
    asm volatile ( "clflush (%0)" : : "r"(a) )

#define nop() \
    asm volatile ( "nop" )

#define xchg(ptr,v) \
    ((__typeof__(*(ptr)))__xchg((unsigned long)(v),(ptr),sizeof(*(ptr))))

struct __xchg_dummy { unsigned long a[100]; };
#define __xg(x) ((volatile struct __xchg_dummy *)(x))

#if defined(__i386__)
# include <asm/x86_32/system.h>
#elif defined(__x86_64__)
# include <asm/x86_64/system.h>
#endif

/*
 * Note: no "lock" prefix even on SMP: xchg always implies lock anyway
 * Note 2: xchg has side effect, so that attribute volatile is necessary,
 *   but generally the primitive is invalid, *ptr is output argument. --ANK
 */
static always_inline unsigned long __xchg(
    unsigned long x, volatile void *ptr, int size)
{
    switch ( size )
    {
    case 1:
        asm volatile ( "xchgb %b0,%1"
                       : "=q" (x)
                       : "m" (*__xg((volatile void *)ptr)), "0" (x)
                       : "memory" );
        break;
    case 2:
        asm volatile ( "xchgw %w0,%1"
                       : "=r" (x)
                       : "m" (*__xg((volatile void *)ptr)), "0" (x)
                       : "memory" );
        break;
#if defined(__i386__)
    case 4:
        asm volatile ( "xchgl %0,%1"
                       : "=r" (x)
                       : "m" (*__xg((volatile void *)ptr)), "0" (x)
                       : "memory" );
        break;
#elif defined(__x86_64__)
    case 4:
        asm volatile ( "xchgl %k0,%1"
                       : "=r" (x)
                       : "m" (*__xg((volatile void *)ptr)), "0" (x)
                       : "memory" );
        break;
    case 8:
        asm volatile ( "xchgq %0,%1"
                       : "=r" (x)
                       : "m" (*__xg((volatile void *)ptr)), "0" (x)
                       : "memory" );
        break;
#endif
    }
    return x;
}

/*
 * Atomic compare and exchange.  Compare OLD with MEM, if identical,
 * store NEW in MEM.  Return the initial value in MEM.  Success is
 * indicated by comparing RETURN with OLD.
 */

static always_inline unsigned long __cmpxchg(
    volatile void *ptr, unsigned long old, unsigned long new, int size)
{
    unsigned long prev;
    switch ( size )
    {
    case 1:
        asm volatile ( LOCK_PREFIX "cmpxchgb %b1,%2"
                       : "=a" (prev)
                       : "q" (new), "m" (*__xg((volatile void *)ptr)),
                       "0" (old)
                       : "memory" );
        return prev;
    case 2:
        asm volatile ( LOCK_PREFIX "cmpxchgw %w1,%2"
                       : "=a" (prev)
                       : "r" (new), "m" (*__xg((volatile void *)ptr)),
                       "0" (old)
                       : "memory" );
        return prev;
#if defined(__i386__)
    case 4:
        asm volatile ( LOCK_PREFIX "cmpxchgl %1,%2"
                       : "=a" (prev)
                       : "r" (new), "m" (*__xg((volatile void *)ptr)),
                       "0" (old)
                       : "memory" );
        return prev;
#elif defined(__x86_64__)
    case 4:
        asm volatile ( LOCK_PREFIX "cmpxchgl %k1,%2"
                       : "=a" (prev)
                       : "r" (new), "m" (*__xg((volatile void *)ptr)),
                       "0" (old)
                       : "memory" );
        return prev;
    case 8:
        asm volatile ( LOCK_PREFIX "cmpxchgq %1,%2"
                       : "=a" (prev)
                       : "r" (new), "m" (*__xg((volatile void *)ptr)),
                       "0" (old)
                       : "memory" );
        return prev;
#endif
    }
    return old;
}

#define __HAVE_ARCH_CMPXCHG

/*
 * Both Intel and AMD agree that, from a programmer's viewpoint:
 *  Loads cannot be reordered relative to other loads.
 *  Stores cannot be reordered relative to other stores.
 * 
 * Intel64 Architecture Memory Ordering White Paper
 * <http://developer.intel.com/products/processor/manuals/318147.pdf>
 * 
 * AMD64 Architecture Programmer's Manual, Volume 2: System Programming
 * <http://www.amd.com/us-en/assets/content_type/\
 *  white_papers_and_tech_docs/24593.pdf>
 */
#define rmb()           barrier()
#define wmb()           barrier()

#ifdef CONFIG_SMP
#define smp_mb()        mb()
#define smp_rmb()       rmb()
#define smp_wmb()       wmb()
#else
#define smp_mb()        barrier()
#define smp_rmb()       barrier()
#define smp_wmb()       barrier()
#endif

#define set_mb(var, value) do { xchg(&var, value); } while (0)
#define set_wmb(var, value) do { var = value; wmb(); } while (0)

#define local_irq_disable()     asm volatile ( "cli" : : : "memory" )
#define local_irq_enable()      asm volatile ( "sti" : : : "memory" )

/* used in the idle loop; sti takes one instruction cycle to complete */
#define safe_halt()     asm volatile ( "sti; hlt" : : : "memory" )
/* used when interrupts are already enabled or to shutdown the processor */
#define halt()          asm volatile ( "hlt" : : : "memory" )

#define local_save_flags(x)                                      \
({                                                               \
    BUILD_BUG_ON(sizeof(x) != sizeof(long));                     \
    asm volatile ( "pushf" __OS " ; pop" __OS " %0" : "=g" (x)); \
})
#define local_irq_save(x)                                        \
({                                                               \
    local_save_flags(x);                                         \
    local_irq_disable();                                         \
})
#define local_irq_restore(x)                                     \
({                                                               \
    BUILD_BUG_ON(sizeof(x) != sizeof(long));                     \
    asm volatile ( "push" __OS " %0 ; popf" __OS                 \
                   : : "g" (x) : "memory", "cc" );               \
})

static inline int local_irq_is_enabled(void)
{
    unsigned long flags;
    local_save_flags(flags);
    return !!(flags & (1<<9)); /* EFLAGS_IF */
}

#define BROKEN_ACPI_Sx          0x0001
#define BROKEN_INIT_AFTER_S1    0x0002

void trap_init(void);
void percpu_traps_init(void);
void subarch_percpu_traps_init(void);

#endif

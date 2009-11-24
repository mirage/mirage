#ifndef __ASM_APIC_H
#define __ASM_APIC_H

#include <xen/config.h>
#include <asm/apicdef.h>
#include <asm/fixmap.h>
#include <asm/system.h>

#define Dprintk(x...)

/*
 * Debugging macros
 */
#define APIC_QUIET   0
#define APIC_VERBOSE 1
#define APIC_DEBUG   2

#define	SET_APIC_LOGICAL_ID(x)	(((x)<<24))

#define IO_APIC_REDIR_VECTOR_MASK	0x000FF
#define IO_APIC_REDIR_DEST_LOGICAL	0x00800
#define IO_APIC_REDIR_DEST_PHYSICAL	0x00000

extern int apic_verbosity;
extern int x2apic_enabled;

extern void enable_x2apic(void);

static __inline int x2apic_is_available(void)
{
    unsigned int op = 1, eax, ecx;

    asm ( "cpuid"
          : "=a" (eax), "=c" (ecx)
          : "0" (op)
          : "bx", "dx" );

    return (ecx & (1U << 21));
}

/*
 * Define the default level of output to be very little
 * This can be turned up by using apic=verbose for more
 * information and apic=debug for _lots_ of information.
 * apic_verbosity is defined in apic.c
 */
#define apic_printk(v, s, a...) do {       \
		if ((v) <= apic_verbosity) \
			printk(s, ##a);    \
	} while (0)


#ifdef CONFIG_X86_LOCAL_APIC

/*
 * Basic functions accessing APICs.
 */

static __inline void apic_mem_write(unsigned long reg, u32 v)
{
	*((volatile u32 *)(APIC_BASE+reg)) = v;
}

static __inline void apic_mem_write_atomic(unsigned long reg, u32 v)
{
	(void)xchg((volatile u32 *)(APIC_BASE+reg), v);
}

static __inline u32 apic_mem_read(unsigned long reg)
{
	return *((volatile u32 *)(APIC_BASE+reg));
}

/* NOTE: in x2APIC mode, we should use apic_icr_write()/apic_icr_read() to
 * access the 64-bit ICR register.
 */

static __inline void apic_wrmsr(unsigned long reg, u32 low, u32 high)
{
    if (reg == APIC_DFR || reg == APIC_ID || reg == APIC_LDR ||
        reg == APIC_LVR)
        return;

    __asm__ __volatile__("wrmsr"
            : /* no outputs */
            : "c" (APIC_MSR_BASE + (reg >> 4)), "a" (low), "d" (high));
}

static __inline void apic_rdmsr(unsigned long reg, u32 *low, u32 *high)
{
    if (reg == APIC_DFR)
    {
        *low = *high = -1u;
        return;
    }
    __asm__ __volatile__("rdmsr"
            : "=a" (*low), "=d" (*high)
            : "c" (APIC_MSR_BASE + (reg >> 4)));
}

static __inline void apic_write(unsigned long reg, u32 v)
{

    if ( x2apic_enabled )
        apic_wrmsr(reg, v, 0);
    else
        apic_mem_write(reg, v);
}

static __inline void apic_write_atomic(unsigned long reg, u32 v)
{
    if ( x2apic_enabled )
        apic_wrmsr(reg, v, 0);
    else
        apic_mem_write_atomic(reg, v);
}

static __inline u32 apic_read(unsigned long reg)
{
    u32 lo, hi;

    if ( x2apic_enabled )
        apic_rdmsr(reg, &lo, &hi);
    else
        lo = apic_mem_read(reg);
    return lo;
}

static __inline u64 apic_icr_read(void)
{
    u32 lo, hi;

    if ( x2apic_enabled )
        apic_rdmsr(APIC_ICR, &lo, &hi);
    else
    {
        lo = apic_mem_read(APIC_ICR);
        hi = apic_mem_read(APIC_ICR2);
    }
    
    return ((u64)lo) | (((u64)hi) << 32);
}

static __inline void apic_icr_write(u32 low, u32 dest)
{
    if ( x2apic_enabled )
        apic_wrmsr(APIC_ICR, low, dest);
    else
    {
        apic_mem_write(APIC_ICR2, dest << 24);
        apic_mem_write(APIC_ICR, low);
    }
}

static __inline u32 get_apic_id(void) /* Get the physical APIC id */
{
    u32 id = apic_read(APIC_ID);
    return x2apic_enabled ? id : GET_xAPIC_ID(id);
}

static __inline u32 get_logical_apic_id(void)
{
    u32 logical_id = apic_read(APIC_LDR);
    return x2apic_enabled ? logical_id : GET_xAPIC_LOGICAL_ID(logical_id);
}

void apic_wait_icr_idle(void);

int get_physical_broadcast(void);

#ifdef CONFIG_X86_GOOD_APIC
# define FORCE_READ_AROUND_WRITE 0
# define apic_read_around(x)
# define apic_write_around(x,y) apic_write((x),(y))
#else
# define FORCE_READ_AROUND_WRITE 1
# define apic_read_around(x) apic_read(x)
# define apic_write_around(x,y) apic_write_atomic((x),(y))
#endif

static inline void ack_APIC_irq(void)
{
	/*
	 * ack_APIC_irq() actually gets compiled as a single instruction:
	 * - a single rmw on Pentium/82489DX
	 * - a single write on P6+ cores (CONFIG_X86_GOOD_APIC)
	 * ... yummie.
	 */

	/* Docs say use 0 for future compatibility */
	apic_write_around(APIC_EOI, 0);
}

extern void (*wait_timer_tick)(void);

extern int get_maxlvt(void);
extern void clear_local_APIC(void);
extern void connect_bsp_APIC (void);
extern void disconnect_bsp_APIC (int virt_wire_setup);
extern void disable_local_APIC (void);
extern void lapic_shutdown (void);
extern int verify_local_APIC (void);
extern void cache_APIC_registers (void);
extern void sync_Arb_IDs (void);
extern void init_bsp_APIC (void);
extern void setup_local_APIC (void);
extern void init_apic_mappings (void);
extern void smp_local_timer_interrupt (struct cpu_user_regs *regs);
extern void setup_boot_APIC_clock (void);
extern void setup_secondary_APIC_clock (void);
extern void setup_apic_nmi_watchdog (void);
extern int reserve_lapic_nmi(void);
extern void release_lapic_nmi(void);
extern void self_nmi(void);
extern void disable_timer_nmi_watchdog(void);
extern void enable_timer_nmi_watchdog(void);
extern void nmi_watchdog_tick (struct cpu_user_regs *regs);
extern int APIC_init_uniprocessor (void);
extern void disable_APIC_timer(void);
extern void enable_APIC_timer(void);
extern int lapic_suspend(void);
extern int lapic_resume(void);

extern int check_nmi_watchdog (void);
extern void enable_NMI_through_LVT0 (void * dummy);

extern void watchdog_disable(void);
extern void watchdog_enable(void);

extern unsigned int nmi_watchdog;
#define NMI_NONE	0
#define NMI_IO_APIC	1
#define NMI_LOCAL_APIC	2
#define NMI_INVALID	3

#else /* !CONFIG_X86_LOCAL_APIC */
static inline void lapic_shutdown(void) { }
static inline int lapic_suspend(void) {return 0;}
static inline int lapic_resume(void) {return 0;}

#endif /* !CONFIG_X86_LOCAL_APIC */

#endif /* __ASM_APIC_H */

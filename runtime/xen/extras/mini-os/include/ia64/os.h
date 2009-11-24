/*
 * Copyright (C) 2007 - Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 *
 ****************************************************************************
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 * DEALINGS IN THE SOFTWARE.
 */


#if !defined(__OS_H__)
#define __OS_H__

#if !defined(__ASSEMBLY__)

#include <mini-os/types.h>
#include "ia64_cpu.h"
#include "atomic.h"
#include "efi.h"
#include "sal.h"
#include "pal.h"
#include <mini-os/hypervisor.h>
#include <mini-os/kernel.h>


typedef uint64_t paddr_t;		/* Physical address. */
#ifndef HAVE_LIBC
typedef uint64_t caddr_t;		/* rr7/kernel memory address. */
#endif

#include "page.h"
#include "mm.h"


void arch_init(start_info_t *si);	/* in common.c */
void arch_print_info(void);		/* in common.c */
void arch_fini(void);


/* Size of xen_ia64_boot_param.command_line */
#define COMMAND_LINE_SIZE       512

extern struct xen_ia64_boot_param* ia64_boot_paramP;
extern struct xen_ia64_boot_param ia64BootParamG;
extern char boot_cmd_line[];
extern efi_system_table_t* efiSysTableP;
extern int bootverbose;

extern void ia64_probe_sapics(void);



/* Contains the needed stuff from efi. */
struct efi
{

	efi_system_table_t*		efiSysTableP;
	efi_set_virtual_address_map_t	setVirtAddrMapF;
	efi_get_time_t			getTimeF;
	efi_reset_system_t		resetSystemF;

};

struct machine_fw
{
	struct efi efi;

	uint64_t ia64_port_base;	/* physical address */
	uint64_t ia64_pal_base;		/* virtual rr7 address */

	sal_system_table_t* ia64_sal_tableP;
	sal_entry_t* ia64_sal_entryP;	/* SAL_PROC entrypoint */

	uint64_t ia64_efi_acpi_table;	/* physical address */
	uint64_t ia64_efi_acpi20_table;	/* physical address */

	uint64_t mach_mem_start;	/* phys start addr of machine memory */
	uint64_t mach_mem_size;		/* size of machine memory */

	uint64_t kernstart;		/* virt address of kern text start */
	uint64_t kernend;
	uint64_t kernpstart;		/* phys address of kern text start */
	uint64_t kernpend;
};

extern struct machine_fw machineFwG;

#define ia64_sal_entry machineFwG.ia64_sal_entryP

#define smp_processor_id() 0

static inline uint64_t
xchg8(uint64_t* ptr, uint64_t x)                                               \
{
        uint64_t oldVal;
        asm volatile ("xchg8 %0=[%1],%2" : "=r" (oldVal)
                      : "r" (ptr), "r" (x) : "memory");
        return oldVal;
}
#define xchg xchg8

// Counts the number of 1-bits in x.
#if __GNUC__ >= 4 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 4)
# define get_popcnt(x)         __builtin_popcountl(x)
#else
# define get_popcnt(x)					\
  ({							\
	uint64_t num;					\
	asm ("popcnt %0=%1" : "=r" (num) : "r" (x));	\
	num;						\
  })
#endif

/**
 * __ffs - find first bit in word.
 * @x: The word to search
 *
 * Undefined if no bit exists, so code should check against 0 first.
 */
static inline unsigned long
__ffs (unsigned long x)
{
	unsigned long result;

	result = get_popcnt((x-1) & ~x);
	return result;
}


static inline void
synch_clear_bit(int num, volatile void *addr)
{
	clear_bit(num, addr);
}

static inline void
synch_set_bit(int num, volatile void *addr)
{
	set_bit(num, addr);
}

static inline int
synch_test_bit(int nr, const volatile void *addr)
{
	return test_bit(nr, addr);
}

static inline int
synch_test_and_set_bit(int num, volatile void * addr)
{
	return test_and_set_bit(num, addr);
}


#define synch_cmpxchg(ptr, old, new) \
((__typeof__(*(ptr)))__synch_cmpxchg((ptr),\
                                     (unsigned long)(old), \
                                     (unsigned long)(new), \
                                     sizeof(*(ptr))))

static inline unsigned long
__synch_cmpxchg(volatile void *ptr, uint64_t old, uint64_t new, int size)
{
	switch (size)
	{
		case 1:
			return ia64_cmpxchg_acq_8(ptr, old, new);
		case 2:
			return ia64_cmpxchg_acq_16(ptr, old, new);
		case 4:
			return ia64_cmpxchg_acq_32(ptr, old, new);
		case 8:
			return ia64_cmpxchg_acq_64(ptr, old, new);
	}
	return ia64_cmpxchg_acq_64(ptr, old, new);
}

extern shared_info_t *HYPERVISOR_shared_info;


/*
 * This code is from the originally os.h and should be put in a
 * common header file!
 */

/* 
 * The use of 'barrier' in the following reflects their use as local-lock
 * operations. Reentrancy must be prevented (e.g., __cli()) /before/ following
 * critical operations are executed. All critical operations must complete
 * /before/ reentrancy is permitted (e.g., __sti()). Alpha architecture also
 * includes these barriers, for example.
 */

#define __cli()								\
do {									\
	vcpu_info_t *_vcpu;						\
	_vcpu = &HYPERVISOR_shared_info->vcpu_info[smp_processor_id()];	\
	_vcpu->evtchn_upcall_mask = 1;					\
	barrier();							\
} while (0)

#define __sti()								\
do {									\
	vcpu_info_t *_vcpu;						\
	barrier();							\
	_vcpu = &HYPERVISOR_shared_info->vcpu_info[smp_processor_id()];	\
	_vcpu->evtchn_upcall_mask = 0;					\
	barrier(); /* unmask then check (avoid races) */		\
	if (unlikely(_vcpu->evtchn_upcall_pending))			\
		force_evtchn_callback();				\
} while (0)

#define __save_flags(x)							\
do {									\
	vcpu_info_t *_vcpu;						\
	_vcpu = &HYPERVISOR_shared_info->vcpu_info[smp_processor_id()];	\
	(x) = _vcpu->evtchn_upcall_mask;				\
} while (0)

#define __restore_flags(x)						\
do {									\
	vcpu_info_t *_vcpu;						\
	barrier();							\
	_vcpu = &HYPERVISOR_shared_info->vcpu_info[smp_processor_id()];	\
	if ((_vcpu->evtchn_upcall_mask = (x)) == 0) {			\
		barrier(); /* unmask then check (avoid races) */	\
		if ( unlikely(_vcpu->evtchn_upcall_pending) )		\
			force_evtchn_callback();			\
	}\
} while (0)

#define safe_halt()		((void)0)

#define __save_and_cli(x)						\
do {									\
	vcpu_info_t *_vcpu;						\
	_vcpu = &HYPERVISOR_shared_info->vcpu_info[smp_processor_id()];	\
	(x) = _vcpu->evtchn_upcall_mask;				\
	_vcpu->evtchn_upcall_mask = 1;					\
	barrier();							\
} while (0)

#define local_irq_save(x)	__save_and_cli(x)
#define local_irq_restore(x)	__restore_flags(x)
#define local_save_flags(x)	__save_flags(x)
#define local_irq_disable()	__cli()
#define local_irq_enable()	__sti()

#define irqs_disabled()			\
	(HYPERVISOR_shared_info->vcpu_info[smp_processor_id()].evtchn_upcall_mask)

/* This is a barrier for the compiler only, NOT the processor! */
#define barrier() __asm__ __volatile__("": : :"memory")

#define mb()	ia64_mf()
#define rmb()	mb()
#define wmb()	mb()


#define BUG()	\
	{ printk("mini-os BUG at %s:%d!\n", __FILE__, __LINE__); do_exit(); }

#define PRINT_BV(_fmt, _params...)		\
	if (bootverbose)			\
		printk(_fmt , ## _params)

#endif /* !defined(__ASSEMBLY__) */

#if defined(__ASSEMBLY__)

#define UL_CONST(x)	x
#define UL_TYPE(x)	x

#else /* defined(__ASSEMBLY__) */

#define UL_CONST(x)	x##UL
#define UL_TYPE(x)	((uint64_t)x)

#endif /* defined(__ASSEMBLY__) */

#endif /* !defined(__OS_H__) */

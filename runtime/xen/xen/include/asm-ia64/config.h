#ifndef	_IA64_CONFIG_H_
#define _IA64_CONFIG_H_

#undef DEBUG_PFMON

// manufactured from component pieces

// defined in linux/arch/ia64/defconfig
#define	CONFIG_IA64_GENERIC
#define CONFIG_HZ	32

#define	CONFIG_IA64_L1_CACHE_SHIFT 7
// needed by include/asm-ia64/page.h
#define	CONFIG_IA64_PAGE_SIZE_16KB	// 4KB doesn't work?!?
#define	CONFIG_IA64_GRANULE_16MB

// this needs to be on to run on system with large memory hole
#define	CONFIG_VIRTUAL_FRAME_TABLE

#define CONFIG_EFI
#define CONFIG_EFI_PCDP
#define CONFIG_SERIAL_SGI_L1_CONSOLE

#define CONFIG_XEN_SMP

#ifdef CONFIG_XEN_SMP
#define CONFIG_SMP 1
#define CONFIG_HOTPLUG_CPU 1
#ifdef MAX_PHYS_CPUS
#define NR_CPUS MAX_PHYS_CPUS
#else
#define NR_CPUS 64
#endif
#define MAX_VIRT_CPUS XEN_LEGACY_MAX_VCPUS
#define MAX_HVM_VCPUS MAX_VIRT_CPUS
#define CONFIG_NUMA
#define CONFIG_ACPI_NUMA
#define NODES_SHIFT 8				/* linux/asm/numnodes.h */
#define NR_NODE_MEMBLKS (MAX_NUMNODES*2)	/* linux-xen/asm/acpi.h */
#else
#undef CONFIG_SMP
#define NR_CPUS 1
#endif
#define CONFIG_NR_CPUS NR_CPUS

#define CONFIG_IOSAPIC
#define supervisor_mode_kernel (0)

#define PADDR_BITS	48

/* If PERFC is used, include privop maps.  */
#ifdef PERF_COUNTERS
#define CONFIG_PRIVOP_ADDRS
#define PRIVOP_COUNT_NADDRS 30
#endif

#define CONFIG_VGA 1


#define NR_hypercalls 64

/* PV domains use this value for priv. level 0 emulation */
#define CONFIG_CPL0_EMUL	1

#ifndef __ASSEMBLY__

// can't find where this typedef was before?!?
// needed by include/asm-ia64/processor.h (and other places)
typedef int pid_t;

// now needed for xen/include/mm.h
typedef unsigned long paddr_t;
#define INVALID_PADDR (~0UL)
// from include/linux/kernel.h
#define ALIGN(x,a) (((x)+(a)-1)&~((a)-1))

//////////////////////////////////////

#define FASTCALL(x) x	// see linux/include/linux/linkage.h
#define fastcall	// " "

#define watchdog_disable() ((void)0)
#define watchdog_enable()  ((void)0)
// from linux/include/linux/types.h
#define CLEAR_BITMAP(name,bits) \
	memset(name, 0, BITS_TO_LONGS(bits)*sizeof(unsigned long))

// FIXME?: x86-ism used in xen/mm.h
#define LOCK_PREFIX

extern unsigned long total_pages;
extern unsigned long xen_pstart;
extern unsigned long xenheap_size;

extern int running_on_sim;

// from linux/include/linux/mm.h
extern struct page_info *mem_map;

// xen/include/asm/config.h
extern char _end[]; /* standard ELF symbol */

// linux/include/linux/compiler.h
//#define __kernel
//#define __safe
#define __force
#define __chk_user_ptr(x) (void)0
//#define __chk_io_ptr(x) (void)0
//#define __builtin_warning(x, y...) (1)
//#define __acquires(x)
//#define __releases(x)
//#define __acquire(x) (void)0
//#define __release(x) (void)0
//#define __cond_lock(x) (x)
//#define __must_check
#define __deprecated

// xen/include/asm/config.h
//#define HZ 1000
// FIXME SMP: leave SMP for a later time
///////////////////////////////////////////////////////////////
// xen/include/asm/config.h
#define	ELFSIZE	64

///////////////////////////////////////////////////////////////

// get rid of difficult circular include dependency
#define CMPXCHG_BUGCHECK(v)
#define CMPXCHG_BUGCHECK_DECL

// from include/asm-ia64/smp.h
#define	get_cpu()	smp_processor_id()
#define put_cpu()	do {} while(0)
#define put_cpu_no_resched()	do{} while (0)

// needed for common/dom0_ops.c until hyperthreading is supported
#ifdef CONFIG_SMP
extern int smp_num_siblings;
#else
#define smp_num_siblings 1
#endif

// function calls; see decl in xen/include/xen/sched.h
#undef free_task_struct
#undef alloc_task_struct
#define get_thread_info(v) alloc_thread_info(v)

// avoid redefining task_t in asm/thread_info.h
#define task_t	struct domain

// avoid redefining task_struct in asm/current.h
#define task_struct vcpu

#include <xen/cache.h>
#ifndef CONFIG_SMP
#define __cacheline_aligned_in_smp
#else
#define __cacheline_aligned_in_smp __cacheline_aligned
#endif

#define ____cacheline_aligned __attribute__((__aligned__(SMP_CACHE_BYTES)))
#ifndef CONFIG_SMP
#define ____cacheline_aligned_in_smp
#else
#define ____cacheline_aligned_in_smp ____cacheline_aligned
#endif

#define CONFIG_PERFMON

#ifndef __ASSEMBLY__
#include "asm/types.h"	// for u64
#include "linux/linkage.h"	// for asmlinkage which is used by
                                // xen/include/acpi/acpixf.h
#endif

// warning: unless search_extable is declared, the return value gets
// truncated to 32-bits, causing a very strange error in privop handling
struct exception_table_entry;

const struct exception_table_entry *
search_extable(const struct exception_table_entry *first,
	       const struct exception_table_entry *last,
	       unsigned long value);
void sort_extable(struct exception_table_entry *start,
		  struct exception_table_entry *finish);
void sort_main_extable(void);

#define find_first_set_bit(x)	(ffs(x)-1)	// FIXME: Is this right???

// see drivers/char/console.c
#define	OPT_CONSOLE_STR "com1"

#define __nocast

// see include/asm-x86/atomic.h (different from standard linux)
#define _atomic_set(v,i) (((v).counter) = (i))
#define _atomic_read(v) ((v).counter)
#define atomic_compareandswap(old, new, v) ((atomic_t){ cmpxchg(v, _atomic_read(old), _atomic_read(new)) })

// Deprivated linux inf and put here for short time compatibility
#define kmalloc(s, t) xmalloc_bytes((s))
#define kfree(s) xfree((s))
#define kzalloc(size, flags) 				\
({							\
	unsigned char *mem;				\
	mem = (unsigned char *)xmalloc_bytes(size);	\
	if (mem)					\
		memset(mem, 0, size);			\
	(void *)mem;					\
})
#define kcalloc(n, size, flags)		kzalloc(n * size, flags)
#define alloc_bootmem_node(pg, size)	xmalloc_bytes(size)

// see common/keyhandler.c
#define	nop()	asm volatile ("nop 0")

// from include/linux/preempt.h (needs including from interrupt.h or smp.h)
#define preempt_enable()	do { } while (0)
#define preempt_disable()	do { } while (0)

// needed for include/xen/linuxtime.h
typedef s64 time_t;
typedef s64 suseconds_t;

// needed for include/linux/jiffies.h
typedef long clock_t;

// from include/linux/kernel.h, needed by jiffies.h
#define typecheck(type,x) \
({	type __dummy; \
	typeof(x) __dummy2; \
	(void)(&__dummy == &__dummy2); \
	1; \
})

// from include/linux/timex.h, needed by arch/ia64/time.c
#define	TIME_SOURCE_CPU 0

// used in common code
#define softirq_pending(cpu)	(cpu_data(cpu)->softirq_pending)

// dup'ed from signal.h to avoid changes to includes
#define	SA_SHIRQ	0x04000000
#define	SA_INTERRUPT	0x20000000

// needed for setup.c
extern unsigned long loops_per_jiffy;
extern char saved_command_line[];
struct screen_info { };
#define seq_printf(a,b...) printk(b)
//#define CONFIG_BLK_DEV_INITRD // needed to reserve memory for domain0

#define CONFIG_SHADOW	1

// xen/include/asm/config.h
/******************************************************************************
 * config.h
 * 
 * A Linux-style configuration list.
 */

#ifndef __XEN_IA64_CONFIG_H__
#define __XEN_IA64_CONFIG_H__

#undef CONFIG_X86

#define CONFIG_MCKINLEY

#undef CONFIG_X86_LOCAL_APIC
#undef CONFIG_X86_IO_APIC
#undef CONFIG_X86_L1_CACHE_SHIFT

//#ifndef CONFIG_IA64_HP_SIM
// looks like this is hard to turn off for Xen
#define CONFIG_ACPI 1
#define CONFIG_ACPI_BOOT 1
//#endif

#define CONFIG_XEN_ATTENTION_KEY 1
#endif /* __ASSEMBLY__ */
#endif /* __XEN_IA64_CONFIG_H__ */

/* Allow .serialize.data/instruction in asm files.
   Old as doesn't handle this.  */
#define HAVE_SERIALIZE_DIRECTIVE

/* Define CONFIG_PRIVIFY to support privified OS (deprecated).  */
#undef CONFIG_PRIVIFY

#define CONFIG_XENCOMM_MARK_DIRTY 1

#define ARCH_CRASH_SAVE_VMCOREINFO

#endif	/* _IA64_CONFIG_H_ */

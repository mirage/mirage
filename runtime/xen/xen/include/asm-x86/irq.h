#ifndef _ASM_HW_IRQ_H
#define _ASM_HW_IRQ_H

/* (C) 1992, 1993 Linus Torvalds, (C) 1997 Ingo Molnar */

#include <xen/config.h>
#include <asm/atomic.h>
#include <xen/cpumask.h>
#include <xen/smp.h>
#include <irq_vectors.h>
#include <asm/percpu.h>

#define IO_APIC_IRQ(irq)    (platform_legacy_irq(irq) ?    \
			     (1 << (irq)) & io_apic_irqs : \
			     (irq) < nr_irqs_gsi)
#define IO_APIC_VECTOR(irq) (irq_vector[irq])

#define MSI_IRQ(irq)       ((irq) >= nr_irqs_gsi && (irq) < nr_irqs)

#define LEGACY_VECTOR(irq)          ((irq) + FIRST_LEGACY_VECTOR)
#define LEGACY_IRQ_FROM_VECTOR(vec) ((vec) - FIRST_LEGACY_VECTOR)

#define irq_to_desc(irq)    (&irq_desc[irq])
#define irq_cfg(irq)        (&irq_cfg[irq])

#define MAX_GSI_IRQS PAGE_SIZE * 8
#define MAX_NR_IRQS (2 * MAX_GSI_IRQS)

struct irq_cfg {
        int  vector;
        cpumask_t domain;
        cpumask_t old_domain;
        unsigned move_cleanup_count;
        u8 move_in_progress : 1;
};

extern struct irq_cfg *irq_cfg;

typedef int vector_irq_t[NR_VECTORS];
DECLARE_PER_CPU(vector_irq_t, vector_irq);

extern u8 *irq_vector;

/*
 * Per-cpu current frame pointer - the location of the last exception frame on
 * the stack
 */
DECLARE_PER_CPU(struct cpu_user_regs *, __irq_regs);

static inline struct cpu_user_regs *get_irq_regs(void)
{
	return __get_cpu_var(__irq_regs);
}

static inline struct cpu_user_regs *set_irq_regs(struct cpu_user_regs *new_regs)
{
	struct cpu_user_regs *old_regs, **pp_regs = &__get_cpu_var(__irq_regs);

	old_regs = *pp_regs;
	*pp_regs = new_regs;
	return old_regs;
}


#define platform_legacy_irq(irq)	((irq) < 16)

fastcall void event_check_interrupt(void);
fastcall void invalidate_interrupt(void);
fastcall void call_function_interrupt(void);
fastcall void apic_timer_interrupt(void);
fastcall void error_interrupt(void);
fastcall void pmu_apic_interrupt(void);
fastcall void spurious_interrupt(void);
fastcall void thermal_interrupt(void);
fastcall void cmci_interrupt(void);
fastcall void irq_move_cleanup_interrupt(void);

fastcall void smp_event_check_interrupt(struct cpu_user_regs *regs);
fastcall void smp_invalidate_interrupt(void);
fastcall void smp_call_function_interrupt(struct cpu_user_regs *regs);
fastcall void smp_apic_timer_interrupt(struct cpu_user_regs *regs);
fastcall void smp_error_interrupt(struct cpu_user_regs *regs);
fastcall void smp_pmu_apic_interrupt(struct cpu_user_regs *regs);
fastcall void smp_spurious_interrupt(struct cpu_user_regs *regs);
fastcall void smp_thermal_interrupt(struct cpu_user_regs *regs);
fastcall void smp_cmci_interrupt(struct cpu_user_regs *regs);
fastcall void smp_irq_move_cleanup_interrupt(struct cpu_user_regs *regs);

asmlinkage void do_IRQ(struct cpu_user_regs *regs);

void disable_8259A_irq(unsigned int irq);
void enable_8259A_irq(unsigned int irq);
int i8259A_irq_pending(unsigned int irq);
void init_8259A(int aeoi);
int i8259A_suspend(void);
int i8259A_resume(void);

void setup_IO_APIC(void);
void disable_IO_APIC(void);
void print_IO_APIC(void);
void setup_ioapic_dest(void);

extern unsigned long io_apic_irqs;

extern atomic_t irq_err_count;
extern atomic_t irq_mis_count;

int pirq_shared(struct domain *d , int irq);

int map_domain_pirq(struct domain *d, int pirq, int irq, int type,
                           void *data);
int unmap_domain_pirq(struct domain *d, int pirq);
int get_free_pirq(struct domain *d, int type, int index);
void free_domain_pirqs(struct domain *d);

int  init_irq_data(void);

void clear_irq_vector(int irq);

int irq_to_vector(int irq);
int create_irq(void);
void destroy_irq(unsigned int irq);

struct irq_desc;
extern void irq_complete_move(struct irq_desc **descp);

extern struct irq_desc *irq_desc;

void lock_vector_lock(void);
void unlock_vector_lock(void);

void __setup_vector_irq(int cpu);

void move_native_irq(int irq);

int __assign_irq_vector(int irq, struct irq_cfg *cfg, cpumask_t mask);

int bind_irq_vector(int irq, int vector, cpumask_t domain);

void move_native_irq(int irq);

void move_masked_irq(int irq);

void irq_set_affinity(int irq, cpumask_t mask);

int check_irq_status(int irq);

#define domain_pirq_to_irq(d, pirq) ((d)->arch.pirq_irq[pirq])
#define domain_irq_to_pirq(d, irq) ((d)->arch.irq_pirq[irq])

#endif /* _ASM_HW_IRQ_H */

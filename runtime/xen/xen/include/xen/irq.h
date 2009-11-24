#ifndef __XEN_IRQ_H__
#define __XEN_IRQ_H__

#include <xen/config.h>
#include <xen/cpumask.h>
#include <xen/spinlock.h>
#include <xen/time.h>
#include <asm/regs.h>
#include <asm/hardirq.h>

struct irqaction {
    void (*handler)(int, void *, struct cpu_user_regs *);
    const char *name;
    void *dev_id;
    bool_t free_on_release;
};

/*
 * IRQ line status.
 */
#define IRQ_INPROGRESS	1	/* IRQ handler active - do not enter! */
#define IRQ_DISABLED	2	/* IRQ disabled - do not enter! */
#define IRQ_PENDING	4	/* IRQ pending - replay on enable */
#define IRQ_REPLAY	8	/* IRQ has been replayed but not acked yet */
#define IRQ_GUEST       16      /* IRQ is handled by guest OS(es) */
#define IRQ_GUEST_EOI_PENDING 32 /* IRQ was disabled, pending a guest EOI */
#define IRQ_MOVE_PENDING      64  /* IRQ is migrating to another CPUs */
#define IRQ_PER_CPU     256     /* IRQ is per CPU */

/* Special IRQ numbers. */
#define AUTO_ASSIGN_IRQ         (-1)
#define NEVER_ASSIGN_IRQ        (-2)
#define FREE_TO_ASSIGN_IRQ      (-3)

/*
 * Interrupt controller descriptor. This is all we need
 * to describe about the low-level hardware. 
 */
struct hw_interrupt_type {
    const char *typename;
    unsigned int (*startup)(unsigned int irq);
    void (*shutdown)(unsigned int irq);
    void (*enable)(unsigned int irq);
    void (*disable)(unsigned int irq);
    void (*ack)(unsigned int irq);
    void (*end)(unsigned int irq);
    void (*set_affinity)(unsigned int irq, cpumask_t mask);
};

typedef const struct hw_interrupt_type hw_irq_controller;

#include <asm/irq.h>

#ifdef NR_IRQS
# define nr_irqs NR_IRQS
# define nr_irqs_gsi NR_IRQS
#else
extern unsigned int nr_irqs_gsi;
extern unsigned int nr_irqs;
#endif

struct msi_desc;
struct irq_cfg;
/*
 * This is the "IRQ descriptor", which contains various information
 * about the irq, including what kind of hardware handling it has,
 * whether it is disabled etc etc.
 */
typedef struct irq_desc {
    unsigned int status;		/* IRQ status */
    hw_irq_controller *handler;
    struct msi_desc   *msi_desc;
    struct irqaction *action;	/* IRQ action list */
    unsigned int depth;		/* nested irq disables */
    struct irq_cfg *chip_data;
    int irq;
    spinlock_t lock;
    cpumask_t affinity;
    cpumask_t pending_mask;  /* IRQ migration pending mask */

    /* irq ratelimit */
    s_time_t rl_quantum_start;
    unsigned int rl_cnt;
    struct list_head rl_link;
} __cacheline_aligned irq_desc_t;

#if defined(__ia64__)
extern irq_desc_t irq_desc[NR_VECTORS];

#define setup_irq(irq, action) \
    setup_irq_vector(irq_to_vector(irq), action)

#define release_irq(irq) \
    release_irq_vector(irq_to_vector(irq))

#define request_irq(irq, handler, irqflags, devname, devid) \
    request_irq_vector(irq_to_vector(irq), handler, irqflags, devname, devid)

static inline unsigned int irq_to_vector(int);
extern int setup_irq_vector(unsigned int, struct irqaction *);
extern void release_irq_vector(unsigned int);
extern int request_irq_vector(unsigned int vector,
               void (*handler)(int, void *, struct cpu_user_regs *),
               unsigned long irqflags, const char * devname, void *dev_id);

#define create_irq(x) assign_irq_vector(AUTO_ASSIGN_IRQ)
#define destroy_irq(x) free_irq_vector(x)

#define irq_cfg(x)        &irq_cfg[(x)]
#define irq_to_desc(x)    &irq_desc[(x)]

#define irq_complete_move(x) do {} \
    while(!x)

#define domain_pirq_to_irq(d, irq) domain_irq_to_vector(d, irq)

struct irq_cfg {
        int  vector;
        cpumask_t domain;
};

extern struct irq_cfg irq_cfg[];

#else
extern int setup_irq(unsigned int irq, struct irqaction *);
extern void release_irq(unsigned int irq);
extern int request_irq(unsigned int irq,
               void (*handler)(int, void *, struct cpu_user_regs *),
               unsigned long irqflags, const char * devname, void *dev_id);
#endif

extern hw_irq_controller no_irq_type;
extern void no_action(int cpl, void *dev_id, struct cpu_user_regs *regs);

struct domain;
struct vcpu;
extern int pirq_guest_eoi(struct domain *d, int irq);
extern int pirq_guest_unmask(struct domain *d);
extern int pirq_guest_bind(struct vcpu *v, int irq, int will_share);
extern void pirq_guest_unbind(struct domain *d, int irq);
extern irq_desc_t *domain_spin_lock_irq_desc(
    struct domain *d, int irq, unsigned long *pflags);

static inline void set_native_irq_info(unsigned int irq, cpumask_t mask)
{
    irq_desc[irq].affinity = mask;
}

static inline void set_irq_info(int irq, cpumask_t mask)
{
    set_native_irq_info(irq, mask);
}

unsigned int set_desc_affinity(struct irq_desc *desc, cpumask_t mask);

#endif /* __XEN_IRQ_H__ */

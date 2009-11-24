
#ifndef __X86_TIME_H__
#define __X86_TIME_H__

#include <asm/msr.h>

void calibrate_tsc_bp(void);
void calibrate_tsc_ap(void);

typedef u64 cycles_t;

static inline cycles_t get_cycles(void)
{
    cycles_t c;
    rdtscll(c);
    return c;
}

unsigned long
mktime (unsigned int year, unsigned int mon,
        unsigned int day, unsigned int hour,
        unsigned int min, unsigned int sec);

int time_suspend(void);
int time_resume(void);

void init_percpu_time(void);

struct ioreq;
int dom0_pit_access(struct ioreq *ioreq);

int cpu_frequency_change(u64 freq);

struct tm;
struct tm wallclock_time(void);

void pit_broadcast_enter(void);
void pit_broadcast_exit(void);
int pit_broadcast_is_available(void);

uint64_t acpi_pm_tick_to_ns(uint64_t ticks);
uint64_t ns_to_acpi_pm_tick(uint64_t ns);

void pv_soft_rdtsc(struct vcpu *v, struct cpu_user_regs *regs);

void force_update_vcpu_system_time(struct vcpu *v);

#endif /* __X86_TIME_H__ */

/******************************************************************************
 * asm-x86/xenoprof.h
 * xenoprof x86 arch specific header file
 *
 * Copyright (c) 2006 Isaku Yamahata <yamahata at valinux co jp>
 *                    VA Linux Systems Japan K.K.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef __ASM_X86_XENOPROF_H__
#define __ASM_X86_XENOPROF_H__

int nmi_reserve_counters(void);
int nmi_setup_events(void);
int nmi_enable_virq(void);
int nmi_start(void);
void nmi_stop(void);
void nmi_disable_virq(void);
void nmi_release_counters(void);

int xenoprof_arch_init(int *num_events, char *cpu_type);
#define xenoprof_arch_reserve_counters()        nmi_reserve_counters()
#define xenoprof_arch_setup_events()            nmi_setup_events()
#define xenoprof_arch_enable_virq()             nmi_enable_virq()
#define xenoprof_arch_start()                   nmi_start()
#define xenoprof_arch_stop()                    nmi_stop()
#define xenoprof_arch_disable_virq()            nmi_disable_virq()
#define xenoprof_arch_release_counters()        nmi_release_counters()

int xenoprof_arch_counter(XEN_GUEST_HANDLE(void) arg);
int compat_oprof_arch_counter(XEN_GUEST_HANDLE(void) arg);

struct vcpu;
struct cpu_user_regs;

int xenoprofile_get_mode(struct vcpu *v, struct cpu_user_regs * const regs);

static inline int xenoprof_backtrace_supported(void)
{
    return 1;
}

void xenoprof_backtrace(
    struct domain *d, struct vcpu *vcpu, 
    struct cpu_user_regs *const regs, unsigned long depth, int mode);

#define xenoprof_shared_gmfn(d, gmaddr, maddr)                      \
    do {                                                            \
        (void)(maddr);                                              \
        gdprintk(XENLOG_WARNING,                                    \
                 "xenoprof/x86 with autotranslated mode enabled"    \
                 "isn't supported yet\n");                          \
    } while (0)
int passive_domain_do_rdmsr(struct cpu_user_regs *regs);
int passive_domain_do_wrmsr(struct cpu_user_regs *regs);
void passive_domain_destroy(struct vcpu *v);

#endif /* __ASM_X86_XENOPROF_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

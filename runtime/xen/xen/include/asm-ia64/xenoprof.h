/******************************************************************************
 * asm-ia64/xenoprof.h
 * xenoprof ia64 arch specific header file
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
 *
 */

#ifndef __ASM_XENOPROF_H__
#define __ASM_XENOPROF_H__

int xenoprof_arch_init(int *num_events, char *cpu_type);
int xenoprof_arch_reserve_counters(void);
int xenoprof_arch_counter(XEN_GUEST_HANDLE(void) arg);
int xenoprof_arch_setup_events(void);
int xenoprof_arch_enable_virq(void);
int xenoprof_arch_start(void);
void xenoprof_arch_stop(void);
void xenoprof_arch_disable_virq(void);
void xenoprof_arch_release_counters(void);

struct vcpu;
struct cpu_user_regs;
int xenoprofile_get_mode(struct vcpu *v, struct cpu_user_regs * const regs);
static inline int xenoprof_backtrace_supported(void)
{
    return 0;
}
static inline void xenoprof_backtrace(
    struct domain *d, struct vcpu *vcpu, 
    struct pt_regs *const regs, unsigned long depth, int mode)
{
    /* To be implemented */
    return;
}
#define xenoprof_shared_gmfn(d, gmaddr, maddr)                      \
do {                                                                \
    unsigned long ret;                                              \
    ret = create_grant_host_mapping((gmaddr),                       \
                                    (maddr) >> PAGE_SHIFT, 0, 0);   \
    BUG_ON(ret != GNTST_okay);                                      \
} while (0)

static inline int
ring(const struct pt_regs* regs)
{
    return ((struct ia64_psr*)(&(regs)->cr_ipsr))->cpl;
}
#define ring_0(r)       (ring(r) == 0)
#define ring_1(r)       (ring(r) == 1)
#define ring_2(r)       (ring(r) == 2)
#define ring_3(r)       (ring(r) == 3)

#endif /* __ASM_XENOPROF_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */

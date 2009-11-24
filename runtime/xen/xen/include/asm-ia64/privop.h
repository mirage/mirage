#ifndef _XEN_IA64_PRIVOP_H
#define _XEN_IA64_PRIVOP_H

#include <asm/ia64_int.h>
#include <asm/vcpu.h>

extern IA64FAULT priv_emulate(VCPU *vcpu, REGS *regs, u64 isr);

extern void privify_memory(void *start, u64 len);

extern int ia64_hyperprivop(unsigned long iim, REGS *regs);

#endif

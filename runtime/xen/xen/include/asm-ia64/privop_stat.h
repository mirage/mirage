#ifndef _XEN_IA64_PRIVOP_STAT_H
#define _XEN_IA64_PRIVOP_STAT_H
#include <asm/config.h>
#include <xen/types.h>
#include <public/xen.h>

#ifdef CONFIG_PRIVOP_ADDRS

extern void gather_privop_addrs(void);
extern void reset_privop_addrs(void);

#define PERFCOUNTER(var, name)
#define PERFCOUNTER_ARRAY(var, name, size)

#define PERFSTATUS(var, name)
#define PERFSTATUS_ARRAY(var, name, size)

#define PERFPRIVOPADDR(name) privop_inst_##name,

enum privop_inst {
#include <asm/perfc_defn.h>
};

#undef PERFCOUNTER
#undef PERFCOUNTER_ARRAY

#undef PERFSTATUS
#undef PERFSTATUS_ARRAY

#undef PERFPRIVOPADDR

#define	PRIVOP_COUNT_ADDR(regs,inst) privop_count_addr(regs->cr_iip,inst)
extern void privop_count_addr(unsigned long addr, enum privop_inst inst);

#else
#define PRIVOP_COUNT_ADDR(x,y) do {} while (0)
#define gather_privop_addrs() do {} while (0)
#define reset_privop_addrs() do {} while (0)
#endif

#endif /* _XEN_IA64_PRIVOP_STAT_H */

#ifndef __ASM_PERFC_H__
#define __ASM_PERFC_H__

#include <asm/vhpt.h>
#include <asm/privop_stat.h>

static inline void arch_perfc_printall(void)
{
}

static inline void arch_perfc_reset(void)
{
  reset_privop_addrs();
}

static inline void arch_perfc_gather(void)
{
  gather_vhpt_stats();
  gather_privop_addrs();
}

#endif

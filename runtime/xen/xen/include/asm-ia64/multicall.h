#ifndef __ASM_IA64_MULTICALL_H__
#define __ASM_IA64_MULTICALL_H__

#include <public/xen.h>
#include <xen/errno.h>

extern unsigned long ia64_do_multicall_call(
			unsigned long arg0,
			unsigned long arg1,
			unsigned long arg2,
			unsigned long arg3,
			unsigned long arg4,
			unsigned long arg5,
			unsigned long op);

static inline void do_multicall_call(multicall_entry_t *call)
{
	if (call->op < NR_hypercalls)
		call->result = ia64_do_multicall_call(
			call->args[0],
			call->args[1],
			call->args[2],
			call->args[3],
			call->args[4],
			call->args[5],
			call->op);
	else
		call->result = -ENOSYS;
}

#endif /* __ASM_IA64_MULTICALL_H__ */

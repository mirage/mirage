/*
 * File:	xenmca.h
 * Purpose:	Machine check handling specific defines for Xen
 *
 * Copyright (C) 2006 FUJITSU LTD. (kaz@jp.fujitsu.com)
 */

#ifndef _ASM_IA64_XENMCA_H
#define _ASM_IA64_XENMCA_H

#ifndef __ASSEMBLER__
#include <linux/list.h>
#include <asm/sal.h>

typedef struct sal_queue_entry_t {
	int cpuid;
	int sal_info_type;
	unsigned int vector;
	unsigned int virq;
	unsigned int length;
	struct list_head list;
} sal_queue_entry_t;

extern struct list_head *sal_queue;

struct ia64_mca_tlb_info {
	u64 cr_lid;
	u64 percpu_paddr;
};

extern struct ia64_mca_tlb_info ia64_mca_tlb_list[];
#endif	/* __ASSEMBLER__ */

#endif /* _ASM_IA64_XENMCA_H */


/*
 * Copyright (C) 2005 Hewlett-Packard Co
 *	Dan Magenheimer <dan.magenheimer@hp.com>
 *
 * Paravirtualizations of privileged operations for Xen/ia64
 *
 */

#ifndef _PRIVOP_H_
#define _PRIVOP_H_

#include <xen/arch-ia64.h>

#define IA64_PARAVIRTUALIZED

/* At 1 MB, before per-cpu space but still addressable using addl instead
   of movl. */
#define XSI_BASE		0xfffffffffff00000

/* Address of mapped regs.  */
#define XMAPPEDREGS_BASE	(XSI_BASE + XSI_SIZE)

#ifdef __ASSEMBLY__
#define	XEN_HYPER_RFI		break HYPERPRIVOP_RFI
#define	XEN_HYPER_RSM_PSR_DT	break HYPERPRIVOP_RSM_DT
#define	XEN_HYPER_SSM_PSR_DT	break HYPERPRIVOP_SSM_DT
#define	XEN_HYPER_COVER		break HYPERPRIVOP_COVER
#define	XEN_HYPER_ITC_D		break HYPERPRIVOP_ITC_D
#define	XEN_HYPER_ITC_I		break HYPERPRIVOP_ITC_I
#define	XEN_HYPER_SSM_I		break HYPERPRIVOP_SSM_I
#define	XEN_HYPER_GET_IVR	break HYPERPRIVOP_GET_IVR
#define	XEN_HYPER_GET_TPR	break HYPERPRIVOP_GET_TPR
#define	XEN_HYPER_SET_TPR	break HYPERPRIVOP_SET_TPR
#define	XEN_HYPER_EOI		break HYPERPRIVOP_EOI
#define	XEN_HYPER_SET_ITM	break HYPERPRIVOP_SET_ITM
#define	XEN_HYPER_THASH		break HYPERPRIVOP_THASH
#define	XEN_HYPER_PTC_GA	break HYPERPRIVOP_PTC_GA
#define	XEN_HYPER_ITR_D		break HYPERPRIVOP_ITR_D
#define	XEN_HYPER_GET_RR	break HYPERPRIVOP_GET_RR
#define	XEN_HYPER_SET_RR	break HYPERPRIVOP_SET_RR
#define	XEN_HYPER_SET_KR	break HYPERPRIVOP_SET_KR
#define	XEN_HYPER_FC		break HYPERPRIVOP_FC
#define	XEN_HYPER_GET_CPUID	break HYPERPRIVOP_GET_CPUID
#define	XEN_HYPER_GET_PMD	break HYPERPRIVOP_GET_PMD
#define	XEN_HYPER_GET_EFLAG	break HYPERPRIVOP_GET_EFLAG
#define	XEN_HYPER_SET_EFLAG	break HYPERPRIVOP_SET_EFLAG
#define	XEN_HYPER_RSM_BE	break HYPERPRIVOP_RSM_BE
#define	XEN_HYPER_GET_PSR	break HYPERPRIVOP_GET_PSR

#define XSI_IFS			(XSI_BASE + XSI_IFS_OFS)
#define XSI_PRECOVER_IFS	(XSI_BASE + XSI_PRECOVER_IFS_OFS)
#define XSI_INCOMPL_REGFR	(XSI_BASE + XSI_INCOMPL_REGFR_OFS)
#define XSI_IFA			(XSI_BASE + XSI_IFA_OFS)
#define XSI_ISR			(XSI_BASE + XSI_ISR_OFS)
#define XSI_IIM			(XSI_BASE + XSI_IIM_OFS)
#define XSI_ITIR		(XSI_BASE + XSI_ITIR_OFS)
#define XSI_PSR_I_ADDR		(XSI_BASE + XSI_PSR_I_ADDR_OFS)
#define XSI_PSR_IC		(XSI_BASE + XSI_PSR_IC_OFS)
#define XSI_IPSR		(XSI_BASE + XSI_IPSR_OFS)
#define XSI_IIP			(XSI_BASE + XSI_IIP_OFS)
#define XSI_BANK1_R16		(XSI_BASE + XSI_BANK1_R16_OFS)
#define XSI_BANKNUM		(XSI_BASE + XSI_BANKNUM_OFS)
#define XSI_IHA			(XSI_BASE + XSI_IHA_OFS)
#endif

#ifndef __ASSEMBLY__
#define	XEN_HYPER_SSM_I		asm("break %0" : : "i" (HYPERPRIVOP_SSM_I))
#define	XEN_HYPER_GET_IVR	asm("break %0" : : "i" (HYPERPRIVOP_GET_IVR))

/************************************************/
/* Instructions paravirtualized for performance */
/************************************************/

/* Xen uses memory-mapped virtual privileged registers for access to many
 * performance-sensitive privileged registers.  Some, like the processor
 * status register (psr), are broken up into multiple memory locations.
 * Others, like "pend", are abstractions based on privileged registers.
 * "Pend" is guaranteed to be set if reading cr.ivr would return a
 * (non-spurious) interrupt. */
#define XEN_MAPPEDREGS ((struct mapped_regs *)XMAPPEDREGS_BASE)
#define XSI_PSR_I			\
	(*XEN_MAPPEDREGS->interrupt_mask_addr)
#define xen_get_virtual_psr_i()		\
	(!XSI_PSR_I)
#define xen_set_virtual_psr_i(_val)	\
	({ XSI_PSR_I = (uint8_t)(_val) ? 0 : 1; })
#define xen_get_virtual_psr_ic()	\
	( XEN_MAPPEDREGS->interrupt_collection_enabled )
#define xen_set_virtual_psr_ic(_val)	\
	({ XEN_MAPPEDREGS->interrupt_collection_enabled = _val ? 1 : 0; })
#define xen_get_virtual_pend()		(XEN_MAPPEDREGS->pending_interruption)

#endif /* __ASSEMBLY__ */

#endif /* _PRIVOP_H_ */


#ifndef _ASM_IA64_XENKREGS_H
#define _ASM_IA64_XENKREGS_H

/*
 * Translation registers:
 */
#define IA64_TR_MAPPED_REGS	3	/* dtr3: vcpu mapped regs */
#define IA64_TR_SHARED_INFO	4	/* dtr4: page shared with domain */
#define IA64_TR_VHPT		5	/* dtr5: vhpt */

#define IA64_TR_VPD		2	/* itr2: vpd */

#define IA64_DTR_GUEST_KERNEL   7
#define IA64_ITR_GUEST_KERNEL   2
/* Processor status register bits: */
#define IA64_PSR_VM_BIT		46
#define IA64_PSR_VM	(__IA64_UL(1) << IA64_PSR_VM_BIT)

#define IA64_DEFAULT_DCR_BITS	(IA64_DCR_PP | IA64_DCR_LC | IA64_DCR_DM | \
				 IA64_DCR_DP | IA64_DCR_DK | IA64_DCR_DX | \
				 IA64_DCR_DR | IA64_DCR_DA | IA64_DCR_DD)

// note IA64_PSR_PK removed from following, why is this necessary?
#define	DELIVER_PSR_SET	(IA64_PSR_IC | IA64_PSR_I  |	\
			 IA64_PSR_DT | IA64_PSR_RT |	\
			 IA64_PSR_IT | IA64_PSR_BN)

#define	DELIVER_PSR_CLR	(IA64_PSR_AC | IA64_PSR_DFL| IA64_PSR_DFH|	\
			 IA64_PSR_SP | IA64_PSR_DI | IA64_PSR_SI |	\
			 IA64_PSR_DB | IA64_PSR_LP | IA64_PSR_TB |	\
			 IA64_PSR_CPL| IA64_PSR_MC | IA64_PSR_IS |	\
			 IA64_PSR_ID | IA64_PSR_DA | IA64_PSR_DD |	\
			 IA64_PSR_SS | IA64_PSR_RI | IA64_PSR_ED | IA64_PSR_IA)

//  NO PSR_CLR IS DIFFERENT! (CPL)
#define IA64_PSR_CPL1	(__IA64_UL(1) << IA64_PSR_CPL1_BIT)
#define IA64_PSR_CPL0	(__IA64_UL(1) << IA64_PSR_CPL0_BIT)

/* Interruption Function State */
#define IA64_IFS_V_BIT		63
#define IA64_IFS_V	(__IA64_UL(1) << IA64_IFS_V_BIT)

/* Interruption Status Register.  */
#define IA64_ISR_NI_BIT	39	/* Nested interrupt.  */

/* Page Table Address */
#define IA64_PTA_VE_BIT 0
#define IA64_PTA_SIZE_BIT 2
#define IA64_PTA_SIZE_LEN 6
#define IA64_PTA_VF_BIT 8
#define IA64_PTA_BASE_BIT 15

#define IA64_PTA_VE     (__IA64_UL(1) << IA64_PTA_VE_BIT)
#define IA64_PTA_SIZE   (__IA64_UL((1 << IA64_PTA_SIZE_LEN) - 1) <<	\
			 IA64_PTA_SIZE_BIT)
#define IA64_PTA_VF     (__IA64_UL(1) << IA64_PTA_VF_BIT)
#define IA64_PTA_BASE   (__IA64_UL(0) - ((__IA64_UL(1) << IA64_PTA_BASE_BIT)))

/* Some cr.itir declarations. */
#define	IA64_ITIR_PS		2
#define	IA64_ITIR_PS_LEN	6
#define	IA64_ITIR_PS_MASK	(((__IA64_UL(1) << IA64_ITIR_PS_LEN) - 1) \
 							<< IA64_ITIR_PS)
#define	IA64_ITIR_KEY		8
#define	IA64_ITIR_KEY_LEN	24
#define	IA64_ITIR_KEY_MASK	(((__IA64_UL(1) << IA64_ITIR_KEY_LEN) - 1) \
							<< IA64_ITIR_KEY)
#define	IA64_ITIR_PS_KEY(_ps, _key)	(((_ps) << IA64_ITIR_PS) | \
					 (((_key) << IA64_ITIR_KEY)))

/* Region Register Bits */
#define IA64_RR_PS		2
#define IA64_RR_PS_LEN		6
#define IA64_RR_RID		8
#define IA64_RR_RID_LEN		24
#define IA64_RR_RID_MASK	(((__IA64_UL(1) << IA64_RR_RID_LEN) - 1) << \
				IA64_RR_RID

/* Define Protection Key Register (PKR) */
#define	IA64_PKR_V		0
#define	IA64_PKR_WD		1
#define	IA64_PKR_RD		2
#define	IA64_PKR_XD		3
#define	IA64_PKR_MBZ0		4
#define	IA64_PKR_KEY		8
#define	IA64_PKR_KEY_LEN	24
#define	IA64_PKR_MBZ1		32

#define	IA64_PKR_VALID		(1 << IA64_PKR_V)
#define	IA64_PKR_KEY_MASK	(((__IA64_UL(1) << IA64_PKR_KEY_LEN) - 1) \
							<< IA64_PKR_KEY)

#define	XEN_IA64_NPKRS		15	/* Number of pkr's in PV */

  	/* A pkr val for the hypervisor: key = 0, valid = 1. */
#define XEN_IA64_PKR_VAL	((0 << IA64_PKR_KEY) | IA64_PKR_VALID)

#endif /* _ASM_IA64_XENKREGS_H */

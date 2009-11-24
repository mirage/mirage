/*
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 * This code is mostly taken from FreeBSD.
 *
 *
 ****************************************************************************
 * Copyright (c) 2000 Doug Rabson
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

#ifndef _IA64_CPU_H_
#define _IA64_CPU_H_

#include "ia64_fpu.h"

/*
 * Definition of Region Register bits (RR)
 *
 * RR bit field positions
 */
#define IA64_RR_VE		0
#define IA64_RR_MBZ0		1
#define IA64_RR_PS		2
#define IA64_RR_PS_LEN		6
#define IA64_RR_RID		8
#define IA64_RR_RID_LEN		24
#define IA64_RR_MBZ1		32

#define IA64_RR_IDX_POS		61

#define IA64_RR_VAL(size,rid) (((size) << IA64_RR_PS) | ((rid) << IA64_RR_RID))

/*
 * Define Protection Key Register (PKR)
 *
 * PKR bit field positions
 */
#define IA64_PKR_V		0
#define IA64_PKR_WD		1
#define IA64_PKR_RD		2
#define IA64_PKR_XD		3
#define IA64_PKR_MBZ0		4
#define IA64_PKR_KEY		8
#define IA64_PKR_KEY_LEN	24
#define IA64_PKR_MBZ1		32

#define IA64_PKR_VALID		(1 << IA64_PKR_V)


/*
 * ITIR bit field positions
 */

#define	IA64_ITIR_MBZ0		0
#define	IA64_ITIR_PS		2
#define	IA64_ITIR_PS_LEN	6
#define	IA64_ITIR_KEY		8
#define	IA64_ITIR_KEY_LEN	24
#define	IA64_ITIR_MBZ1		32
#define	IA64_ITIR_MBZ1_LEN	16
#define	IA64_ITIR_PPN		48
#define	IA64_ITIR_PPN_LEN	15
#define	IA64_ITIR_MBZ2		63

/*
 * Definition of PSR and IPSR bits.
 */
#define IA64_PSR_BE		0x0000000000000002
#define IA64_PSR_UP		0x0000000000000004
#define IA64_PSR_AC		0x0000000000000008
#define IA64_PSR_MFL		0x0000000000000010
#define IA64_PSR_MFH_BIT	5
#define IA64_PSR_MFH		(1 << IA64_PSR_MFH_BIT)
#define IA64_PSR_UMASK		(IA64_PSR_BE | IA64_PSR_UP |	\
				IA64_PSR_AC | IA64_PSR_MFL |	\
				IA64_PSR_MFH)
#define IA64_PSR_IC_BIT		13
#define IA64_PSR_IC		(1<<IA64_PSR_IC_BIT) /*0x0000000000002000*/
#define IA64_PSR_I_BIT		14
#define IA64_PSR_I		(1<<IA64_PSR_I_BIT) /*0x0000000000004000*/
#define IA64_PSR_PK		0x0000000000008000
#define IA64_PSR_DT		0x0000000000020000
#define IA64_PSR_DFL		0x0000000000040000
#define IA64_PSR_DFH		0x0000000000080000
#define IA64_PSR_SP		0x0000000000100000
#define IA64_PSR_PP		0x0000000000200000
#define IA64_PSR_DI		0x0000000000400000
#define IA64_PSR_SI		0x0000000000800000
#define IA64_PSR_DB		0x0000000001000000
#define IA64_PSR_LP		0x0000000002000000
#define IA64_PSR_TB		0x0000000004000000
#define IA64_PSR_RT		0x0000000008000000
#define IA64_PSR_CPL		0x0000000300000000
#define IA64_PSR_CPL_KERN	0x0000000000000000
#define IA64_PSR_CPL_1		0x0000000100000000
#define IA64_PSR_CPL_2		0x0000000200000000
#define IA64_PSR_CPL_USER	0x0000000300000000
#define IA64_PSR_IS		0x0000000400000000
#define IA64_PSR_MC		0x0000000800000000
#define IA64_PSR_IT		0x0000001000000000
#define IA64_PSR_ID		0x0000002000000000
#define IA64_PSR_DA		0x0000004000000000
#define IA64_PSR_DD		0x0000008000000000
#define IA64_PSR_SS		0x0000010000000000
#define IA64_PSR_RI		0x0000060000000000
#define IA64_PSR_RI_0		0x0000000000000000
#define IA64_PSR_RI_1		0x0000020000000000
#define IA64_PSR_RI_2		0x0000040000000000
#define IA64_PSR_RI_SHIFT	41
#define IA64_PSR_ED		0x0000080000000000
#define IA64_PSR_BN		0x0000100000000000
#define IA64_PSR_IA		0x0000200000000000


#define STARTUP_PSR (IA64_PSR_IT | IA64_PSR_PK | \
            	     IA64_PSR_DT | IA64_PSR_RT | \
		     IA64_PSR_BN | IA64_PSR_CPL_KERN | IA64_PSR_AC)

#define MOS_SYS_PSR (IA64_PSR_IC | IA64_PSR_I | IA64_PSR_IT | \
            	     IA64_PSR_DT | IA64_PSR_RT | \
		     IA64_PSR_BN | IA64_PSR_CPL_KERN | IA64_PSR_AC)

#define MOS_USR_PSR (IA64_PSR_IC | IA64_PSR_I | IA64_PSR_IT | \
            	     IA64_PSR_DT | IA64_PSR_RT | \
		     IA64_PSR_BN | IA64_PSR_CPL_USER | IA64_PSR_AC)

/*
 * Definition of ISR bits.
 */
#define IA64_ISR_CODE	0x000000000000ffff
#define IA64_ISR_VECTOR	0x0000000000ff0000
#define IA64_ISR_X	0x0000000100000000
#define IA64_ISR_W	0x0000000200000000
#define IA64_ISR_R	0x0000000400000000
#define IA64_ISR_NA	0x0000000800000000
#define IA64_ISR_SP	0x0000001000000000
#define IA64_ISR_RS	0x0000002000000000
#define IA64_ISR_IR	0x0000004000000000
#define IA64_ISR_NI	0x0000008000000000
#define IA64_ISR_SO	0x0000010000000000
#define IA64_ISR_EI	0x0000060000000000
#define IA64_ISR_EI_0	0x0000000000000000
#define IA64_ISR_EI_1	0x0000020000000000
#define IA64_ISR_EI_2	0x0000040000000000
#define IA64_ISR_ED	0x0000080000000000

/*
 * DCR bit positions
 */
#define IA64_DCR_PP		0
#define IA64_DCR_BE		1
#define IA64_DCR_LC		2
#define IA64_DCR_MBZ0		4
#define IA64_DCR_MBZ0_V		0xf
#define IA64_DCR_DM		8
#define IA64_DCR_DP		9
#define IA64_DCR_DK		10
#define IA64_DCR_DX		11
#define IA64_DCR_DR		12
#define IA64_DCR_DA		13
#define IA64_DCR_DD		14
#define IA64_DCR_DEFER_ALL	0x7f00
#define IA64_DCR_MBZ1		2
#define IA64_DCR_MBZ1_V		0xffffffffffffULL


#define IA64_DCR_DEFAULT (IA64_DCR_BE)

/*
 * Vector numbers for various ia64 interrupts.
 */
#define IA64_VEC_VHPT				0
#define IA64_VEC_ITLB				1
#define IA64_VEC_DTLB				2
#define IA64_VEC_ALT_ITLB			3
#define IA64_VEC_ALT_DTLB			4
#define IA64_VEC_NESTED_DTLB			5
#define IA64_VEC_IKEY_MISS			6
#define IA64_VEC_DKEY_MISS			7
#define IA64_VEC_DIRTY_BIT			8
#define IA64_VEC_INST_ACCESS			9
#define IA64_VEC_DATA_ACCESS			10
#define IA64_VEC_BREAK				11
#define IA64_VEC_EXT_INTR			12
#define IA64_VEC_PAGE_NOT_PRESENT		20
#define IA64_VEC_KEY_PERMISSION			21
#define IA64_VEC_INST_ACCESS_RIGHTS		22
#define IA64_VEC_DATA_ACCESS_RIGHTS		23
#define IA64_VEC_GENERAL_EXCEPTION		24
#define IA64_VEC_DISABLED_FP			25
#define IA64_VEC_NAT_CONSUMPTION		26
#define IA64_VEC_SPECULATION			27
#define IA64_VEC_DEBUG				29
#define IA64_VEC_UNALIGNED_REFERENCE		30
#define IA64_VEC_UNSUPP_DATA_REFERENCE		31
#define IA64_VEC_FLOATING_POINT_FAULT		32
#define IA64_VEC_FLOATING_POINT_TRAP		33
#define IA64_VEC_LOWER_PRIVILEGE_TRANSFER 	34
#define IA64_VEC_TAKEN_BRANCH_TRAP		35
#define IA64_VEC_SINGLE_STEP_TRAP		36
#define IA64_VEC_IA32_EXCEPTION			45
#define IA64_VEC_IA32_INTERCEPT			46
#define IA64_VEC_IA32_INTERRUPT			47

/*
 * Define hardware RSE Configuration Register
 *
 * RS Configuration (RSC) bit field positions
 */

#define IA64_RSC_MODE       0
#define IA64_RSC_PL         2
#define IA64_RSC_BE         4
#define IA64_RSC_MBZ0       5
#define IA64_RSC_MBZ0_V     0x3ff
#define IA64_RSC_LOADRS     16
#define IA64_RSC_LOADRS_LEN 14
#define IA64_RSC_MBZ1       30
#define IA64_RSC_MBZ1_V     0x3ffffffffULL

/*
 * RSC modes
 */
#define IA64_RSC_MODE_LY (0x0) 		/* Lazy */
#define IA64_RSC_MODE_SI (0x1) 		/* Store intensive */
#define IA64_RSC_MODE_LI (0x2) 		/* Load intensive */
#define IA64_RSC_MODE_EA (0x3) 		/* Eager */

#define IA64_RSE_EAGER (IA64_RSC_MODE_EA<<IA64_RSC_MODE)
#define IA64_RSE_LAZY (IA64_RSC_MODE_LY<<IA64_RSC_MODE)



#ifndef __ASSEMBLY__

/* ia64 function descriptor and global pointer */
struct ia64_fdesc
{
	uint64_t	func;
	uint64_t	gp;
};
typedef struct ia64_fdesc ia64_fdesc_t;

#define FDESC_FUNC(fn)  (((struct ia64_fdesc *) fn)->func)
#define FDESC_GP(fn)    (((struct ia64_fdesc *) fn)->gp)


/*
 * Various special ia64 instructions.
 */

/*
 * Memory Fence.
 */
static __inline void
ia64_mf(void)
{
	__asm __volatile("mf" ::: "memory");
}

static __inline void
ia64_mf_a(void)
{
	__asm __volatile("mf.a");
}

/*
 * Flush Cache.
 */
static __inline void
ia64_fc(uint64_t va)
{
	__asm __volatile("fc %0" :: "r"(va));
}

/*
 * Sync instruction stream.
 */
static __inline void
ia64_sync_i(void)
{
	__asm __volatile("sync.i");
}

/*
 * Calculate address in VHPT for va.
 */
static __inline uint64_t
ia64_thash(uint64_t va)
{
	uint64_t result;
	__asm __volatile("thash %0=%1" : "=r" (result) : "r" (va));
	return result;
}

/*
 * Calculate VHPT tag for va.
 */
static __inline uint64_t
ia64_ttag(uint64_t va)
{
	uint64_t result;
	__asm __volatile("ttag %0=%1" : "=r" (result) : "r" (va));
	return result;
}

/*
 * Convert virtual address to physical.
 */
static __inline uint64_t
ia64_tpa(uint64_t va)
{
	uint64_t result;
	__asm __volatile("tpa %0=%1" : "=r" (result) : "r" (va));
	return result;
}

/*
 * Generate a ptc.e instruction.
 */
static __inline void
ia64_ptc_e(uint64_t v)
{
	__asm __volatile("ptc.e %0;; srlz.d;;" :: "r"(v));
}

/*
 * Generate a ptc.g instruction.
 */
static __inline void
ia64_ptc_g(uint64_t va, uint64_t size)
{
	__asm __volatile("ptc.g %0,%1;; srlz.d;;" :: "r"(va), "r"(size<<2));
}

/*
 * Generate a ptc.ga instruction.
 */
static __inline void
ia64_ptc_ga(uint64_t va, uint64_t size)
{
	__asm __volatile("ptc.ga %0,%1;; srlz.d;;" :: "r"(va), "r"(size<<2));
}

/*
 * Generate a ptc.l instruction.
 */
static __inline void
ia64_ptc_l(uint64_t va, uint64_t size)
{
	__asm __volatile("ptc.l %0,%1;; srlz.d;;" :: "r"(va), "r"(size<<2));
}

/*
 * Read the value of psr.
 */
static __inline uint64_t
ia64_get_psr(void)
{
	uint64_t result;
	__asm __volatile("mov %0=psr;;" : "=r" (result));
	return result;
}

static __inline void
ia64_set_psr(uint64_t v)
{
	__asm __volatile("mov psr.l=%0" :: "r" (v));
}

static __inline void
ia64_srlz_d(void)
{
	__asm __volatile("srlz.d;;");
}

static __inline void
disable_intr(void)
{
	__asm __volatile ("rsm psr.ic|psr.i");
}

static __inline void
enable_intr(void)
{
	__asm __volatile ("ssm psr.ic|psr.i");
}

/*
 * Define accessors for application registers.
 */

#define IA64_AR(name)							\
									\
static __inline uint64_t						\
ia64_get_##name(void)							\
{									\
	uint64_t result;						\
	__asm __volatile(";;mov %0=ar." #name ";;" : "=r" (result));	\
	return result;							\
}									\
									\
static __inline void							\
ia64_set_##name(uint64_t v)						\
{									\
	__asm __volatile("mov ar." #name "=%0" :: "r" (v));		\
}

IA64_AR(k0)
IA64_AR(k1)
IA64_AR(k2)
IA64_AR(k3)
IA64_AR(k4)
IA64_AR(k5)
IA64_AR(k6)
IA64_AR(k7)

IA64_AR(rsc)
IA64_AR(bsp)
IA64_AR(bspstore)
IA64_AR(rnat)

IA64_AR(fcr)

IA64_AR(eflag)
IA64_AR(csd)
IA64_AR(ssd)
IA64_AR(cflg)
IA64_AR(fsr)
IA64_AR(fir)
IA64_AR(fdr)

IA64_AR(ccv)

IA64_AR(unat)

IA64_AR(fpsr)

IA64_AR(itc)

IA64_AR(pfs)
IA64_AR(lc)
IA64_AR(ec)

/*
 * Define accessors for control registers.
 */

#define IA64_CR(name)						\
								\
static __inline uint64_t					\
ia64_get_##name(void)						\
{								\
	uint64_t result;					\
	__asm __volatile("mov %0=cr." #name : "=r" (result));	\
	return result;						\
}								\
								\
static __inline void						\
ia64_set_##name(uint64_t v)					\
{								\
	__asm __volatile("mov cr." #name "=%0" :: "r" (v));	\
}

IA64_CR(dcr)
IA64_CR(itm)
IA64_CR(iva)

IA64_CR(pta)

IA64_CR(ipsr)
IA64_CR(isr)

IA64_CR(iip)
IA64_CR(ifa)
IA64_CR(itir)
IA64_CR(iipa)
IA64_CR(ifs)
IA64_CR(iim)
IA64_CR(iha)

IA64_CR(lid)
IA64_CR(ivr)
IA64_CR(tpr)
IA64_CR(eoi)
IA64_CR(irr0)
IA64_CR(irr1)
IA64_CR(irr2)
IA64_CR(irr3)
IA64_CR(itv)
IA64_CR(pmv)
IA64_CR(cmcv)

IA64_CR(lrr0)
IA64_CR(lrr1)

#define IA64_GR(name)						\
								\
static __inline uint64_t					\
ia64_get_##name(void)						\
{								\
	uint64_t result;					\
	__asm __volatile("mov %0=" #name : "=r" (result));	\
	return result;						\
}								\
								\
static __inline void						\
ia64_set_##name(uint64_t v)					\
{								\
	__asm __volatile("mov " #name "=%0" :: "r" (v));	\
}

IA64_GR(sp)
IA64_GR(b0)
IA64_GR(r13)	// tp


/*
 * Write a region register.
 */
static __inline void
ia64_set_rr(uint64_t rrbase, uint64_t v)
{
	__asm __volatile("mov rr[%0]=%1;; srlz.d;;"
			 :: "r"(rrbase), "r"(v) : "memory");
}

/*
 * Read a region register.
 */
static __inline uint64_t
ia64_get_rr(uint64_t rrbase)
{
	uint64_t v;
	__asm __volatile("mov %1=rr[%0];;"
			 : "=r" (v) : "r"(rrbase) : "memory");
	return v;
}


/*
 * Read a CPUID register.
 */
static __inline uint64_t
ia64_get_cpuid(int i)
{
	uint64_t result;
	__asm __volatile("mov %0=cpuid[%1]"
			 : "=r" (result) : "r"(i));
	return result;
}


struct trap_frame
{
	uint64_t	rsc;
	uint64_t	ndirty;		/* number of dirty regs */
	uint64_t	ssd;
	uint64_t	iip;		/* interrupted ip */
	uint64_t	ipsr;		/* interrupted psr */
	uint64_t	ifs;		/* interruption func status register */

	uint16_t	trap_num;	/* Trap num, index in trap_vec */
	uint64_t	cfm;		/* current frame marker */
	uint64_t	pfs;		/* previous function state ar64 */
	uint64_t	bsp;		/* backing store pointer ar17 */
	uint64_t	rnat;		/* rse nat collection ar19 */
	uint64_t	csd;		/* comp and store data reg ar25 */
	uint64_t	ccv;		/* comp and xchange val reg ar32 */
	uint64_t	unat;		/* */
	uint64_t	fpsr;		/* floating point state reg ar40 */
	uint64_t	pr;		/* predicate regs 0-63 */

	uint64_t	gp;		/* the gp pointer */
	uint64_t	sp;		/* stack pointer */
	uint64_t	tp;		/* thread pointer */

	uint64_t	r2;		/* global reg 2 */
	uint64_t	r3;
	uint64_t	r8;
	uint64_t	r9;
	uint64_t	r10;
	uint64_t	r11;
	uint64_t	r14;
	uint64_t	r15;
	uint64_t	r16;
	uint64_t	r17;
	uint64_t	r18;
	uint64_t	r19;
	uint64_t	r20;
	uint64_t	r21;
	uint64_t	r22;
	uint64_t	r23;
	uint64_t	r24;
	uint64_t	r25;
	uint64_t	r26;
	uint64_t	r27;
	uint64_t	r28;
	uint64_t	r29;
	uint64_t	r30;
	uint64_t	r31;

	uint64_t	b0;
	uint64_t	b6;
	uint64_t	b7;

	ia64_fpreg_t	f6;           /* floating point register 6 */
	ia64_fpreg_t	f7;
	ia64_fpreg_t	f8;
	ia64_fpreg_t	f9;
	ia64_fpreg_t	f10;
	ia64_fpreg_t	f11;

	uint64_t	ifa;		/* interruption faulting address */
	uint64_t	isr;		/* interruption status register */
	uint64_t	iim;		/* interruption immediate register */
};

typedef struct trap_frame trap_frame_t;


#endif  /* __ASSEMBLY__ */

/* Page access parameters. */
#define PTE_P_SHIFT	0
#define PTE_P		1

#define PTE_MA_SHIFT	2
#define PTE_MA_WB	0

#define PTE_A_SHIFT	5
#define PTE_A		1
#define PTE_D_SHIFT	6
#define PTE_D		1

#define PTE_AR_SHIFT	9
#define PTE_AR_R	0
#define PTE_AR_RX	1
#define PTE_AR_RW	2
#define PTE_AR_RWX	3
#define PTE_AR_R_RW	4
#define PTE_AR_RX_RWX	5
#define PTE_AR_RWX_RW	6
/* privilege level */
#define PTE_PL_SHIFT	7
#define PTE_PL_KERN	0	/* used for kernel */
/* page size */
#define PTE_PS_4K	12
#define PTE_PS_8K	13
#define PTE_PS_16K	14
#define PTE_PS_64K	16
#define PTE_PS_256K	18
#define PTE_PS_1M	20
#define PTE_PS_4M	22
#define PTE_PS_16M	24
#define PTE_PS_64M	26
#define PTE_PS_256M	28


	/* Some offsets for ia64_pte_t. */
#define PTE_OFF_P	0
#define PTE_OFF_MA	3
#define PTE_OFF_A	5
#define PTE_OFF_D	6
#define PTE_OFF_PL	7
#define PTE_OFF_AR	9
#define PTE_OFF_PPN	12
#define PTE_OFF_ED	52

#if !defined(_ASM) && !defined(__ASSEMBLY__)
/*
 * A short-format VHPT entry. Also matches the TLB insertion format.
 */
typedef struct
{
	uint64_t pte_p	:1;	/* bits 0..0 */
	uint64_t pte_rv1:1;	/* bits 1..1 */
	uint64_t pte_ma	:3;	/* bits 2..4 */
	uint64_t pte_a	:1;	/* bits 5..5 */
	uint64_t pte_d	:1;	/* bits 6..6 */
	uint64_t pte_pl	:2;	/* bits 7..8 */
	uint64_t pte_ar	:3;	/* bits 9..11 */
	uint64_t pte_ppn:38;	/* bits 12..49 */
	uint64_t pte_rv2:2;	/* bits 50..51 */
	uint64_t pte_ed	:1;	/* bits 52..52 */
	uint64_t pte_ig	:11;	/* bits 53..63 */
} ia64_pte_t;


/*
 * A long-format VHPT entry.
 */
typedef struct
{
	uint64_t pte_p		:1;	/* bits 0..0 */
	uint64_t pte_rv1	:1;	/* bits 1..1 */
	uint64_t pte_ma		:3;	/* bits 2..4 */
	uint64_t pte_a		:1;	/* bits 5..5 */
	uint64_t pte_d		:1;	/* bits 6..6 */
	uint64_t pte_pl		:2;	/* bits 7..8 */
	uint64_t pte_ar		:3;	/* bits 9..11 */
	uint64_t pte_ppn	:38;	/* bits 12..49 */
	uint64_t pte_rv2	:2;	/* bits 50..51 */
	uint64_t pte_ed		:1;	/* bits 52..52 */
	uint64_t pte_ig		:11;	/* bits 53..63 */
	uint64_t pte_rv3	:2;	/* bits 0..1 */
	uint64_t pte_ps		:6;	/* bits 2..7 */
	uint64_t pte_key	:24;	/* bits 8..31 */
	uint64_t pte_rv4	:32;	/* bits 32..63 */
	uint64_t pte_tag;		/* includes ti */
	uint64_t pte_chain;		/* pa of collision chain */
} ia64_lpte_t;

#endif /* __ASSEMBLY__ */

#endif /* _IA64_CPU_H_ */

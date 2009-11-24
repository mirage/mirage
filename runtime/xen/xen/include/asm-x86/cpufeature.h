/*
 * cpufeature.h
 *
 * Defines x86 CPU feature bits
 */

#ifndef __ASM_I386_CPUFEATURE_H
#define __ASM_I386_CPUFEATURE_H

#include <xen/bitops.h>

#define NCAPINTS	7	/* N 32-bit words worth of info */

/* Intel-defined CPU features, CPUID level 0x00000001 (edx), word 0 */
#define X86_FEATURE_FPU		(0*32+ 0) /* Onboard FPU */
#define X86_FEATURE_VME		(0*32+ 1) /* Virtual Mode Extensions */
#define X86_FEATURE_DE		(0*32+ 2) /* Debugging Extensions */
#define X86_FEATURE_PSE 	(0*32+ 3) /* Page Size Extensions */
#define X86_FEATURE_TSC		(0*32+ 4) /* Time Stamp Counter */
#define X86_FEATURE_MSR		(0*32+ 5) /* Model-Specific Registers, RDMSR, WRMSR */
#define X86_FEATURE_PAE		(0*32+ 6) /* Physical Address Extensions */
#define X86_FEATURE_MCE		(0*32+ 7) /* Machine Check Architecture */
#define X86_FEATURE_CX8		(0*32+ 8) /* CMPXCHG8 instruction */
#define X86_FEATURE_APIC	(0*32+ 9) /* Onboard APIC */
#define X86_FEATURE_SEP		(0*32+11) /* SYSENTER/SYSEXIT */
#define X86_FEATURE_MTRR	(0*32+12) /* Memory Type Range Registers */
#define X86_FEATURE_PGE		(0*32+13) /* Page Global Enable */
#define X86_FEATURE_MCA		(0*32+14) /* Machine Check Architecture */
#define X86_FEATURE_CMOV	(0*32+15) /* CMOV instruction (FCMOVCC and FCOMI too if FPU present) */
#define X86_FEATURE_PAT		(0*32+16) /* Page Attribute Table */
#define X86_FEATURE_PSE36	(0*32+17) /* 36-bit PSEs */
#define X86_FEATURE_PN		(0*32+18) /* Processor serial number */
#define X86_FEATURE_CLFLSH	(0*32+19) /* Supports the CLFLUSH instruction */
#define X86_FEATURE_DS		(0*32+21) /* Debug Store */
#define X86_FEATURE_ACPI	(0*32+22) /* ACPI via MSR */
#define X86_FEATURE_MMX		(0*32+23) /* Multimedia Extensions */
#define X86_FEATURE_FXSR	(0*32+24) /* FXSAVE and FXRSTOR instructions (fast save and restore */
				          /* of FPU context), and CR4.OSFXSR available */
#define X86_FEATURE_XMM		(0*32+25) /* Streaming SIMD Extensions */
#define X86_FEATURE_XMM2	(0*32+26) /* Streaming SIMD Extensions-2 */
#define X86_FEATURE_SELFSNOOP	(0*32+27) /* CPU self snoop */
#define X86_FEATURE_HT		(0*32+28) /* Hyper-Threading */
#define X86_FEATURE_ACC		(0*32+29) /* Automatic clock control */
#define X86_FEATURE_IA64	(0*32+30) /* IA-64 processor */
#define X86_FEATURE_PBE		(0*32+31) /* Pending Break Enable */

/* AMD-defined CPU features, CPUID level 0x80000001, word 1 */
/* Don't duplicate feature flags which are redundant with Intel! */
#define X86_FEATURE_SYSCALL	(1*32+11) /* SYSCALL/SYSRET */
#define X86_FEATURE_MP		(1*32+19) /* MP Capable. */
#define X86_FEATURE_NX		(1*32+20) /* Execute Disable */
#define X86_FEATURE_MMXEXT	(1*32+22) /* AMD MMX extensions */
#define X86_FEATURE_FFXSR       (1*32+25) /* FFXSR instruction optimizations */
#define X86_FEATURE_PAGE1GB	(1*32+26) /* 1Gb large page support */
#define X86_FEATURE_RDTSCP	(1*32+27) /* RDTSCP */
#define X86_FEATURE_LM		(1*32+29) /* Long Mode (x86-64) */
#define X86_FEATURE_3DNOWEXT	(1*32+30) /* AMD 3DNow! extensions */
#define X86_FEATURE_3DNOW	(1*32+31) /* 3DNow! */

/* Transmeta-defined CPU features, CPUID level 0x80860001, word 2 */
#define X86_FEATURE_RECOVERY	(2*32+ 0) /* CPU in recovery mode */
#define X86_FEATURE_LONGRUN	(2*32+ 1) /* Longrun power control */
#define X86_FEATURE_LRTI	(2*32+ 3) /* LongRun table interface */

/* Other features, Linux-defined mapping, word 3 */
/* This range is used for feature bits which conflict or are synthesized */
#define X86_FEATURE_CXMMX	(3*32+ 0) /* Cyrix MMX extensions */
#define X86_FEATURE_K6_MTRR	(3*32+ 1) /* AMD K6 nonstandard MTRRs */
#define X86_FEATURE_CYRIX_ARR	(3*32+ 2) /* Cyrix ARRs (= MTRRs) */
#define X86_FEATURE_CENTAUR_MCR	(3*32+ 3) /* Centaur MCRs (= MTRRs) */
/* cpu types for specific tunings: */
#define X86_FEATURE_K8		(3*32+ 4) /* Opteron, Athlon64 */
#define X86_FEATURE_K7		(3*32+ 5) /* Athlon */
#define X86_FEATURE_P3		(3*32+ 6) /* P3 */
#define X86_FEATURE_P4		(3*32+ 7) /* P4 */
#define X86_FEATURE_CONSTANT_TSC (3*32+ 8) /* TSC ticks at a constant rate */
#define X86_FEATURE_NONSTOP_TSC	(3*32+ 9) /* TSC does not stop in C states */
#define X86_FEATURE_ARAT	(3*32+ 10) /* Always running APIC timer */
#define X86_FEATURE_ARCH_PERFMON (3*32+11) /* Intel Architectural PerfMon */
#define X86_FEATURE_TSC_RELIABLE (3*32+12) /* TSC is known to be reliable */

/* Intel-defined CPU features, CPUID level 0x00000001 (ecx), word 4 */
#define X86_FEATURE_XMM3	(4*32+ 0) /* Streaming SIMD Extensions-3 */
#define X86_FEATURE_DTES64	(4*32+ 2) /* 64-bit Debug Store */
#define X86_FEATURE_MWAIT	(4*32+ 3) /* Monitor/Mwait support */
#define X86_FEATURE_DSCPL	(4*32+ 4) /* CPL Qualified Debug Store */
#define X86_FEATURE_VMXE	(4*32+ 5) /* Virtual Machine Extensions */
#define X86_FEATURE_SMXE	(4*32+ 6) /* Safer Mode Extensions */
#define X86_FEATURE_EST		(4*32+ 7) /* Enhanced SpeedStep */
#define X86_FEATURE_TM2		(4*32+ 8) /* Thermal Monitor 2 */
#define X86_FEATURE_SSSE3	(4*32+ 9) /* Supplemental Streaming SIMD Extensions-3 */
#define X86_FEATURE_CID		(4*32+10) /* Context ID */
#define X86_FEATURE_CX16        (4*32+13) /* CMPXCHG16B */
#define X86_FEATURE_XTPR	(4*32+14) /* Send Task Priority Messages */
#define X86_FEATURE_PDCM	(4*32+15) /* Perf/Debug Capability MSR */
#define X86_FEATURE_DCA		(4*32+18) /* Direct Cache Access */
#define X86_FEATURE_SSE4_1	(4*32+19) /* Streaming SIMD Extensions 4.1 */
#define X86_FEATURE_SSE4_2	(4*32+20) /* Streaming SIMD Extensions 4.2 */
#define X86_FEATURE_X2APIC	(4*32+21) /* Extended xAPIC */
#define X86_FEATURE_POPCNT	(4*32+23) /* POPCNT instruction */
#define X86_FEATURE_XSAVE	(4*32+26) /* XSAVE/XRSTOR/XSETBV/XGETBV */
#define X86_FEATURE_OSXSAVE	(4*32+27) /* OSXSAVE */
#define X86_FEATURE_HYPERVISOR	(4*32+31) /* Running under some hypervisor */

/* VIA/Cyrix/Centaur-defined CPU features, CPUID level 0xC0000001, word 5 */
#define X86_FEATURE_XSTORE	(5*32+ 2) /* on-CPU RNG present (xstore insn) */
#define X86_FEATURE_XSTORE_EN	(5*32+ 3) /* on-CPU RNG enabled */
#define X86_FEATURE_XCRYPT	(5*32+ 6) /* on-CPU crypto (xcrypt insn) */
#define X86_FEATURE_XCRYPT_EN	(5*32+ 7) /* on-CPU crypto enabled */
#define X86_FEATURE_ACE2	(5*32+ 8) /* Advanced Cryptography Engine v2 */
#define X86_FEATURE_ACE2_EN	(5*32+ 9) /* ACE v2 enabled */
#define X86_FEATURE_PHE		(5*32+ 10) /* PadLock Hash Engine */
#define X86_FEATURE_PHE_EN	(5*32+ 11) /* PHE enabled */
#define X86_FEATURE_PMM		(5*32+ 12) /* PadLock Montgomery Multiplier */
#define X86_FEATURE_PMM_EN	(5*32+ 13) /* PMM enabled */

/* More extended AMD flags: CPUID level 0x80000001, ecx, word 6 */
#define X86_FEATURE_LAHF_LM	(6*32+ 0) /* LAHF/SAHF in long mode */
#define X86_FEATURE_CMP_LEGACY	(6*32+ 1) /* If yes HyperThreading not valid */
#define X86_FEATURE_SVME        (6*32+ 2) /* Secure Virtual Machine */
#define X86_FEATURE_EXTAPICSPACE (6*32+ 3) /* Extended APIC space */
#define X86_FEATURE_ALTMOVCR	(6*32+ 4) /* LOCK MOV CR accesses CR+8 */
#define X86_FEATURE_ABM		(6*32+ 5) /* Advanced Bit Manipulation */
#define X86_FEATURE_SSE4A	(6*32+ 6) /* AMD Streaming SIMD Extensions-4a */
#define X86_FEATURE_MISALIGNSSE	(6*32+ 7) /* Misaligned SSE Access */
#define X86_FEATURE_3DNOWPF	(6*32+ 8) /* 3DNow! Prefetch */
#define X86_FEATURE_OSVW	(6*32+ 9) /* OS Visible Workaround */
#define X86_FEATURE_IBS		(6*32+ 10) /* Instruction Based Sampling */
#define X86_FEATURE_SSE5	(6*32+ 11) /* AMD Streaming SIMD Extensions-5 */
#define X86_FEATURE_SKINIT	(6*32+ 12) /* SKINIT, STGI/CLGI, DEV */
#define X86_FEATURE_WDT		(6*32+ 13) /* Watchdog Timer */

#define cpu_has(c, bit)		test_bit(bit, (c)->x86_capability)
#define boot_cpu_has(bit)	test_bit(bit, boot_cpu_data.x86_capability)

#ifdef __i386__
#define cpu_has_vme		boot_cpu_has(X86_FEATURE_VME)
#define cpu_has_de		boot_cpu_has(X86_FEATURE_DE)
#define cpu_has_pse		boot_cpu_has(X86_FEATURE_PSE)
#define cpu_has_tsc		boot_cpu_has(X86_FEATURE_TSC)
#define cpu_has_pae		boot_cpu_has(X86_FEATURE_PAE)
#define cpu_has_pge		boot_cpu_has(X86_FEATURE_PGE)
#define cpu_has_pat		boot_cpu_has(X86_FEATURE_PAT)
#define cpu_has_apic		boot_cpu_has(X86_FEATURE_APIC)
#define cpu_has_sep		boot_cpu_has(X86_FEATURE_SEP)
#define cpu_has_mtrr		boot_cpu_has(X86_FEATURE_MTRR)
#define cpu_has_mmx		boot_cpu_has(X86_FEATURE_MMX)
#define cpu_has_fxsr		boot_cpu_has(X86_FEATURE_FXSR)
#define cpu_has_xmm		boot_cpu_has(X86_FEATURE_XMM)
#define cpu_has_xmm2		boot_cpu_has(X86_FEATURE_XMM2)
#define cpu_has_xmm3		boot_cpu_has(X86_FEATURE_XMM3)
#define cpu_has_ht		boot_cpu_has(X86_FEATURE_HT)
#define cpu_has_syscall		boot_cpu_has(X86_FEATURE_SYSCALL)
#define cpu_has_mp		boot_cpu_has(X86_FEATURE_MP)
#define cpu_has_nx		boot_cpu_has(X86_FEATURE_NX)
#define cpu_has_k6_mtrr		boot_cpu_has(X86_FEATURE_K6_MTRR)
#define cpu_has_cyrix_arr	boot_cpu_has(X86_FEATURE_CYRIX_ARR)
#define cpu_has_centaur_mcr	boot_cpu_has(X86_FEATURE_CENTAUR_MCR)
#define cpu_has_clflush		boot_cpu_has(X86_FEATURE_CLFLSH)
#define cpu_has_page1gb		0
#define cpu_has_efer		(boot_cpu_data.x86_capability[1] & 0x20100800)
#else /* __x86_64__ */
#define cpu_has_vme		0
#define cpu_has_de		1
#define cpu_has_pse		1
#define cpu_has_tsc		1
#define cpu_has_pae		1
#define cpu_has_pge		1
#define cpu_has_pat		1
#define cpu_has_apic		boot_cpu_has(X86_FEATURE_APIC)
#define cpu_has_sep		boot_cpu_has(X86_FEATURE_SEP)
#define cpu_has_mtrr		1
#define cpu_has_mmx		1
#define cpu_has_fxsr		1
#define cpu_has_xmm		1
#define cpu_has_xmm2		1
#define cpu_has_xmm3		boot_cpu_has(X86_FEATURE_XMM3)
#define cpu_has_ht		boot_cpu_has(X86_FEATURE_HT)
#define cpu_has_syscall		1
#define cpu_has_mp		1
#define cpu_has_nx		boot_cpu_has(X86_FEATURE_NX)
#define cpu_has_k6_mtrr		0
#define cpu_has_cyrix_arr	0
#define cpu_has_centaur_mcr	0
#define cpu_has_clflush		boot_cpu_has(X86_FEATURE_CLFLSH)
#define cpu_has_page1gb		boot_cpu_has(X86_FEATURE_PAGE1GB)
#define cpu_has_efer		1
#endif

#define cpu_has_ffxsr           ((boot_cpu_data.x86_vendor == X86_VENDOR_AMD) \
                                 && boot_cpu_has(X86_FEATURE_FFXSR))

#define cpu_has_x2apic          boot_cpu_has(X86_FEATURE_X2APIC)

#define cpu_has_xsave           boot_cpu_has(X86_FEATURE_XSAVE)

#define cpu_has_arch_perfmon    boot_cpu_has(X86_FEATURE_ARCH_PERFMON)

#endif /* __ASM_I386_CPUFEATURE_H */

/* 
 * Local Variables:
 * mode:c
 * comment-column:42
 * End:
 */

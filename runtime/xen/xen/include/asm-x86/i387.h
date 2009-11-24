/*
 * include/asm-i386/i387.h
 *
 * Copyright (C) 1994 Linus Torvalds
 *
 * Pentium III FXSR, SSE support
 * General FPU state handling cleanups
 *	Gareth Hughes <gareth@valinux.com>, May 2000
 */

#ifndef __ASM_I386_I387_H
#define __ASM_I386_I387_H

#include <xen/sched.h>
#include <asm/processor.h>

extern unsigned int xsave_cntxt_size;
extern u32 xfeature_low, xfeature_high;

extern void xsave_init(void);
extern void xsave_init_save_area(void *save_area);

#define XSTATE_FP       (1 << 0)
#define XSTATE_SSE      (1 << 1)
#define XSTATE_YMM      (1 << 2)
#define XSTATE_FP_SSE   (XSTATE_FP | XSTATE_SSE)
#define XCNTXT_MASK     (XSTATE_FP | XSTATE_SSE | XSTATE_YMM)
#define XSTATE_YMM_OFFSET  (512 + 64)
#define XSTATE_YMM_SIZE    256

struct xsave_struct
{
    struct { char x[512]; } fpu_sse;         /* FPU/MMX, SSE */

    struct {
        u64 xstate_bv;
        u64 reserved[7];
    } xsave_hdr;                            /* The 64-byte header */

    struct { char x[XSTATE_YMM_SIZE]; } ymm; /* YMM */
    char   data[];                           /* Future new states */
} __attribute__ ((packed, aligned (64)));

#define XCR_XFEATURE_ENABLED_MASK   0

#ifdef CONFIG_X86_64
#define REX_PREFIX "0x48, "
#else
#define REX_PREFIX
#endif

static inline void xsetbv(u32 index, u64 xfeature_mask)
{
    u32 hi = xfeature_mask >> 32;
    u32 lo = (u32)xfeature_mask;

    asm volatile (".byte 0x0f,0x01,0xd1" :: "c" (index),
            "a" (lo), "d" (hi));
}

static inline void set_xcr0(u64 xfeature_mask)
{
    xsetbv(XCR_XFEATURE_ENABLED_MASK, xfeature_mask);
}

static inline void xsave(struct vcpu *v)
{
    u64 mask = v->arch.hvm_vcpu.xfeature_mask | XSTATE_FP_SSE;
    u32 lo = mask, hi = mask >> 32;
    struct xsave_struct *ptr;

    ptr =(struct xsave_struct *)v->arch.hvm_vcpu.xsave_area;

    asm volatile (".byte " REX_PREFIX "0x0f,0xae,0x27"
        :
        : "a" (lo), "d" (hi), "D"(ptr)
        : "memory");
}

static inline void xrstor(struct vcpu *v)
{
    u64 mask = v->arch.hvm_vcpu.xfeature_mask | XSTATE_FP_SSE;
    u32 lo = mask, hi = mask >> 32;
    struct xsave_struct *ptr;

    ptr =(struct xsave_struct *)v->arch.hvm_vcpu.xsave_area;

    asm volatile (".byte " REX_PREFIX "0x0f,0xae,0x2f"
        :
        : "m" (*ptr), "a" (lo), "d" (hi), "D"(ptr));
}

extern void init_fpu(void);
extern void save_init_fpu(struct vcpu *v);
extern void restore_fpu(struct vcpu *v);

#define unlazy_fpu(v) do {                      \
    if ( (v)->fpu_dirtied )                     \
        save_init_fpu(v);                       \
} while ( 0 )

#define load_mxcsr(val) do {                                    \
    unsigned long __mxcsr = ((unsigned long)(val) & 0xffbf);    \
    __asm__ __volatile__ ( "ldmxcsr %0" : : "m" (__mxcsr) );    \
} while ( 0 )

static inline void setup_fpu(struct vcpu *v)
{
    /* Avoid recursion. */
    clts();

    if ( !v->fpu_dirtied )
    {
        v->fpu_dirtied = 1;
        if ( cpu_has_xsave && is_hvm_vcpu(v) )
        {
            if ( !v->fpu_initialised )
                v->fpu_initialised = 1;

            set_xcr0(v->arch.hvm_vcpu.xfeature_mask | XSTATE_FP_SSE);
            xrstor(v);
            set_xcr0(v->arch.hvm_vcpu.xfeature_mask);
        }
        else
        {
            if ( v->fpu_initialised )
                restore_fpu(v);
            else
                init_fpu();
        }
    }
}

#endif /* __ASM_I386_I387_H */

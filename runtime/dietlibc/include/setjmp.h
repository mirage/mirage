#ifndef _SETJMP_H
#define _SETJMP_H

#include <sys/cdefs.h>

__BEGIN_DECLS

#ifdef __i386__
#ifndef __ASSEMBLER__
typedef long __jmp_buf[6];
#endif
# define JB_BX	0
# define JB_SI	1
# define JB_DI	2
# define JB_BP	3
# define JB_SP	4
# define JB_PC	5
# define JB_SIZE 24
#endif

#ifdef __x86_64__
#ifndef __ASSEMBLER__
typedef long __jmp_buf[8];
#endif
# define JB_RBX	0
# define JB_RBP	1
# define JB_R12	2
# define JB_R13	3
# define JB_R14	4
# define JB_R15	5
# define JB_RSP	6
# define JB_PC	7
# define JB_SIZE 64
#endif

#ifdef __s390__
#ifndef __ASSEMBLER__
typedef struct {
  long int gregs[10];
  long fpregs[4];
} __jmp_buf[1];
#endif
#define __JB_GPR6	0
#define __JB_GPR7	1
#define __JB_GPR8	2
#define __JB_GPR9	3
#define __JB_GPR10	4
#define __JB_GPR11	5
#define __JB_GPR12	6
#define __JB_GPR13	7
#define __JB_GPR14	8
#define __JB_GPR15	9

#define _JMPBUF_UNWINDS(jmpbuf, address) ((int) (address) < (jmpbuf)->gregs[__JB_GPR15])
#endif

#ifdef __alpha__
#define JB_S0  0
#define JB_S1  1
#define JB_S2  2
#define JB_S3  3
#define JB_S4  4
#define JB_S5  5
#define JB_PC  6
#define JB_FP  7
#define JB_SP  8
#define JB_F2  9
#define JB_F3  10
#define JB_F4  11
#define JB_F5  12
#define JB_F6  13
#define JB_F7  14
#define JB_F8  15
#define JB_F9  16
#ifndef __ASSEMBLER__
typedef long int __jmp_buf[17];
#endif
#endif

#ifdef __mips__
#ifndef __ASSEMBLER__
typedef struct
  {
    void * __pc;	/* Program counter.  */
    void * __sp;	/* Stack pointer.  */
    int __regs[8];	/* Callee-saved registers s0 through s7.  */
    void * __fp;	/* The frame pointer.  */
    void * __gp;	/* The global pointer.  */
    int __fpc_csr;	/* Floating point status register.  */
    double __fpregs[6];	/* Callee-saved floating point registers.  */
  } __jmp_buf[1];
#endif
#endif

#ifdef __sparc__
#ifdef __arch64__

#define MC_TSTATE	0
#define MC_PC		1
#define MC_NPC		2
#define MC_Y		3
#define MC_G1		4
#define MC_G2		5
#define MC_G3		6
#define MC_G4		7
#define MC_G5		8
#define MC_G6		9
#define MC_G7		10
#define MC_O0		11
#define MC_O1		12
#define MC_O2		13
#define MC_O3		14
#define MC_O4		15
#define MC_O5		16
#define MC_O6		17
#define MC_O7		18
#define MC_NGREG	19

#define FLAG_SAVEMASK	512
#ifndef __ASSEMBLER__
#include <signal.h>

/* this equal to ucontext from "include/asm-sparc64/uctx.h" */
typedef struct __sparc64_jmp_buf {
  struct __sparc64_jmp_buf *uc_link;
  unsigned long uc_flags;
  sigset_t uc_sigmask;
  struct {
    unsigned long	mc_gregs[MC_NGREG];
    unsigned long	mc_fp;
    unsigned long	mc_i7;
    struct {
      union {
	unsigned int	sregs[32];
	unsigned long	dregs[32];
	long double	qregs[16];
      } mcfpu_fregs;
      unsigned long	mcfpu_fsr;
      unsigned long	mcfpu_fprs;
      unsigned long	mcfpu_gsr;
      struct {
	unsigned long	*mcfq_addr;
	unsigned int	mcfq_insn;
      } *mcfpu_fq;
      unsigned char	mcfpu_qcnt;
      unsigned char	mcfpu_qentsz;
      unsigned char	mcfpu_enab;
    } mc_fpregs;
  } uc_mcontext;
} __jmp_buf[1];

#endif

#else

#define JB_SP  0
#define JB_FP  1
#define JB_PC  2
#ifndef __ASSEMBLER__
typedef int __jmp_buf[3];
#endif

#endif
#endif

#ifdef __arm__
#define __JMP_BUF_SP            8
#ifndef __ASSEMBLER__
typedef int __jmp_buf[24];
#endif
#endif

#if defined(__powerpc__) || defined(__powerpc64__)
/* 40 registers: 22 GPRs (4 or 8 bytes) + 18 FPRs (8 bytes) */
#define JB_GPR1   0  /* Also known as the stack pointer */
#define JB_GPR2   1
#define JB_LR     2  /* The address we will return to */
#define JB_GPRS   3  /* GPRs 14 through 31 are saved, 18 in total */
#define JB_CR     21 /* Condition code registers. */
#define JB_FPRS   22 /* FPRs 14 through 31 are saved, 18*2 words total */
#if defined(__powerpc64__)
#define JB_SIZE   (40*8)
#ifndef __ASSEMBLER__
typedef long __jmp_buf[40];
#endif
#else
#define JB_SIZE   (58*4)	/* == 22*4 + 18*8 */
#ifndef __ASSEMBLER__
typedef long __jmp_buf[58] __attribute__ ((__aligned__(8)));
#endif
#endif
#endif

#ifdef __hppa__
#ifndef __ASSEMBLER__
typedef double __jmp_buf[21];
#endif
#endif

#ifdef __ia64__
#ifndef __ASSEMBLER__
typedef long __jmp_buf[70] __attribute__ ((__aligned__(16)));
#endif
#endif

#ifndef __ASSEMBLER__
#include <signal.h>

/* typedef int sig_atomic_t; */
#define __sig_atomic_t sig_atomic_t

/* Calling environment, plus possibly a saved signal mask.  */
typedef struct __jmp_buf_tag {	/* C++ doesn't like tagless structs.  */
/* NOTE: The machine-dependent definitions of `__sigsetjmp'
 * assume that a `jmp_buf' begins with a `__jmp_buf'.
 * Do not move this member or add others before it.  */
  __jmp_buf __jmpbuf;		/* Calling environment.  */
  int __mask_was_saved;		/* Saved the signal mask?  */
  sigset_t __saved_mask;	/* Saved signal mask.  */
} jmp_buf[1];

extern int __sigsetjmp(jmp_buf __env,int __savemask) __THROW;

extern void longjmp(jmp_buf __env,int __val)
     __THROW __attribute__((__noreturn__));

typedef jmp_buf sigjmp_buf;

extern void siglongjmp(sigjmp_buf __env,int __val)
     __THROW __attribute__((__noreturn__));

#ifdef _BSD_SOURCE
#define setjmp(env) __sigsetjmp(env,1)
#else
#define setjmp(env) __sigsetjmp(env,0)
#endif
#define sigsetjmp(a,b) __sigsetjmp(a,b)

#endif

__END_DECLS

#endif

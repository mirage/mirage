/* This is a simple version of setjmp and longjmp for MIPS 32 and 64.

   Ian Lance Taylor, Cygnus Support, 13 May 1993.  */

#ifdef __mips16
/* This file contains 32 bit assembly code.  */
	.set nomips16
#endif

#define GPR_LAYOUT		\
	GPR_OFFSET ($16, 0);	\
	GPR_OFFSET ($17, 1);	\
	GPR_OFFSET ($18, 2);	\
	GPR_OFFSET ($19, 3);	\
	GPR_OFFSET ($20, 4);	\
	GPR_OFFSET ($21, 5);	\
	GPR_OFFSET ($22, 6);	\
	GPR_OFFSET ($23, 7);	\
	GPR_OFFSET ($29, 8);	\
	GPR_OFFSET ($30, 9);	\
	GPR_OFFSET ($31, 10)

#define NUM_GPRS_SAVED 11

#ifdef __mips_hard_float
#define FPR_LAYOUT		\
	FPR_OFFSET ($f20, 0);	\
	FPR_OFFSET ($f21, 1);	\
	FPR_OFFSET ($f22, 2);	\
	FPR_OFFSET ($f23, 3);	\
	FPR_OFFSET ($f24, 4);	\
	FPR_OFFSET ($f25, 5);	\
	FPR_OFFSET ($f26, 6);	\
	FPR_OFFSET ($f27, 7);	\
	FPR_OFFSET ($f28, 8);	\
	FPR_OFFSET ($f29, 9);	\
	FPR_OFFSET ($f30, 10);	\
	FPR_OFFSET ($f31, 11)
#else
#define FPR_LAYOUT
#endif

#ifdef __mips64
#define BYTES_PER_WORD 8
#define LOAD_GPR ld
#define LOAD_FPR ldc1
#define STORE_GPR sd
#define STORE_FPR sdc1
#else
#define BYTES_PER_WORD 4
#define LOAD_GPR lw
#define LOAD_FPR lwc1
#define STORE_GPR sw
#define STORE_FPR swc1
#endif

#define GPOFF(INDEX) (INDEX * BYTES_PER_WORD)
#define FPOFF(INDEX) ((INDEX + NUM_GPRS_SAVED) * BYTES_PER_WORD)

/* int setjmp (jmp_buf);  */
	.globl	setjmp
	.ent	setjmp
setjmp:
	.frame	$sp,0,$31

#define GPR_OFFSET(REG, INDEX) STORE_GPR REG,GPOFF(INDEX)($4)
#define FPR_OFFSET(REG, INDEX) STORE_FPR REG,FPOFF(INDEX)($4)
	GPR_LAYOUT
	FPR_LAYOUT
#undef GPR_OFFSET
#undef FPR_OFFSET

	move	$2,$0
	j	$31

	.end	setjmp

/* volatile void longjmp (jmp_buf, int);  */
	.globl	longjmp
	.ent	longjmp
longjmp:
	.frame	$sp,0,$31

#define GPR_OFFSET(REG, INDEX) LOAD_GPR REG,GPOFF(INDEX)($4)
#define FPR_OFFSET(REG, INDEX) LOAD_FPR REG,FPOFF(INDEX)($4)
	GPR_LAYOUT
	FPR_LAYOUT
#undef GPR_OFFSET
#undef FPR_OFFSET

	bne	$5,$0,1f
	li	$5,1
1:
	move	$2,$5
	j	$31

	.end longjmp

	
    .file   "crt0.S"
	
#define XGLUE(a,b) a##b
#define GLUE(a,b) XGLUE(a,b)
	
#ifdef __USER_LABEL_PREFIX__
#define SYM_NAME( name ) GLUE (__USER_LABEL_PREFIX__, name)
#else
#error __USER_LABEL_PREFIX is not defined
#endif

    .text
     /* Setup the assembly entry point.  */
#ifdef __thumb2__
.macro FUNC_START name
	.global \name
	.thumb_func
\name:
.endm
	.syntax unified
	.thumb
#else
.macro FUNC_START name
	.global \name
\name:
.endm
	.code 32
#endif
	FUNC_START SYM_NAME(start)
	FUNC_START SYM_NAME(_start)
	mov	fp, #0	/* Null frame pointer.  */
	mov	r7, #0	/* Null frame pointer for Thumb.  */

	/* Enable interrupts for gdb debugging.  */
#ifdef __thumb2__
	cpsie if
#else
	mrs    r0, cpsr
	bic    r0, r0, #0xC0
	msr    cpsr, r0
#endif
	
	mov 	a2, #0			/* Second arg: fill value.  */
	ldr	a1, .LC1		/* First arg: start of memory block.  */
	ldr	a3, .LC2	
	sub	a3, a3, a1		/* Third arg: length of block.  */

#ifdef	GCRT0
	/* Zero out the bss without using memset. 
	   Using memset is bad because it may be instrumented for
	   profiling, but at this point, the profiling data structures
	   have not been set up. 
	   FIXME: This loop could be a lot more efficient.  */
	subs	a3, a3, #0
	beq	2f
1:	strb	a2, [a1]
	subs	a3, a3, #1
	add	a1, a1, #1
	bne	1b
2:	
	/* Nothing to left to clear.  */
#endif

#if defined(__thumb__) && !defined(__thumb2__)	/* Enter Thumb mode. */
	add	a4, pc, #1	/* Get the address of the Thumb block.  */
	bx	a4		/* Go there and start Thumb decoding.   */

	.code 16
	.global __change_mode
	.thumb_func
__change_mode:	
#endif

#ifndef	GCRT0
	bl	SYM_NAME(memset)
#endif
	bl	SYM_NAME(__get_memtop)
	sub	r0, r0, #32
	mov	sp, r0

#ifdef __USES_INITFINI__
	/* Some arm/elf targets use the .init and .fini sections
	   to create constructors and destructors, and for these
	   targets we need to call the _init function and arrange
	   for _fini to be called at program exit.  */
	ldr	r0, .Lfini
	bl	SYM_NAME (atexit)
	bl	SYM_NAME (_init)
#endif	

	mov 	a1, #0
	ldr	a2, .LC3
	mov	a3, a2
	bl	SYM_NAME(main)
    1:	bl	SYM_NAME(exit)
	b	1b
	.align	2
.LC1:
	.word	__bss_start__
.LC2:
	.word	__bss_end__
.LC3:
	.word	0
#ifdef __USES_INITFINI__
.Lfini:
	.word	SYM_NAME(_fini)
#endif
#if 0
#ifdef __thumb__
	.code 16
#endif
	.global SYM_NAME(__syscall)
#ifdef __thumb__
        .thumb_func
#else
	.align  4
#endif
SYM_NAME(__syscall):
	mov	r12, lr
#ifdef __thumb__
	swi	0x18
#else
	swi	0x180001
#endif
	mov	pc, r12
#endif

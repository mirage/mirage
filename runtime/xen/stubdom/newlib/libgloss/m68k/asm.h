/* asm.h -- macros for m68k asm
 *
 * Copyright (c) 1995, 1996 Cygnus Support
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

#if 0
/*
 * XXX __USER_LABEL_PREFIX__ and __REGISTER_PREFIX__ do not work on gcc 2.7.0-3
 * XXX The following ifdef magic fixes the problem but results in a warning
 * XXX when compiling assembly code.
 */
#ifndef __USER_LABEL_PREFIX__
/* #define __USER_LABEL_PREFIX__ ""	/* no underscore for coff */
#define __USER_LABEL_PREFIX__ _		/* leading underscore for aout */
#endif

#ifndef __REGISTER_PREFIX__
#define __REGISTER_PREFIX__ 		/* never has anything prefixed */
#endif
#endif

/*
 * some assemblers choke on '#' as an immediate value. As gcc can also
 * use '&', use that in those cases. 
 */
#ifndef __IMMEDIATE_PREFIX__
#define __IMMEDIATE_PREFIX__ #
#endif

/* ANSI concatenation macros.  */
#define CONCAT1(a, b) CONCAT2(a, b)
#define CONCAT2(a, b) a ## b

/* use the right prefix for global labels.  */
#define SYM(x) CONCAT1 (__USER_LABEL_PREFIX__,x)

/* use the right prefix for registers.  */
#define REG(x) CONCAT1 (__REGISTER_PREFIX__,x)

/* use the right prefix for immediate values.  */
#define IMM(x) CONCAT1 (__IMMEDIATE_PREFIX__,x)

/* use the right prefix for register names */
#define d0 REG (d0)
#define d1 REG (d1)
#define d2 REG (d2)
#define d3 REG (d3)
#define d4 REG (d4)
#define d5 REG (d5)
#define d6 REG (d6)
#define d7 REG (d7)
#define a0 REG (a0)
#define a1 REG (a1)
#define a2 REG (a2)
#define a3 REG (a3)
#define a4 REG (a4)
#define a5 REG (a5)
#define a6 REG (a6)
#define a7 REG (a7)
#define fp REG (fp)
#define fp0 REG (fp0)
#define fp1 REG (fp1)
#define fp2 REG (fp2)
#define fp3 REG (fp3)
#define fp4 REG (fp4)
#define fp5 REG (fp5)
#define fp6 REG (fp6)
#define fp7 REG (fp7)
#define sp REG (sp)
#define usp REG (usp)
#define vbr REG (vbr)
#define mbb REG (mbb)
#define sr REG (sr)
#define fpcr REG (fpcr)
#define fpsr REG (fpsr)
#define fpi REG (fpi)

/* Provide a few macros to allow for PIC code support.
 * With PIC, data is stored A5 relative so we've got to take a bit of special
 * care to ensure that all loads of global data is via A5.  PIC also requires
 * jumps and subroutine calls to be PC relative rather than absolute.  We cheat
 * a little on this and in the PIC case, we use short offset branches and
 * hope that the final object code is within range (which it should be).
 */
#ifndef __PIC__

	/* Non PIC (absolute/relocatable) versions */

	.macro PICCALL addr
	jbsr	\addr
	.endm

	.macro PICJUMP addr
	jmp	\addr
	.endm

	.macro PICLEA sym, reg
	lea	\sym, \reg
	.endm

	.macro PICPEA sym, areg
	pea	\sym
	.endm

#else /* __PIC__ */

	/* Common for -mid-shared-libary and -msep-data */

	.macro PICCALL addr
	bsr	\addr
	.endm

	.macro PICJUMP addr
	bra	\addr
	.endm

# if defined(__ID_SHARED_LIBRARY__)

	/* -mid-shared-library versions  */

	.macro PICLEA sym, reg
	movel	a5@(_current_shared_library_a5_offset_), \reg
	movel	\sym@GOT(\reg), \reg
	.endm

	.macro PICPEA sym, areg
	movel	a5@(_current_shared_library_a5_offset_), \areg
	movel	\sym@GOT(\areg), sp@-
	.endm

# else /* !__ID_SHARED_LIBRARY__ */

	/* Versions for -msep-data */

	.macro PICLEA sym, reg
	movel	\sym@GOT(a5), \reg
	.endm

	.macro PICPEA sym, areg
	movel	\sym@GOT(a5), sp@-
	.endm

# endif /* !__ID_SHARED_LIBRARY__ */
#endif /* __PIC__ */


/* crt0.S -- startup file for frv.
 * 
 * Copyright (c) 2002, 2003 Red Hat, Inc
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

#include <frv-asm.h>

	/* statically store .Lcall's address so we can see if we are running
	   at the location we were linked for or a different location.  */
	.data
	.type	EXT(__start_cmp),@object
	.size	EXT(__start_cmp),4
	.p2align 2
EXT(__start_cmp):
	.picptr	 .Lcall
	
	.globl	__start
	.weak	_start
	.text
	.type	__start,@function
__start:
_start:
	call	.Lcall				/* set up _gp in a pic-friendly manor */
.Lcall:	movsg	lr, gr4
	P(sethi) #gprelhi(.Lcall), gr5
	setlo	 #gprello(.Lcall), gr5
	P(sub)	 gr4, gr5, gr16

#if ! __FRV_FDPIC__
	sethi	 #gprelhi(EXT(_stack)), sp	/* load up stack pointer */
	P(setlo) #gprello(EXT(_stack)), sp
	setlos   #0, fp				/* zero fp to allow unwinders to stop */
	P(add)	 sp, gr16, sp

#define FDPIC(...)
#else
#define FDPIC(...) __VA_ARGS__
	
	/* The assembler will rightfully claim that
	#hi/lo(__stacksize) are unsafe for PIC, but since __stacksize
	is absolute, and we don't want it to be relocated, we should
	be fine.  */

	sethi	#gprelhi(EXT(__end)), gr6
	P(sethi) #hi(EXT(__stacksize+7)), gr5
	setlo	#gprello(EXT(__end)), gr6
	P(setlo) #lo(EXT(__stacksize+7)), gr5
	add	gr6, gr16, gr6
	add	gr6, gr5, gr5
	andi	gr5, -8, sp

	/* Using GPREL to compute _GLOBAL_OFFSET_TABLE_'s will force
	the entire program to relocate as a unit, which is fine for
	frv-elf.  */
	
	P(sethi) #gprelhi(EXT(_GLOBAL_OFFSET_TABLE_)), gr15
	setlo    #gprello(EXT(_GLOBAL_OFFSET_TABLE_)), gr15
	/* We compute the value in a call-saved register (that happens
	to be the PIC register in the EABI, and copy it to gr15 before
	every call.  */
	add	 gr15, gr16, gr17
#endif

	sethi	 #gprelhi(EXT(__start_cmp)), gr5
	setlo    #gprello(EXT(__start_cmp)), gr5
	ld	 @(gr5,gr16), gr6
	subcc	gr4, gr6, gr8, icc0
	beq	icc0, 0, .Lfixed

	P(st)	gr4, @(gr5, gr16)	/* update so if we restart no need to fixup */
	setlos	4, gr11

#if ! __FRV_FDPIC__

					/* fixup the .ctors list */
	sethi	 #gprelhi(EXT(__CTOR_LIST__)), gr9
	P(sethi) #gprelhi(EXT(__CTOR_END__)), gr10
	setlo	 #gprello(EXT(__CTOR_LIST__)), gr9
	P(setlo) #gprello(EXT(__CTOR_END__)), gr10
	add	 gr9, gr16, gr9
	P(add)	 gr10, gr16, gr10
	addi	 gr9, 4, gr9
	P(subi)	 gr10, 4, gr10
	call	 EXT(__frv_fixptrs)

					/* fixup the .dtors list */
	P(sethi) #gprelhi(EXT(__DTOR_LIST__)), gr9
	sethi	 #gprelhi(EXT(__DTOR_END__)), gr10
	P(setlo) #gprello(EXT(__DTOR_LIST__)), gr9
	setlo	 #gprello(EXT(__DTOR_END__)), gr10
	P(add)	 gr9, gr16, gr9
	add	 gr10, gr16, gr10
	P(addi)	 gr9, 4, gr9
	subi	 gr10, 4, gr10
	call	 EXT(__frv_fixptrs)
#endif /* ! __FRV_FDPIC__ */

					/* fixup the user .rofixup list */
	P(sethi) #gprelhi(EXT(__ROFIXUP_LIST__)), gr9
	sethi	 #gprelhi(EXT(__ROFIXUP_END__)), gr10
	P(setlo) #gprello(EXT(__ROFIXUP_LIST__)), gr9
	setlo	 #gprello(EXT(__ROFIXUP_END__)), gr10
	P(add)	 gr9, gr16, gr9
	add	 gr10, gr16, gr10
	FDPIC(mov gr17, gr15)
	call	 EXT(__frv_fix_usrptrs)

.Lfixed:

/* HSR flags */
#define HSR_ICE  0x80000000		/* Instruction cache enable */
#define HSR_DCE  0x40000000		/* Data cache enable */
#define HSR_CBM  0x08000000		/* Cache copy back mode */
#define HSR_EIMM 0x04000000		/* Enable Instruction MMU */
#define HSR_EDMM 0x02000000		/* Enable Data MMU */
#define HSR_EMEM 0x00800000		/* Enable MMU miss exception mask */
#define HSR_RME  0x00400000		/* Ram mode enable */
#define HSR_SA   0x00001000		/* Start address */
#define HSR_FRN  0x00000800		/* Number of FPRs */
#define HSR_GRN  0x00000400		/* Number of GPRs */
#define HSR_FRHE 0x00000200		/* FR Higher Enable */
#define HSR_FRLE 0x00000100		/* FR Lower Enable */
#define HSR_GRHE 0x00000080		/* GR Higher Enable */
#define HSR_GRLE 0x00000040		/* GR Lower Enable */

#ifndef HSR_CLEAR
#define HSR_CLEAR 0
#endif

#ifndef HSR_SET
#ifndef FRV_NO_CACHE
#define HSR_SET (HSR_ICE|HSR_DCE|HSR_FRHE|HSR_FRLE|HSR_GRHE|HSR_GRLE)
#else
#define HSR_SET (HSR_FRHE|HSR_FRLE|HSR_GRHE|HSR_GRLE)
#endif
#endif

/* PSR flags */
#define PSR_ICE  0x00010000		/* In circuit emulation mode */
#define PSR_NEM  0x00004000		/* Non-exception mode */
#define PSR_CM   0x00002000		/* Conditional mode */
#define PSR_BE   0x00001000		/* Big endian mode */
#define PSR_EF   0x00000100		/* Enable floating point */
#define PSR_EM   0x00000080		/* Enable media instructions */
#define PSR_S    0x00000004		/* Enable supervisor mode */
#define PSR_PS   0x00000002		/* Previous supervisor mode */
#define PSR_ET   0x00000001		/* Enable interrupts */

#ifndef PSR_CLEAR
#if __FRV_FPR__
#define PSR_CLEAR 0
#else
#define PSR_CLEAR (PSR_EF|PSR_EM)
#endif
#endif

#ifndef PSR_SET
#if __FRV_FPR__
#define PSR_SET (PSR_NEM|PSR_CM|PSR_EF|PSR_EM)
#else
#define PSR_SET (PSR_NEM|PSR_CM)
#endif
#endif

	/* Enable floating point */
	movsg	  hsr0, gr4
	P(sethi)  #hi(HSR_SET), gr5
	setlo	  #lo(HSR_SET), gr5
	P(sethi)  #hi(~HSR_CLEAR), gr6
	setlo     #lo(~HSR_CLEAR), gr6
	or	  gr4, gr5, gr4
	and	  gr4, gr6, gr4
	movgs	  gr4, hsr0

	movsg	  psr, gr4
	P(sethi)  #hi(PSR_SET), gr5
	setlo	  #lo(PSR_SET), gr5
	P(sethi)  #hi(~PSR_CLEAR), gr6
	setlo     #lo(~PSR_CLEAR), gr6
	or	  gr4, gr5, gr4
	and	  gr4, gr6, gr4
	movgs	  gr4, psr

	/* zero the bss area */
	P(sethi)  #gprelhi(__bss_start), gr8
	sethi	  #gprelhi(__end), gr4
	P(setlo)  #gprello(__bss_start), gr8
	setlo	  #gprello(__end), gr4
	P(add)	  gr8, gr16, gr8
	add	  gr4, gr16, gr4
	P(setlos) #0, gr9
	sub	  gr4, gr8, gr10
	FDPIC(mov gr17, gr15)
	call	  EXT(memset)

	P(setlos) #0, gr8		/* zero argc, argv, envp */
	setlos	  #0, gr9
	P(setlos) #0, gr10

	FDPIC(mov gr17, gr15)
	call	  EXT(main)
	FDPIC(mov gr17, gr15)
	call	  EXT(exit)
.Lend:
	.size	__start,(.Lend-__start)

#if ! __FRV_FDPIC__
	/* Routine to adjust pointers
	   gr8  = difference to adjust by
	   gr9  = starting address
	   gr10 = ending address + 4
	   gr11 = amount to add to the pointer each iteration.  */
	.globl	EXT(__frv_fixptrs)
	.type	EXT(__frv_fixptrs),@function
EXT(__frv_fixptrs):
	P(sub)	gr9, gr11, gr9
	sub	gr10, gr11, gr10
.Lloop2:
	cmp	gr10, gr9, icc0
	bls	icc0, 0, .Lret2

	ldu	@(gr9,gr11), gr5
	add	gr8, gr5, gr5
	P(st)	gr5, @(gr9,gr0)
	bra	.Lloop2

.Lret2:	ret
.Lend2:
	.size	EXT(__frv_fixptrs),.Lend2-EXT(__frv_fixptrs)
#endif /* ! __FRV_FDPIC__ */

	/* Routine to adjust statically initialized pointers
	   Note since these are pointers to pointers, they
	   need to be adjusted themsevles.

	   gr8  = difference to adjust by
	   gr9  = starting address
	   gr10 = ending address + 4
	   gr11 = amount to add to the pointer each iteration.  */
	.globl	EXT(__frv_fix_usrptrs)
	.type	EXT(__frv_fix_usrptrs),@function
EXT(__frv_fix_usrptrs):
	P(sub)	gr9, gr11, gr9
	sub	gr10, gr11, gr10
.Lloop3:
	cmp	gr10, gr9, icc0
	bls	icc0, 0, .Lret3

	ldu	@(gr9,gr11), gr5
	ld	@(gr5, gr8), gr6
	cmp	gr6, gr0, icc0		/* skip pointers initialized to 0 */
	beq	icc0, 0, .Lloop3

	add	gr8, gr6, gr6
	P(st)	gr6, @(gr5,gr8)
	bra	.Lloop3

.Lret3:	ret
.Lend3:
	.size	EXT(__frv_fix_usrptrs),.Lend2-EXT(__frv_fix_usrptrs)

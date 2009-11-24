/*
 * C startup code for the Fujitsu SPARClite demo board
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
#include "asm.h"
	
.data
        .align  8
	.ascii	"DaTa"		! this is the first address in the data section
	.long	SYM(sdata)
SYM(environ):
        .long   0

	.text
	.align 8

	.globl SYM(_start)
SYM(_start):
	.globl SYM(start)
SYM(start):
	/* see if the stack is already setup. if not, then default
         *  to using the value of %sp as set by the ROM monitor
         */
	sethi	%hi(__stack), %g1
        or      %g1,%lo(__stack),%g1
        cmp     %g0,%g1
        be      1f
	mov	%g1, %sp				! set the stack pointer
        mov     %sp, %fp
1:	

	/* zero the bss section */
        sethi %hi(__bss_start),%g2
        or    %g2,%lo(__bss_start),%g2		! start of bss
        sethi %hi(_end),%g3
        or    %g3,%lo(_end),%g3			! end of bss
        mov   %g0,%g1				! so std has two zeros
zerobss:
        std    %g0,[%g2]
        add    %g2,8,%g2
        cmp    %g2,%g3
        bleu,a zerobss
        nop
	
/*
 * copy prom & trap vectors to sram.
 */
	set 0x30000000, %l0
	set 0xfff8, %l1
	tst %l1					! Set condition codes

copyloop:
	ldd [%l1], %l2
	std %l2, [%l0 + %l1]
	bg copyloop
	deccc 8, %l1

	set 0x30000000, %l0			! Base of new trap vector
	mov %l0, %tbr				! Install the new tbr

	set SYM(win_ovf_trap), %l1		! Setup window overflow trap
	ldd [%l1], %l2
	std %l2, [%l0 + 5 * 16]
	ldd [%l1 + 8], %l2
	std %l2, [%l0 + 5 * 16 + 8]

	set SYM(win_unf_trap), %l1		! Setup window underflow trap
	ldd [%l1], %l2
	std %l2, [%l0 + 6 * 16]
	ldd [%l1 + 8], %l2
	std %l2, [%l0 + 6 * 16 + 8]

/*
 * Try enabling the FPU by setting EF.  If that causes a trap, then we probably
 * don't have an FPU.
 */

	ldd [%l0 + 2 * 16], %l4			! Save original trap routine
	set SYM(no_fpu_trap), %l1		! Install new one
	ldd [%l1], %l2
	std %l2, [%l0 + 2 * 16]

	mov %psr, %l0
	sethi %hi(0x1000), %l1
	bset %l1, %l0
!	mov %l0, %psr

	std %l4, [2 * 16]			! Restore original trap routine


/*
 * Move the data segment from it's ROM address to RAM where it
 * belongs. 
 */

relocd:
#if 0	/* This code is broken.  FIXME */
        set (_sdata),%g2			! %g2 = start of data in aout file
        set SYM(environ),%g4			! %g4 = actual data base address
        set (_edata),%g3			! %g3 = end of where data should go
        subcc   %g3, %g4, %g5			! %g5 = length of data

        subcc   %g4, %g2, %g0			! need to relocate data ?
        ble     init
        ld      [%g4], %g6
        subcc   %g6, 1, %g0
        be      init
mvdata:
        subcc   %g5, 8, %g5
        ldd     [%g2 + %g5], %g6
        bg      mvdata
#endif

/*
 * initialize target specific stuff. Only execute these
 * functions it they exist.
 */
init:
	sethi	%hi(SYM(hardware_init_hook)), %g1
        or      %g1,%lo(SYM(hardware_init_hook)),%g1
	cmp	%g0,%g1
	be	1f
	nop
	call	SYM(hardware_init_hook)
	nop

1:	
	sethi	%hi(SYM(software_init_hook)), %g1
        or      %g1,%lo(SYM(software_init_hook)),%g1
	cmp	%g0,%g1
	be	2f
	nop
	call	SYM(software_init_hook)
	nop
2:
	call SYM(main)
	nop

	/* call exit from the C library so atexit gets called, and the
	 * C++ destructors get run. This calls our exit routine below	 
	 * when it's done.
	 */
	call	SYM(exit)
	nop

/*
 * This should drop control back to the ROM monitor, if there is
 * one.
 */
	.globl	SYM(_exit)
SYM(_exit):
	call	0
	nop

/*
 * Trap handlers.
 */

	.align 8

SYM(win_ovf_trap):
	sethi %hi(SYM(win_ovf)), %l3
	jmpl %lo(SYM(win_ovf))+%l3, %g0
	mov %wim, %l0
	nop

SYM(win_unf_trap):
	sethi %hi(SYM(win_unf)), %l3
	jmpl %lo(SYM(win_unf))+%l3, %g0
	mov %wim, %l0
	nop
	
SYM(no_fpu_trap):			! Come here when no fpu exists.
	jmpl %l2, %g0			! This just skips the
        rett %l2+4			! offending instruction.

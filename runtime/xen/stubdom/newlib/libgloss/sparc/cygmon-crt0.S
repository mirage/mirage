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

#ifdef TARGET_CPU_SPARC64
#define STACK_BIAS 2047
#define SAVE_SIZE -128
#else
#define SAVE_SIZE -64
#endif
	
.data
        .align  8
SYM(environ):			! this is the first address in the data section
        .long   0

SYM(argc):
	.long	0

	.text
	.align 8

	.globl SYM(start)
	.globl start
SYM(start):
start:
	/* see if the stack is already setup. if not, then default
         *  to using the value of %sp as set by the ROM monitor
         */
	sethi	%hi(__stack), %g1
        or      %g1,%lo(__stack),%g1
        cmp     %g0,%g1
        be      1f
	nop
#ifdef STACK_BIAS
	sub	%g1, STACK_BIAS, %g1
#endif
	mov	%g1, %sp				! set the stack pointer
        mov     0, %fp
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
	set	SYM(__sigtramp), %o0
	call	SYM(__install_signal_handler)
	nop

	set	do_dtors,%o0
	call	SYM(atexit)
	nop

	call	do_ctors
	nop

	set	SYM(argc), %o0
	call	SYM(__getProgramArgs)
	nop

	mov	%o0, %o1
	set	SYM(argc), %o0
	ld	[%o0], %o0
	call SYM(main)
	nop

	/* call exit from the C library so atexit gets called, and the
	 * C++ destructors get run. This calls our exit routine below	 
	 * when it's done.
	 */
	call	SYM(exit)
	nop

do_ctors:
	save	%sp,SAVE_SIZE,%sp
	set	__CTOR_LIST__,%l0
our_entry:
	ld	[%l0],%l1
	add	%l0,4,%l0
	tst	%l1
1:
	beq	2f
	nop
	ld	[%l0],%l2
	add	%l0,4,%l0

	call	%l2
	nop
	deccc	%l1
	b	1b
	nop
2:
	ret
	restore

do_dtors:
	save	%sp,SAVE_SIZE,%sp
	set	__DTOR_LIST__,%l0
	b	our_entry
	nop

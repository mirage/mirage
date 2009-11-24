/*
 * This is based on the file srt0.s provided with the binary
 * distribution of the SPARC Instruction Simulator (SIS) found
 * at ftp://ftp.estec.esa.nl/pub/ws/wsd/erc32.
 */

#include "asm.h"

	.data
        .align  8
SYM(environ):
        .long   0

	.text

	.globl SYM(start)
SYM(start):
	sethi	%hi(__stack), %g1
        or      %g1,%lo(__stack),%g1
	mov	%g1, %sp		! set the stack pointer
        mov     %sp, %fp

        /* clear the bss */
        sethi %hi(__bss_start),%g2
        or    %g2,%lo(__bss_start),%g2	! start of bss
        sethi %hi(_end),%g3
        or    %g3,%lo(_end),%g3		! end of bss
        mov   %g0,%g1			! so std has two zeros
zerobss:
        std    %g0,[%g2]
        add    %g2,8,%g2
        cmp    %g2,%g3
        bleu,a zerobss
        nop

        /* move data segment to proper location */
 
#if 0
relocd:
        set (_endtext),%g2		! g2 = start of data in aout file
        set (_environ),%g4		! g4 = start of where data should go
        set (_edata),%g3		! g3 = end of where data should go
        subcc   %g3, %g4, %g5		! g5 = length of data

        subcc   %g4, %g2, %g0		! need to relocate data ?
        ble     initok
        ld      [%g4], %g6
        subcc   %g6, 1, %g0
        be      initok
mvdata:
        subcc   %g5, 8, %g5
        ldd     [%g2 + %g5], %g6
        bg      mvdata
        std     %g6, [%g4 + %g5]

initok:
#endif

	call	SYM(__fix_ctors)
	nop
        call    SYM(main)
        nop

	/* call exit from the C library so atexit gets called, and the
	 * C++ destructors get run. This calls our exit routine below	 * when it's done.
	 */
	call	SYM(exit)
	nop

	.globl	SYM(_exit)
SYM(_exit):
	set	0xdeadd00d, %o1		! Magic number for simulator.
        ta      0                       ! Halt if _main returns ...
        nop
 

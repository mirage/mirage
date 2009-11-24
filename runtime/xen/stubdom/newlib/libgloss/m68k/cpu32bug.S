/*
 * cpu32bug.S -- board support for the CPU32BUG monitor.
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
#include "cpu32bug.h"

	.title "cpu32bug.S for m68k-coff"

	.text
	.global SYM (_exit)
	.global SYM (outln)
	.global SYM (outbyte)
	.global SYM (putDebugChar)
	.global SYM (inbyte)
	.global SYM (getDebugChar)
	.global SYM (havebyte)

/*
 * _exit -- Exit from the application. Normally we cause a user trap
 *          to return to the ROM monitor for another run.
 */
	.text
	.align	2
SYM (_exit):
	link	fp, IMM(0)
        trap	IMM(15)
        .word	RETURN

/*
 * inbyte -- get a byte from the serial port
 *	d0 - contains the byte read in
 */
	.text
	.align	2
SYM (getDebugChar):		/* symbol name used by m68k-stub */
SYM (inbyte):
	link	fp, IMM(-8)
	trap 	IMM(15)
	.word	INCHR
	moveb 	sp@, d0
	extw	d0
	extl	d0
	unlk	fp
	rts

/*
 * outbyte -- sends a byte out the serial port
 *	d0 - contains the byte to be sent
 */
	.text
	.align	2
SYM (putDebugChar):		/* symbol name used by m68k-stub */
SYM (outbyte):
	link	fp, IMM(-4)
 	moveb	fp@(11), sp@
	trap 	IMM(15)
	.word	OUTCHR
	unlk	fp
	rts

/*
 * outln -- sends a string of bytes out the serial port with a CR/LF
 *	a0 - contains the address of the string's first byte
 *	a1 - contains the address of the string's last byte
 */
	.text
	.align	2
SYM (outln):
	link	fp, IMM(-8)
	moveml	a0/a1, sp@
	trap 	IMM(15)
	.word 	OUTLN
	unlk	fp
	rts

/*
 * outstr -- sends a string of bytes out the serial port without a CR/LF
 *	a0 - contains the address of the string's first byte
 *	a1 - contains the address of the string's last byte
 */
	.text
	.align	2
SYM (outstr):
	link	fp, IMM(-8)
	moveml	a0/a1, sp@
	trap 	IMM(15)
	.word 	OUTSTR
	unlk	fp
	rts

/*
 * havebyte -- checks to see if there is a byte in the serial port,
 *             returns 1 if there is a byte, 0 otherwise.
 */
	.text
	.align	2
SYM (havebyte):
	trap 	IMM(15)
	.word	INSTAT
	beqs	empty
	movel 	IMM(1), d0
	rts
empty:
	movel	IMM(0), d0
	rts

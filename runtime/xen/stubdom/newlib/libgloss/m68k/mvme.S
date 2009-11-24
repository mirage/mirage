/* mvme.S -- board support for m68k
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

	.title "mvme.S for m68k-coff"

	.align	2
	.text
	.global SYM (_exit)
	.global SYM (outln)
	.global SYM (outbyte)
	.global SYM (putDebugChar)
	.global SYM (inbyte)
	.global SYM (getDebugChar)
	.global SYM (havebyte)
	.global SYM (exceptionHandler)

	.set	vbr_size, 0x400
	.comm	SYM (vbr_table), vbr_size

/*
 * _exit -- Exit from the application. Normally we cause a user trap
 *          to return to the ROM monitor for another run.
 */
SYM (_exit):
        unlk    a6
        trap IMM(15)
        .word return

        .align  2

/*
 * inbyte -- get a byte from the serial port
 *	d0 - contains the byte read in
 */
	.align	2
SYM (getDebugChar):		/* symbol name used by m68k-stub */
SYM (inbyte):
	link	a6, IMM(-8)
	trap 	IMM(15)
	.word	inchr
	moveb 	sp@, d0
	extw	d0
	extl	d0
	unlk	a6
	rts

/*
 * outbyte -- sends a byte out the serial port
 *	d0 - contains the byte to be sent
 */
	.align	2
SYM (putDebugChar):		/* symbol name used by m68k-stub */
SYM (outbyte):
	link	fp, IMM(-4)
 	moveb	fp@(11), sp@
	trap 	IMM(15)
	.word	outchr
	unlk	fp
	rts

/*
 * outln -- sends a string of bytes out the serial port with a CR/LF
 *	a0 - contains the address of the string's first byte
 *	a1 - contains the address of the string's last byte
 */
	.align	2
SYM (outln):
	link	a6, IMM(-8)
	moveml	a0/a1, sp@
	trap 	IMM(15)
	.word 	outln
	unlk	a6
	rts

/*
 * outstr -- sends a string of bytes out the serial port without a CR/LF
 *	a0 - contains the address of the string's first byte
 *	a1 - contains the address of the string's last byte
 */
	.align	2
SYM (outstr):
	link	a6, IMM(-8)
	moveml	a0/a1, sp@
	trap 	IMM(15)
	.word 	outstr
	unlk	a6
	rts

/*
 * havebyte -- checks to see if there is a byte in the serial port,
 *             returns 1 if there is a byte, 0 otherwise.
 */
SYM (havebyte):
	trap 	IMM(15)
	.word	instat
	beqs	empty
	movel 	IMM(1), d0
	rts
empty:
	movel	IMM(0), d0
	rts

/*
 * These constants are for the MVME-135 board's boot monitor. They
 * are used with a TRAP 15 call to access the monitor's I/O routines.
 * they must be in the word following the trap call.
 */
	.set inchr, 0x0
	.set instat, 0x1
	.set inln, 0x2
	.set readstr, 0x3
	.set readln, 0x4
	.set chkbrk, 0x5

	.set outchr, 0x20
	.set outstr, 0x21
	.set outln, 0x22
	.set write, 0x23
	.set writeln, 0x24
	.set writdln, 0x25
	.set pcrlf, 0x26
	.set eraseln, 0x27
	.set writd, 0x28
	.set sndbrk, 0x29

	.set tm_ini, 0x40
	.set dt_ini, 0x42
	.set tm_disp, 0x43
	.set tm_rd, 0x44

	.set redir, 0x60
	.set redir_i, 0x61
	.set redir_o, 0x62
	.set return, 0x63
	.set bindec, 0x64

	.set changev, 0x67
	.set strcmp, 0x68
	.set mulu32, 0x69
	.set divu32, 0x6A
	.set chk_sum, 0x6B

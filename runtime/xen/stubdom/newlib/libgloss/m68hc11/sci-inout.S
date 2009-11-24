/* M68HC11/M68HC12 serial line operations
 * Copyright (C) 1999, 2001, 2003, 2004 Stephane Carrez (stcarrez@nerim.fr)
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

#ifdef __HAVE_SHORT_INT__
	.mode mshort
#else
	.mode mlong
#endif

#if defined(__USE_RTC__)
	.macro ret
#if defined(mc68hc12)
	rtc
#else
	jmp __return_32
#endif
	.endm
#else
	.macro ret
	rts
	.endm
#endif
#ifdef mc68hc12
	SC0CR1 = 0xC2
	SC0CR2 = 0xC3
	SC0SR1 = 0xC4
	SC0DRL = 0xC7
	SC0BD  = 0xC0

	.sect .data
	.globl _m68hc12_ports
_m68hc12_ports:	.word	0

	.sect .text
	.globl outbyte
;;;
;;; int outbyte(char c);
;;;
;;; B :	Character to send
;;; 
outbyte:
	bsr	_sci_init
L1:
	ldaa	SC0SR1,x
	bge	L1
	stab	SC0DRL,x
	ldab	SC0CR2,x
	orab	#0x8
	stab	SC0CR2,x
	ret

	.sect .text
	.globl inbyte
;;;
;;; char inbyte(void);
;;; 
inbyte:
	bsr	_sci_init
	ldaa	SC0SR1,x
	bita	#0x20
	beq	inbyte
	ldab	SC0CR2,x
	ret

	.globl _sci_init
	.sect .text
_sci_init:
	ldx	_m68hc12_ports
	beq	do_init
	dex
	rts
do_init:
	ldx	#0x1
	stx	_m68hc12_ports
	dex
	ldd	#26
	std	SC0BD,x
	ldaa	#0
	staa	SC0CR1,x
	ldaa	#0xC
	staa	SC0CR2,x
	rts
#else	
	BAUD = 0x2b
	SCCR1= 0x2c
	SCCR2= 0x2d
	SCSR = 0x2e
	SCDR = 0x2f

	.sect .data
	.globl _m68hc11_ports
_m68hc11_ports:	.word	0

	.sect .text
	.globl outbyte
;;;
;;; int outbyte(char c);
;;;
;;; B :	Character to send
;;; 
outbyte:
	bsr	_sci_init
L1:
	ldaa	SCSR,x
	bge	L1
	stab	SCDR,x
	ldab	SCCR2,x
	orab	#0x8
	stab	SCCR2,x
	ret

	.sect .text
	.globl inbyte
;;;
;;; char inbyte(void);
;;; 
inbyte:
	bsr	_sci_init
	ldaa	SCSR,x
	bita	#0x20
	beq	inbyte
	ldab	SCDR,x
	ret

	.globl _sci_init
	.sect .text
_sci_init:
	ldx	_m68hc11_ports
	beq	do_init
	rts
do_init:
	ldx	#0x1000
	stx	_m68hc11_ports
	ldaa	#0x30
	staa	BAUD,x
	clra
	staa	SCCR1,x
	ldaa	#0xC
	staa	SCCR2,x
	rts

#endif

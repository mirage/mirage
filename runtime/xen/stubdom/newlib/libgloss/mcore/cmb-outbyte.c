/* cmb-outbyte.c -- outbyte function for CMB1200 eval board.
 *
 * Copyright (c) 1999 Cygnus Support
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
#include <_ansi.h>

#define _TX  0x40
#define _SR  0x86

#define UART0_BASE 0x10009000
#define UART1_BASE 0x1000a000

#define UART_BASE UART0_BASE

#define TXREG ((volatile unsigned short *)(UART_BASE + _TX))
#define SRREG ((volatile unsigned short *)(UART_BASE + _SR))

#define TRDY  0x2000

#define GDB_QUOTE_CHAR 15  /* ^O */

/*
 * outbyte -- send a byte to the UART.
 */
void
_DEFUN (outbyte, (ch),
	char ch)
{
    while (!(*SRREG & TRDY))
	;
    *TXREG = GDB_QUOTE_CHAR;

    while (!(*SRREG & TRDY))
	;
    *TXREG = (unsigned short)ch;
}

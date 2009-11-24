/* idp-outbyte.c
 * Copyright (c) 1995 Cygnus Support
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
#include "mc68681reg.h"

/* 
 * The DUART is mapped into the IDP address space in an unusual 
 * manner.  The mc68681 is an 8 bit device located on the least
 * significant byte (byte0) of the data bus.  Bytes 3, 2, and 
 * one have nothing in them and writes to these locations are
 * not valid.
 */

#define DUART_ADDR	0x00B00000
#define READREG(x)	(*((volatile char *) DUART_ADDR + (x * 4) + 3))
#define WRITEREG(x, y)	(*((char *) DUART_ADDR + (x * 4) + 3) = y)

/*
 * raw_outbyte -- send a byte to the DUART buffer. This only sends
 *           to channel A.
 */
static void
_DEFUN (raw_outbyte, (byte),
	char byte)
{
  /* First, wait for the UART to finish clocking out the last
     character we sent, if any.  Then, give it the next character to
     work on.  By waiting first, then handing off a new character, we
     allow the UART to work while the processor (perhaps) does other
     things; if we waited after sending each character, there'd be no
     opportunity for parallelism.  */
  while ((READREG (DUART_SRA) & 0x04) == 0x00)
    ;

  WRITEREG (DUART_TBA, byte);		/* write the byte */
}


/*
 * outbyte -- send BYTE out the DUART's channel A, for display to
 *      the user.
 *
 *      Normally, this is identical to raw_outbyte, but if
 *      GDB_MONITOR_OUTPUT is #defined, we prefix each byte we send
 *      with a ^O character (ASCII 15).  This is a signal to GDB's
 *      `rom68k' target to pass the character directly on to the user;
 *      it allows programs to do console output under GDB.
 *
 *      We compile this file twice: once with GDB_MONITOR_OUTPUT
 *      #defined, and once without.  The former .o file we put in
 *      libidpgdb.a, which is included in the link by idpgdb.ld; the
 *      latter we put in libidp.a, which is selected by idp.ld.
 */
void
_DEFUN (outbyte, (byte),
        char byte)
{
#ifdef GDB_MONITOR_OUTPUT
  raw_outbyte (0x0f);
#endif
  raw_outbyte (byte);
}

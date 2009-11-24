/* Stand-alone library for M32R-EVA board.
 *
 * Copyright (c) 1996, 1998 Cygnus Support
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

/* #define REVC to enable handling of the original RevC board,
   which is no longer the default, nor is it supported.  */

#ifndef REVC

/* Serial I/O routines for MSA2000G01 board */
#define UART_INCHAR_ADDR	0xff004009
#define UART_OUTCHR_ADDR	0xff004007
#define UART_STATUS_ADDR	0xff004002

#else

/* Serial I/O routines for M32R-EVA board */
#define UART_INCHAR_ADDR	0xff102013
#define UART_OUTCHR_ADDR	0xff10200f
#define UART_STATUS_ADDR	0xff102006

#endif

#define UART_INPUT_EMPTY	0x4
#define UART_OUTPUT_EMPTY	0x1

static volatile char  *rx_port   = (unsigned char *)  UART_INCHAR_ADDR;
static volatile char  *tx_port   = (char *)  UART_OUTCHR_ADDR;
static volatile short *rx_status = (short *) UART_STATUS_ADDR;
static volatile short *tx_status = (short *) UART_STATUS_ADDR;

static int
rx_rdy()
{
#ifndef REVC
  return (*rx_status & UART_INPUT_EMPTY);
#else
  return !(*rx_status & UART_INPUT_EMPTY);
#endif
}

static int
tx_rdy()
{
  return (*tx_status & UART_OUTPUT_EMPTY);
}

static unsigned char
rx_uchar()
{
  return *rx_port;
}

void
tx_char(char c)
{
  *tx_port = c;
}

int
getDebugChar()
{
  while (!rx_rdy())
    ;
  return rx_uchar();
}

void
putDebugChar(int c)
{
  while (!tx_rdy())
    ;
  tx_char(c);
}

void mesg(char *p)
{
  while (*p)
    {
      if (*p == '\n')
	putDebugChar('\r');
      putDebugChar(*p++);
    }
}

void phex(long x)
{
  char buf[9];
  int i;

  buf[8] = '\0';
  for (i = 7; i >= 0; i--)
    {
      char c = x & 0x0f;
      buf[i] = c < 10 ? c + '0' : c - 10 + 'A';
      x >>= 4;
    }
  mesg(buf);
}

/*
 * These routines set and get exception handlers.  They look a little
 * funny because the M32R uses branch instructions in its exception
 * vectors, not just the addresses.  The instruction format used is
 * BRA pcdisp24.
 */

#define TRAP_VECTOR_BASE_ADDR   0x00000040

/* Setup trap TT to go to ROUTINE. */
void 
exceptionHandler (int tt, unsigned long routine)
{
#ifndef REVC
  unsigned long *tb = (unsigned long *) TRAP_VECTOR_BASE_ADDR;
  tb[tt] = (0xff000000 | ((routine - (unsigned long) (&tb[tt])) >> 2));
#else
  unsigned long *tb = 0;	/* Trap vector base address */

  tb[tt] = ((routine >> 2) | 0xff000000) - tt;
#endif
}

/* Return the address of trap TT handler */
unsigned long
getExceptionHandler (int tt)
{
#ifndef REVC
  unsigned long *tb = (unsigned long *) TRAP_VECTOR_BASE_ADDR;
  return ((tb[tt] & ~0xff000000) << 2) + (unsigned long) (&tb[tt]);
#else
  unsigned long *tb = 0;	/* Trap vector base address */

  return ((tb[tt] + tt) | 0xff000000) << 2;
#endif
}

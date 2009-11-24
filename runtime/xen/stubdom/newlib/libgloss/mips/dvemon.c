/* dve.c -- I/O code for the Densan DVE-R3900 board.
 *
 * Copyright (c) 1998, 1999 Cygnus Support
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

/* Flag indicating that we are being debugged by GDB.  If set,
   preceded each character output to the console with a ^O,
   so that GDB will print it instead of discarding it.  */

int output_debug = 1;

/* Monitor "ci" function (console input) */

typedef int (*cifunc)(int waitflag);
#ifdef __mips64
static cifunc ci = (cifunc) 0xffffffffbfc00010L;
#else
static cifunc ci = (cifunc) 0xbfc00010;
#endif

#define WAIT    1
#define NOWAIT  0 
#define NOCHAR  (-1)

/* Monitor "co" function (console output) */

typedef void (*cofunc)(int c);
#ifdef __mips64
static cofunc co = (cofunc) 0xffffffffbfc00018L;
#else
static cofunc co = (cofunc) 0xbfc00018;
#endif

/*  outbyte -- shove a byte out the serial port; used by write.c.  */

int
outbyte(byte)
     unsigned char byte;
{
  /* Output a ^O prefix so that GDB won't discard the output.  */
  if (output_debug)
    co (0x0f);

  co (byte);
  return byte;
}

/* inbyte -- get a byte from the serial port; used by read.c.  */

unsigned char
inbyte()
{
  return (unsigned char) ci (WAIT);
}


/* Structure filled in by get_mem_info.  Only the size field is
   actually used (by sbrk), so the others aren't even filled in.  */

struct s_mem
{
  unsigned int size;
  unsigned int icsize;
  unsigned int dcsize;
};


void
get_mem_info (mem)
     struct s_mem *mem;
{
  mem->size = 0x1000000;	/* DVE-R3900 board has 16 MB of RAM */
}

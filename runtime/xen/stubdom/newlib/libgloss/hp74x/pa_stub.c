/* -*-C-*-
*******************************************************************************
*
* File:         pa_stub.c
* RCS:          $Header: /cvs/src/src/libgloss/hp74x/pa_stub.c,v 1.1 2000/03/17 22:48:50 ranjith Exp $
* Description:  main routines for PA RISC monitor stub
* Author:       Robert Quist
* Created:      Mon Nov  1 10:00:36 1993
* Modified:     Fri Nov 12 15:14:23 1993 (Robert Quist) quist@hpfcrdq
* Language:     C
* Package:      N/A
* Status:       Experimental (Do Not Distribute)
*
*******************************************************************************
*/

/****************************************************************************

		THIS SOFTWARE IS NOT COPYRIGHTED

   HP offers the following for use in the public domain.  HP makes no
   warranty with regard to the software or it's performance and the
   user accepts the software "AS IS" with all faults.

   HP DISCLAIMS ANY WARRANTIES, EXPRESS OR IMPLIED, WITH REGARD
   TO THIS SOFTWARE INCLUDING BUT NOT LIMITED TO THE WARRANTIES
   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

****************************************************************************/

/****************************************************************************
 *
 *  Description:     low level support for gdb debugger. $
 *
 *  Considerations:  only works on target hardware $
 *
 *  NOTES:           See Below $
 *
 *    To enable debugger support, two things need to happen.
 *
 *  One, a call to set_debug_traps() is necessary in order to allow
 *  any breakpoints or error conditions to be properly intercepted and
 *  reported to gdb.  
 *
 *  Two, a breakpoint needs to be generated to begin communication.
 *  This is most easily accomplished by a call to breakpoint().
 *  breakpoint() simulates a breakpoint


 *************
 *
 *    The following gdb commands are supported:
 *
 * command          function                               Return value
 *
 *    g             return the value of the CPU registers  hex data or ENN
 *    G             set the value of the CPU registers     OK or ENN
 *
 *    mAA..AA,LLLL  Read LLLL bytes at address AA..AA      hex data or ENN
 *    MAA..AA,LLLL: Write LLLL bytes at address AA.AA      OK or ENN
 *
 *    c             Resume at current address              SNN   ( signal NN)
 *    cAA..AA       Continue at address AA..AA             SNN
 *
 *    s             Step one instruction                   SNN
 *    sAA..AA       Step one instruction from AA..AA       SNN
 *
 *    k             kill
 *
 *    ?             What was the last sigval ?             SNN   (signal NN)
 *
 *    bBB..BB	    Set baud rate to BB..BB		   OK or BNN, then sets
 *							   baud rate
 *

 ************
 * All commands and responses are sent with a packet which includes a
 * checksum.  A packet consists of :
 *
 * $<packet info>#<checksum>.
 *
 * where
 * <packet info> :: <characters representing the command or response>
 * <checksum>    :: < two hex digits computed as modulo 256 sum of <packetinfo>>
 *
 * When a packet is received, it is first acknowledged with either '+' or '-'.
 * '+' indicates a successful transfer.  '-' indicates a failed transfer.
 *
 * Example:
 *
 * Host:                  Reply:
 * $m0,10#2a               +$00010203040506070809101112131415#42
 *
 ****************************************************************************/
#include <signal.h>
#include "hppa-defs.h"

/************************************************************************
 *
 * external low-level support
 */
#define	OPT_PDC_CACHE	     5
#define	OPT_PDC_ADD_VALID   12
#define PGZ_MEM_PDC	0x0388	/* location of PDC_ENTRY in memory    */
#define CALL_PDC	(*(int (*)())((int *)(*((int *)PGZ_MEM_PDC))))

extern putDebugChar();   /* write a single character      */
extern getDebugChar();   /* read and return a single char */
extern FICE();           /* flush i cache entry */
extern INLINE_BREAK();   /* break for user call */

#define RADDR_ALIGN(s,r) (s = ((unsigned int *) ((((int) r ) + 7 ) & 0xFFFFFFF8)))

/************************************************************************/
/* BUFMAX defines the maximum number of characters in inbound/outbound buffers*/
/* at least NUMREGBYTES*2 are needed for register packets */

#define BUFMAX 2048

#define NUMGPRS	  32
#define NUMSRS	   8
#define	NUMCRS	  32
#define	NUMSPCLS   3
#define	NUMFPRS	  32

#define NUMGPRBYTES	4
#define NUMSRBYTES	4
#define	NUMCRBYTES	4
#define	NUMSPCLBYTES	4
#define NUMFPRBYTES	8

/* Number of bytes of registers.  */
#define	NUMREGBYTES \
	(  (NUMGPRS * NUMGPRBYTES) \
         + (NUMSRS * NUMSRBYTES)   \
         + (NUMCRS * NUMCRBYTES)   \
	 + (NUMSPCLS * NUMSPCLBYTES) \
	 + (NUMFPRS * NUMFPRBYTES) \
        )
         

enum regnames   {GR0,  GR1,  GR2,  GR3,  GR4,  GR5,  GR6,  GR7,
		 GR8,  GR9,  GR10, GR11, GR12, GR13, GR14, GR15,
		 GR16, GR17, GR18, GR19, GR20, GR21, GR22, GR23,
		 GR24, GR25, GR26, GR27, GR28, GR29, GR30, GR31,
                 
                 SR0,  SR1,  SR2,  SR3,  SR4,  SR5,  SR6,  SR7,

                 CR0,  CR1,  CR2,  CR3,  CR4,  CR5,  CR6,  CR7,
		 CR8,  CR9,  CR10, CR11, CR12, CR13, CR14, CR15,
		 CR16, CR17H,CR18H,CR19, CR20, CR21, CR22, CR23,
		 CR24, CR25, CR26, CR27, CR28, CR29, CR30, CR31,
                 
                 CR17T,CR18T,CPUD0 };

enum fregnames  {FPR0,  FPR1,  FPR2,  FPR3,  FPR4,  FPR5,  FPR6,  FPR7,
		 FPR8,  FPR9,  FPR10, FPR11, FPR12, FPR13, FPR14, FPR15,
		 FPR16, FPR17, FPR18, FPR19, FPR20, FPR21, FPR22, FPR23,
		 FPR24, FPR25, FPR26, FPR27, FPR28, FPR29, FPR30, FPR31 };

#define PC  CR18H
#define NPC CR18T
#define SP  GR30
                
struct registers {
       int intregs[NUMGPRS + NUMSRS + NUMCRS + NUMSPCLS];
       int fpregs [NUMFPRS * 2];
                 };    
/* Global Variables */

static int initialized = 0;	/* !0 means we've been initialized */
static unsigned char hexchars[]="0123456789abcdef";
static unsigned char remcomInBuffer[BUFMAX];
static unsigned char remcomOutBuffer[BUFMAX];
static unsigned int  i_cache_params[6];

/* This table contains the mapping between PA hardware exception
   types, and signals, which are primarily what GDB understands.  It also
   indicates which hardware traps we need to commandeer when initializing
   the stub.

   The only two currently used are Recovery counter (single stepping)
   and Break trap ( break points ).
*/

static struct hard_trap_info
{
  unsigned char tt;		/* Trap number for PA-RISC */
  unsigned char signo;		/* Signal that we map this trap into */
} hard_trap_info[] = {
/* 1  High priority machine check */
/* 2  Power failure interrupt*/
/* 3  Recovery counter -- init */
/* 4  External interrupt */
/* 5  Low priority machine check */
  {6, SIGSEGV},			/* Instruction TLB miss/page fault */
  {7, SIGSEGV},			/* Memory protection */
  {8, SIGILL},			/* Illegal instruction */
  {9, SIGTRAP},			/* Break instruction -- init */
  {10,SIGILL},			/* Privileged instruction */
  {11,SIGILL},			/* Privileged register */
  {12,SIGUSR1},			/* Overflow */
  {13,SIGUSR2},			/* Conditional */
  {14,SIGEMT},			/* Assist Exception */
  {15,SIGSEGV},			/* Data TLB miss/page fault */
  {16,SIGSEGV},			/* Non-access Instruction TLB miss */
  {17,SIGSEGV},			/* Non-access Data TLB miss/page fault */
  {18,SIGSEGV},			/* Data memory protection/ unaligned data reference */
  {19,SIGTRAP},			/* Data memory break */
  {20,SIGSEGV},			/* TLB dirty bit */
  {21,SIGSEGV},			/* Page reference */
  {22,SIGEMT},			/* Assist emulation */
  {23,SIGILL},			/* Higher-privilege */
  {24,SIGILL},			/* Lower-privilege */
  {25,SIGTRAP},			/* Taken branch */
  {0, 0}			/* Must be last */
};

/* Functions */
/*========================================================================== */

/* Convert ch from a hex digit to an int */

static int
hex(ch)
     unsigned char ch;
{
  if (ch >= 'a' && ch <= 'f')
    return ch-'a'+10;
  if (ch >= '0' && ch <= '9')
    return ch-'0';
  if (ch >= 'A' && ch <= 'F')
    return ch-'A'+10;
  return -1;
}

/* scan for the sequence $<data>#<checksum>     */

static void
getpacket(buffer)
     char *buffer;
{
  unsigned char checksum;
  unsigned char xmitcsum;
  int i;
  int count;
  unsigned char ch;

  do
    {
      /* wait around for the start character, ignore all other characters */
      strobe();
      while ((ch = getDebugChar()) != '$') ;

      checksum = 0;
      xmitcsum = -1;

      count = 0;

      /* now, read until a # or end of buffer is found */
      while (count < BUFMAX)
	{
	  ch = getDebugChar();
	  if (ch == '#')
	    break;
	  checksum = checksum + ch;
	  buffer[count] = ch;
	  count = count + 1;
	}

      if (count >= BUFMAX)
	continue;

      buffer[count] = 0;

      if (ch == '#')
	{
	  xmitcsum = hex(getDebugChar()) << 4;
	  xmitcsum |= hex(getDebugChar());

#if TESTING
	  /* Humans shouldn't have to figure out checksums to type to it. */
	  putDebugChar ('+');
	  return;
#endif
	  if (checksum != xmitcsum)
	    putDebugChar('-');	/* failed checksum */
	  else
	    {
	      putDebugChar('+'); /* successful transfer */
	      /* if a sequence char is present, reply the sequence ID */
	      if (buffer[2] == ':')
		{
		  putDebugChar(buffer[0]);
		  putDebugChar(buffer[1]);
		  /* remove sequence chars from buffer */
		  count = strlen(buffer);
		  for (i=3; i <= count; i++)
		    buffer[i-3] = buffer[i];
		}
	    }
	}
    }
  while (checksum != xmitcsum);
}

/* send the packet in buffer.  */

static void
putpacket(buffer)
     unsigned char *buffer;
{
  unsigned char checksum;
  int count;
  unsigned char ch;

  /*  $<packet info>#<checksum>. */

  do
    {
      putDebugChar('$');
      checksum = 0;
      count = 0;

      while (ch = buffer[count])
	{
	  if (! putDebugChar(ch))
	    return;
	  checksum += ch;
	  count += 1;
	}

      putDebugChar('#');
      putDebugChar(hexchars[checksum >> 4]);
      putDebugChar(hexchars[checksum & 0xf]);
      } while (getDebugChar() != '+');
}

/* Convert the memory pointed to by mem into hex, placing result in buf.
 * Return a pointer to the last char put in buf (null), in case of mem fault,
 * return 0.
 * If MAY_FAULT is non-zero, then we will handle memory faults by returning
 * a 0, else treat a fault like any other fault in the stub.
 */

static unsigned char *
mem2hex(mem, buf, count, may_fault)
     unsigned char *mem;
     unsigned char *buf;
     int count;
     int may_fault;
{
  unsigned char ch;
  int           check_addr,
                new_addr;

  check_addr = 0;

  while (count-- > 0)
    {
      if (may_fault)
      { new_addr = ((int) (mem+3)) & 0xFFFFFFF8;
        if (new_addr != check_addr)
        { check_addr = new_addr;
          if (pdc_call(OPT_PDC_ADD_VALID,0,check_addr)) return 0;
        }
      }
      ch = *mem++;
      *buf++ = hexchars[ch >> 4];
      *buf++ = hexchars[ch & 0xf];
    }

  *buf = 0;

  return buf;
}

/* convert the hex array pointed to by buf into binary to be placed in mem
 * return a pointer to the character AFTER the last byte written */

static unsigned char *
hex2mem(buf, mem, count, may_fault)
     unsigned char *buf;
     unsigned char *mem;
     int count;
     int may_fault;
{
  int          i;
  unsigned int ch;
  int          check_addr,
               new_addr;

  check_addr = 0;

  for (i=0; i<count; i++)
    {
      ch = hex(*buf++) << 4;
      ch |= hex(*buf++);
      if (may_fault)
      { new_addr = ((int)(mem+3)) & 0xFFFFFFF8;
        if (new_addr != check_addr)
        { check_addr = new_addr;
          if (pdc_call(OPT_PDC_ADD_VALID,0,check_addr)) return 0;
        }
      }
      *mem++ = ch;
    }

  return mem;
}

/* Set up exception handlers for traceing and breakpoints */

void
set_debug_traps()
{ 
  unsigned int	R_addr[33];
  unsigned int	*Raddr_ptr;
  
  setup_vectors();
 
  /* get cache params for use by flush_i_cache */
  RADDR_ALIGN(Raddr_ptr,R_addr);

  if (pdc_call(OPT_PDC_CACHE,0,Raddr_ptr,0))
    i_cache_params[0] = -1;
  else
    i_cache_params[0] = R_addr[0];

  i_cache_params[1] = Raddr_ptr[1];
  i_cache_params[2] = Raddr_ptr[2];
  i_cache_params[3] = Raddr_ptr[3];
  i_cache_params[4] = Raddr_ptr[4];
  i_cache_params[5] = Raddr_ptr[5];

  /* In case GDB is started before us, ack any packets (presumably
     "$?#xx") sitting there.  */

  putDebugChar ('+');

  initialized = 1;
}


/* Convert the PA-RISC hardware trap number to a unix signal number. */

static int
computeSignal(tt)
     int tt;
{
  struct hard_trap_info *ht;

  for (ht = hard_trap_info; ht->tt && ht->signo; ht++)
    if (ht->tt == tt)
      return ht->signo;

  return SIGHUP;		/* default for things we don't know about */
}

/*
 * While we find nice hex chars, build an int.
 * Return number of chars processed.
 */

static int
hexToInt(ptr, intValue)
     unsigned char **ptr;
     int *intValue;
{
  int numChars = 0;
  int hexValue;

  *intValue = 0;

  while (**ptr)
    {
      hexValue = hex(**ptr);
      if (hexValue < 0)
	break;

      *intValue = (*intValue << 4) | hexValue;
      numChars ++;

      (*ptr)++;
    }

  return (numChars);
}

void
flush_i_cache()

{
  unsigned int addr,count,loop;

  if (i_cache_params[0] <= 0) return;

  addr = i_cache_params[2];
  for (count = 0; count < i_cache_params[4]; count++)
    { for ( loop = 0; loop < i_cache_params[5]; loop++) FICE(addr);
      addr = addr + i_cache_params[3];
    }
}

/*
 * This function does all command procesing for interfacing to gdb.
   return of 0 will execute DEBUG_GO (continue)
   return of 1 will execute DEBUG_SS (single step)
 */

int
handle_exception (registers,tt)
  unsigned long *registers;
  int  tt;			/* Trap type */
{
  int sigval;
  int addr;
  int length;
  unsigned char *ptr;

  /* reply to host that an exception has occurred */
  sigval = computeSignal(tt);
  ptr = remcomOutBuffer;

  *ptr++ = 'T';
  *ptr++ = hexchars[sigval >> 4];
  *ptr++ = hexchars[sigval & 0xf];

/* could be lots of stuff here like PC and SP registers */

  *ptr++ = 0;

  putpacket(remcomOutBuffer);

  while (1)
    {
      remcomOutBuffer[0] = 0;

      getpacket(remcomInBuffer);
      switch (remcomInBuffer[0])
	{
	case '?':
	  remcomOutBuffer[0] = 'S';
	  remcomOutBuffer[1] = hexchars[sigval >> 4];
	  remcomOutBuffer[2] = hexchars[sigval & 0xf];
	  remcomOutBuffer[3] = 0;
	  break;

	case 'd':
	  /* toggle debug flag */
	  led_putnum (16);
	  break;

	case 'g':		/* return the value of the CPU registers */
	  {
	    ptr = remcomOutBuffer;
            /* GR0..GR31 SR0..SR7 CR0..CR31 specials */
	    ptr = mem2hex((char *)registers, ptr, NUMREGBYTES, 0);
            /* need to add floating point registers */
	  }
	  break;

	case 'G':	   /* set the value of the CPU registers - return OK */
	  {
	    ptr = &remcomInBuffer[1];
            /* GR0..GR31 SR0..SR7 CR0..CR31 specials */
	    hex2mem(ptr, (char *)registers, NUMREGBYTES, 0);
	    strcpy(remcomOutBuffer,"OK 1");
	  }
	  break;

	case 'm':	  /* mAA..AA,LLLL  Read LLLL bytes at address AA..AA */
	  /* Try to read %x,%x.  */

	  ptr = &remcomInBuffer[1];

	  if (hexToInt(&ptr, &addr)
	      && *ptr++ == ','
	      && hexToInt(&ptr, &length))
	    {
	      if (mem2hex((char *)addr, remcomOutBuffer, length, 1))
		break;

	      strcpy (remcomOutBuffer, "E03");
	    }
	  else
	    strcpy(remcomOutBuffer,"E01");
	  break;

	case 'M': /* MAA..AA,LLLL: Write LLLL bytes at address AA.AA return OK */
	  /* Try to read '%x,%x:'.  */

	  ptr = &remcomInBuffer[1];

	  if (hexToInt(&ptr, &addr)
	      && *ptr++ == ','
	      && hexToInt(&ptr, &length)
	      && *ptr++ == ':')
	    {
	      if (hex2mem(ptr, (char *)addr, length, 1))
		strcpy(remcomOutBuffer, "OK");
	      else
		strcpy(remcomOutBuffer, "E03");
	    }
	  else
	    strcpy(remcomOutBuffer, "E02");
	  break;

	case 'c':    /* cAA..AA    Continue at address AA..AA(optional) */
	  /* try to read optional parameter, pc unchanged if no parm */

	  ptr = &remcomInBuffer[1];
	  if (hexToInt(&ptr, &addr))
	    {
	      registers[PC] = addr;
	      registers[NPC] = addr + 4;
	    }

/* Need to flush the instruction cache here, as we may have deposited a
   breakpoint, and the icache probably has no way of knowing that a data ref to
   some location may have changed something that is in the instruction cache.
 */

	  flush_i_cache();
	  return 0;		/* execute GO */

	  /* kill the program */
	case 'k' :		/* do nothing */
	  break;

        case 's' :              /* single step */
	  /* try to read optional parameter, pc unchanged if no parm */

	  ptr = &remcomInBuffer[1];
	  if (hexToInt(&ptr, &addr))
	    {
	      registers[PC] = addr;
	      registers[NPC] = addr + 4;
	    }
/* Need to flush the instruction cache here, as we may have deposited a
   breakpoint, and the icache probably has no way of knowing that a data ref to
   some location may have changed something that is in the instruction cache.
 */
	  flush_i_cache();
	  return 1;		/* execute Single Step */
          break;

#if TESTING1
	case 't':		/* Test feature */
	  break;
#endif
	case 'r':		/* Reset */
	  break;

#if TESTING2
Disabled until we can unscrew this properly

	case 'b':	  /* bBB...  Set baud rate to BB... */
	  {
	    int baudrate;
	    extern void set_timer_3();

	    ptr = &remcomInBuffer[1];
	    if (!hexToInt(&ptr, &baudrate))
	      {
		strcpy(remcomOutBuffer,"B01");
		break;
	      }

	    /* Convert baud rate to uart clock divider */
	    switch (baudrate)
	      {
	      case 38400:
		baudrate = 16;
		break;
	      case 19200:
		baudrate = 33;
		break;
	      case 9600:
		baudrate = 65;
		break;
	      default:
		strcpy(remcomOutBuffer,"B02");
		goto x1;
	      }

	    putpacket("OK 2");	/* Ack before changing speed */
	    set_timer_3(baudrate); /* Set it */
	  }
x1:	  break;
#endif
	}			/* switch */

      /* reply to the request */
      putpacket(remcomOutBuffer);
    }
  print ("\r\nEscaped handle_exception\r\n");
}

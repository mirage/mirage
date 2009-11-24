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
 *  Header: remcom.c,v 1.34 91/03/09 12:29:49 glenne Exp $
 *
 *  Module name: remcom.c $
 *  Revision: 1.34 $
 *  Date: 91/03/09 12:29:49 $
 *  Contributor:     Lake Stevens Instrument Division$
 *
 *  Description:     low level support for gdb debugger. $
 *
 *  Considerations:  only works on target hardware $
 *
 *  Written by:      Glenn Engel $
 *  ModuleState:     Experimental $
 *
 *  NOTES:           See Below $
 *
 *  Heavily modified for XStormy16 by Mark Salter, Red Hat.
 *  Optimisations and 'X' support by Geoff Keating, Red Hat.
 *
 *  To enable debugger support, two things need to happen.  One, a
 *  call to set_debug_traps() is necessary in order to allow any breakpoints
 *  or error conditions to be properly intercepted and reported to gdb.
 *  Two, a breakpoint needs to be generated to begin communication.  This
 *  is most easily accomplished by a call to breakpoint().  Breakpoint()
 *  simulates a breakpoint by executing a trap #1.
 *
 *  Because gdb will sometimes write to the stack area to execute function
 *  calls, this program cannot rely on using the inferior stack so it uses
 *  it's own stack area.
 *
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
 *    XAA..AA,LLLL: Write LLLL binary bytes at address     OK or ENN
 *                  AA..AA
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
 * All commands and responses are sent with a packet which includes a
 * checksum.  A packet consists of
 *
 * $<packet info>#<checksum>.
 *
 * where
 * <packet info> :: <characters representing the command or response>
 * <checksum>    :: <two hex digits computed as modulo 256 sum of <packetinfo>>
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

/* Local functions:
 */
static void putDebugChar(unsigned ch);
static unsigned char getDebugChar(void);
static void putPacket(unsigned char *);
static void putHex (char c, unsigned long mem_arg, int count);
static unsigned char *getpacket(void);
static void hex2mem(unsigned char *, unsigned long, int);
static int valid_addr_range (unsigned long mem, int count);
static int  hexToInt(unsigned char **, long *);
static void prepare_to_step(void);
static void finish_from_step(void);

/* breakpoint opcode */
#define BREAKPOINT_OPCODE 0x0006

/* Error Detection Register */
#define ERR_DETECT_REG  (*(volatile unsigned *)0x7f08)
#define UNDEF_INSN_ENA   0x01
#define UNDEF_INSN_FLAG  0x02
#define ODD_ADDR_ENA     0x04
#define ODD_ADDR_FLAG    0x08
#define BAD_ADDR_ENA     0x10
#define BAD_ADDR_FLAG    0x20
#define SER0_IRQ_ENA     0x1000
#define SER0_IRQ_FLAG    0x2000

/*****************************************************************************
 * BUFMAX defines the maximum number of characters in inbound/outbound buffers
 * at least NUMREGBYTES*2 are needed for register packets 
 */
#define BUFMAX 80

static const unsigned char hexchars[]="0123456789abcdef";

#define NUMREGS 17

/* Number of bytes of registers (extra 2 bytes is for 4 byte PC).  */
#define NUMREGBYTES ((NUMREGS * 2) + 2)
enum regnames { R0,  R1,  R2,  R3,  R4,  R5,  R6,   R7,
		R8,  R9,  R10, R11, R12, R13, R14,  R15,
		PC };

#define FP  R13
#define PSW R14
#define SP  R15

struct regs {
    int  r[16];
    long pc;
} registers;

static struct regs orig_registers;

static unsigned char remcomBuffer[BUFMAX];

/* Indicate whether inferior is running. Used to decide whether or not to
   send T packet when stub is entered. */
static char is_running;

static inline unsigned char
get_char(unsigned long addr)
{
  unsigned int msw, lsw;
  unsigned char ret;

  msw = addr >> 16;
  lsw = addr & 0xffff;

  asm("movf.b %0,(%2)\n" 
      : "=e"(ret) : "d"(msw), "r"(lsw) : "memory");

  return ret;
}

static inline void
set_char(unsigned long addr, unsigned int val)
{
  unsigned int msw, lsw;

  msw = addr >> 16;
  lsw = addr & 0xffff;

  asm("movf.b (%1),%2\n" 
      : /* none */ : "d"(msw), "r"(lsw), "e"(val) : "memory" );
}

static inline unsigned int
get_word(unsigned long addr)
{
  unsigned int ret, msw, lsw;

  msw = addr >> 16;
  lsw = addr & 0xffff;

  asm("movf.w %0,(%2)\n" 
      : "=e"(ret) : "d"(msw), "r"(lsw) : "memory" );

  return ret;
}

static inline void
set_word(unsigned long addr, unsigned int val)
{
  unsigned int msw, lsw;

  msw = addr >> 16;
  lsw = addr & 0xffff;

  asm("movf.w (%1),%2\n" 
      : /* none */ : "d"(msw), "r"(lsw), "e"(val) : "memory" );
}

static void
assign_regs (struct regs *dest, const struct regs *src)
{
  int i;
  char *d = (char *)dest, *s = (char *)src;
  for (i = 0; i < sizeof (struct regs); i++)
    *d++ = *s++;
}

/* Write out a register for a 'T' packet.  */

static unsigned char *
putreg (unsigned char *buf, int regnum, void *mem_p, int count)
{
  int i;
  unsigned char ch;
  char *mem = (char *)mem_p;

  *buf++ = hexchars[regnum >> 4];
  *buf++ = hexchars[regnum % 16];
  *buf++ = ':';

  for (i=0;i<count;i++)
    {
      ch = *mem++;
      *buf++ = hexchars[ch >> 4];
      *buf++ = hexchars[ch % 16];
    }
  *buf++ = ';';
  return(buf);
}

/*
 * This function does all command procesing for interfacing to gdb.
 */
void 
handle_exception(void)
{
  char sigval;
  unsigned char *ptr;
  long addr, length;

  /* reply to host that an exception has occurred */
  sigval = 5; /* SIGTRAP is default */
  if (ERR_DETECT_REG & UNDEF_INSN_FLAG)
    {
      ERR_DETECT_REG &= ~UNDEF_INSN_FLAG;
      registers.pc -= 2;
      if (get_word(registers.pc) != BREAKPOINT_OPCODE)
	sigval = 4; /* SIGILL */
    }
  if (ERR_DETECT_REG & BAD_ADDR_FLAG)
    {
      ERR_DETECT_REG &= ~BAD_ADDR_FLAG;
      sigval = 11; /* SIGSEGV */
    }
  if (ERR_DETECT_REG & SER0_IRQ_FLAG)
    {
      unsigned char ch;
      
      ch = getDebugChar();
      ERR_DETECT_REG &= ~SER0_IRQ_FLAG;
      if (ch != 0x03)
	return;
      sigval = 2; /* SIGINT */
    }

  finish_from_step();

  /* save original context so it can be restored as a result of
     a kill packet. */
  if (orig_registers.pc == 0L)
    assign_regs (&orig_registers, &registers);

  if (is_running)
    {
      ptr = remcomBuffer;
 
      *ptr++ = 'T';         /* notify gdb with signo, PC, FP and SP */
      *ptr++ = hexchars[sigval >> 4];
      *ptr++ = hexchars[sigval & 0xf];
 
      ptr = putreg (ptr, PC, &registers.pc, 4);
      ptr = putreg (ptr, FP, &registers.r[FP], 2);
      ptr = putreg (ptr, SP, &registers.r[SP], 2);

      *ptr++ = 0;
 
      putPacket(remcomBuffer);
    }

  while (1) {
    char kind;
    
    ptr = getpacket();
    kind = *ptr++;
    if (kind == 'M' || kind == 'X')
      {
	/* MAA..AA,LLLL: Write LLLL bytes at address AA.AA return OK */
        /* TRY TO READ '%x,%x:'.  IF SUCCEED, SET PTR = 0 */
	if (hexToInt(&ptr,&addr)
	    && *(ptr++) == ','
	    && hexToInt(&ptr,&length)
	    && *(ptr++) == ':')
	  {
	    if (valid_addr_range (addr, length))
	      {
		if (kind == 'M')
		  hex2mem(ptr, addr, length);
		else
		  {
		    int i;
		    for (i = 0; i < length; i++)
		      if (*ptr++ == 0x7d)
			set_char (addr++, *ptr++ ^ 0x20);
		      else
			set_char (addr++, ptr[-1]);
		    
		  }
		putPacket ("OK");
	      }
	    else
	      putPacket ("E03");
	  }
	else
	  putPacket ("E02");
      }
    else if (kind == 'm')
      {
	/* mAA..AA,LLLL  Read LLLL bytes at address AA..AA */
	/* TRY TO READ %x,%x.  IF SUCCEED, SET PTR = 0 */
        if (hexToInt(&ptr,&addr)
	    && *(ptr++) == ','
	    && hexToInt (&ptr,&length))
	  {
	    if (valid_addr_range (addr, length))
	      putHex (0, addr, length);
	    else
	      putPacket ("E03");
	  }
	else
	  putPacket ("E02");
      }
    else if (kind == 'R')
      {
	if (hexToInt (&ptr, &addr))
	  registers.pc = addr;
	putPacket ("OK");
      }
    else if (kind == '!')
      putPacket ("OK");
    else if (kind == '?')
      putHex ('S', (unsigned long)(unsigned int)&sigval, 1);
    else if (kind == 'g')
      putHex (0, (unsigned long)(unsigned int)&registers, NUMREGBYTES);
    else if (kind == 'P')
      {
	/* set the value of a single CPU register - return OK */
	unsigned long regno;
	
	if (hexToInt (&ptr, &regno) 
	    && *ptr++ == '='
	    && regno < NUMREGS)
	  {
	    hex2mem (ptr, (unsigned long)(unsigned int)(registers.r + regno),
		     regno == PC ? 4 : 2);
	    putPacket ("OK");
	  }
	else
	  putPacket ("E01");
      }
    else if (kind == 'G')
      {
	/* set the value of the CPU registers - return OK */
	hex2mem(ptr, (unsigned long)(unsigned int)&registers, NUMREGBYTES);
	putPacket ("OK");
      }
    else if (kind == 's' || kind == 'c')
      {
	/* sAA..AA	Step one instruction from AA..AA(optional) */
	/* cAA..AA	Continue from address AA..AA(optional) */
	/* try to read optional parameter, pc unchanged if no parm */

	is_running = 1;
	
	if (hexToInt(&ptr,&addr))
	  registers.pc = addr;
	
	if (kind == 's')	/* single-stepping */
	  prepare_to_step();
	return;
      }
    else if (kind == 'k')
      {
	/* kill the program */
	assign_regs (&registers, &orig_registers);
	is_running = 0;
	putPacket ("");
      }
    else
      /* Unknown code.  Return an empty reply message. */
      putPacket ("");
  }
}

static int 
hex (int ch)
{
  if ((ch >= '0') && (ch <= '9')) return (ch-'0');
  if ((ch >= 'a') && (ch <= 'f')) return (ch-'a'+10);
  if ((ch >= 'A') && (ch <= 'F')) return (ch-'A'+10);
  return (-1);
}

/* scan for the sequence $<data>#<checksum>     */

static unsigned char *
getpacket (void)
{
  unsigned char *buffer = &remcomBuffer[0];
  unsigned checksum;
  int count;
  char ch;

  while (1)
    {
      /* wait around for the start character, ignore all other characters */
      while (getDebugChar () != '$')
	;

      checksum = 0;
      count = 0;
      while ((ch = getDebugChar ()) == '$')
	;

      /* now, read until a # or end of buffer is found */
      while (ch != '#' && count < BUFMAX - 1)
	{
	  checksum = checksum + ch;
	  buffer[count] = ch;
	  count = count + 1;
	  ch = getDebugChar ();
	}
      buffer[count] = 0;

      if (ch == '#')
	{
	  unsigned xmitcsum;
	  ch = getDebugChar ();
	  xmitcsum = hex (ch) << 4;
	  ch = getDebugChar ();
	  xmitcsum += hex (ch);

	  /* If one of the above 'hex' calls returns -1, xmitcsum will
	     have high bits set, and so the test below will fail.  */

	  if ((checksum & 0xFF) != xmitcsum)
	    putDebugChar ('-');	/* failed checksum */
	  else
	    {
	      putDebugChar ('+');	/* successful transfer */
	      return &buffer[0];
	    }
	}
    }
}

/* send the packet in buffer.  */

static void 
putPacket (unsigned char *buffer_p)
{
  /*  $<packet info>#<checksum>. */
  do {
    unsigned checksum;
    unsigned char *buffer = buffer_p;

    putDebugChar('$');
    checksum = 0;

    while (*buffer) {
      putDebugChar(*buffer);
      checksum += *buffer;
      buffer++;
    }
    putDebugChar('#');
    putDebugChar(hexchars[(checksum >> 4) % 16]);
    putDebugChar(hexchars[checksum % 16]);
  } while (getDebugChar() != '+');
}

/* Convert the memory pointed to by mem into hex, and return it as a packet. */

static void
putHex (char c, unsigned long mem_arg, int count)
{
  do {
    unsigned long mem = mem_arg;
    int i;
    unsigned checksum;

    putDebugChar('$');
    checksum = 0;

    if (c)
      {
	checksum = c;
	putDebugChar(c);
      }

    for (i = 0; i < count; i++)
      {
	unsigned char c = get_char (mem);
	char ch = hexchars[c >> 4];
	putDebugChar(ch);
	checksum += ch;
	ch = hexchars[c % 16];
	putDebugChar(ch);
	checksum += ch;
	mem++;
      }
    putDebugChar('#');
    putDebugChar(hexchars[(checksum >> 4) % 16]);
    putDebugChar(hexchars[checksum % 16]);
  } while (getDebugChar() != '+');
}

/* Function: gdb_write(char *, int)
   Make gdb write n bytes to stdout (not assumed to be null-terminated). */
 
void
gdb_write (char *data, int len)
{
  ERR_DETECT_REG &= ~SER0_IRQ_ENA;
  putHex ('O', (unsigned long)(unsigned int)data, len);
  ERR_DETECT_REG |= SER0_IRQ_ENA;
}

int
gdb_read (char *buf, int nbytes)
{
  int i = 0;

  ERR_DETECT_REG &= ~SER0_IRQ_ENA;
  for (i = 0; i < nbytes; i++)
    {
      *(buf + i) = getDebugChar();
      if ((*(buf + i) == '\n') || (*(buf + i) == '\r'))
        {
          (*(buf + i + 1)) = 0;
          break;
        }
    }
  ERR_DETECT_REG |= SER0_IRQ_ENA;
  return (i);
}

static int
valid_addr_range (unsigned long mem, int count)
{
  unsigned long last = mem + count - 1;

  if (last < 0x800L)
    return 1;

  if (mem < 0x7f00L)
    return 0;

  if (last > 0x7ffffL)
    return 0;

  return 1;
}

/* Convert the hex array pointed to by buf into binary to be placed in mem.
   Return a pointer to the character AFTER the last byte written. */

static void
hex2mem (unsigned char *buf, unsigned long mem, int count)
{
  int i;
  unsigned char ch;

  for (i=0;i<count;i++)
    {
      ch = hex(*buf++) << 4;
      ch = ch + hex(*buf++);
      set_char (mem++, ch);
    }
}

/**********************************************/
/* WHILE WE FIND NICE HEX CHARS, BUILD AN INT */
/* RETURN NUMBER OF CHARS PROCESSED           */
/**********************************************/
static int 
hexToInt (unsigned char **ptr, long *intValue)
{
  int numChars = 0;
  int hexValue;

  *intValue = 0;
  while (**ptr)
    {
      hexValue = hex(**ptr);
      if (hexValue >=0)
        {
	  *intValue = (*intValue <<4) | (unsigned) hexValue;
	  numChars ++;
        }
      else
	break;
      (*ptr)++;
    }
  return (numChars);
}


/* Function: opcode_size
   Determine number of bytes in full opcode by examining first word.
*/
static int
opcode_size(unsigned int opcode)
{
  if ((opcode & 0xff00) == 0)
    return 2;

  if ((opcode & 0xf800) == 0)
    return 4;

  if ((opcode & 0xf800) == 0x7800)
    return 4;

  if ((opcode & 0xf000) == 0xc000)
    return 4;

  if ((opcode & 0xf100) == 0x2000)
    return 4;

  if ((opcode & 0xfff0) == 0x30e0)
    return 4;

  if ((opcode & 0xf008) == 0x6008)
    return 4;

  if ((opcode & 0xf808) == 0x7008)
    return 4;

  opcode >>= 8;
  if (opcode == 0x0c || opcode == 0x0d || opcode == 0x31)
    return 4;

  return 2;
}

static struct {
  unsigned long  addr;
  unsigned long  addr2;
  unsigned int   opcode;
  unsigned int   opcode2;
} stepinfo;

/* Function: prepare_to_step
   Called from handle_exception to prepare the user program to single-step.
   Places a trap instruction after the target instruction, with special 
   extra handling for branch instructions.
*/

static void
prepare_to_step(void)
{
  unsigned long pc = registers.pc;
  unsigned long next_pc, next_pc2;
  unsigned int  op, op2, sp;
  unsigned char op_msb, op_lsb;
  int  r12;
  char r8;

  op = get_word(pc);
  op_msb = (op >> 8) & 0xff;
  op_lsb = op & 0xff;
  op2 = get_word(pc + 2);
  next_pc = pc + opcode_size(op);
  next_pc2 = 0;

  if (op_msb == 0)
    {
      if (op_lsb == 2)
	{
	  /* IRET */
	  sp = registers.r[SP];
	  next_pc = *(unsigned *)(sp - 4);
	  next_pc = (next_pc << 16) | *(unsigned *)(sp - 6);
	}
      else if (op_lsb == 3)
	{
	  /* RET */
	  sp = registers.r[SP];
	  next_pc = *(unsigned *)(sp - 2);
	  next_pc = (next_pc << 16) | *(unsigned *)(sp - 4);
	}
      else
	{
	  op2 = op_lsb & 0xf0;
	  if (op2 && op2 < 0x40)
	    {
	      /* {CALLR,BR,ICALLR} Rs */
	      next_pc = (pc + 2) + (int)registers.r[op_lsb & 0xf];
	    }
	  else if (op2 < 0x80 || op2 == 0xa0 || op2 == 0xb0)
	    {
	      /* {JMP,ICALL,CALL} Rb,Rs */
	      next_pc = registers.r[(op_lsb & 0x10) ? 9 : 8];
	      next_pc = (next_pc << 16) | (unsigned int)registers.r[op_lsb & 0xf];
	    }
	}
    }
  else if (op_msb < 4)
    {
      /* {CALLF,JMPF,ICALLF} a24 */
      next_pc = ((unsigned long)op2) << 8;
      next_pc |= op_lsb;
    }
  else if (op_msb < 8)
    {
      if ((op2 & 0xf000) == 0)
	{
	    /* Bx Rd,#imm4,r12 */
	    /* Bx Rd,Rs,r12    */
	    r12 = op2 << 4;
	    r12 >>= 4;
	    next_pc2 = (pc + 4) + r12;
	}
    }
  else if (op_msb == 0x0c || op_msb == 0x0d || (op_msb & 0xf1) == 0x20 ||
	   ((op_msb >= 0x7c && op_msb <= 0x7f) && (op2 & 0x8000) == 0))
    {
      /* Bxx Rd,Rs,r12    */
      /* Bxx Rd,#imm8,r12 */
      /* Bx  m8,#imm3,r12 */
      /* Bx s8,#imm3,r12  */
      r12 = op2 << 4;
      r12 >>= 4;
      next_pc2 = (pc + 4) + r12;
    }
  else if ((op_msb & 0xf0) == 0x10)
    {
      /* {BR,CALLR} r12 */
      r12 = (op & 0xffe) << 4;
      r12 >>= 4;
      next_pc = (pc + 2) + r12;
    }
  else if ((op_msb & 0xe0) == 0xc0)
    {
      /* Bxx Rx,#imm16,r8 */
      /* TBxx r8 */
      r8 = op_lsb;
      next_pc2 = next_pc + r8;
    }

  stepinfo.addr = next_pc;
  stepinfo.opcode = get_word(next_pc);
  set_word(next_pc, BREAKPOINT_OPCODE);

  if (next_pc2)
    {
      stepinfo.addr2 = next_pc2;
      stepinfo.opcode2 = get_word(next_pc2);
      set_word(next_pc2, BREAKPOINT_OPCODE);
    }
}

/* Function: finish_from_step
   Called from handle_exception to finish up when the user program 
   returns from a single-step.  Replaces the instructions that had
   been overwritten by breakpoint. */

static void
finish_from_step (void)
{
  if (stepinfo.addr)	/* anything to do? */
    {
      set_word(stepinfo.addr, stepinfo.opcode);
      stepinfo.addr = 0;
      if (stepinfo.addr2)
	{
	  set_word(stepinfo.addr2, stepinfo.opcode2);
          stepinfo.addr2 = 0;
	}
    }
}


/*
 * UART support
 */
#define UART0_BASE 0x7f38
#define UART1_BASE 0x7f48

#define UART_CR(base)  (*(volatile unsigned char *)(base))
#define UART_RXD(base) (*(volatile unsigned int *)((base) + 2))
#define UART_TXD(base) (*(volatile unsigned int *)((base) + 4))

#define UART_CR_RUN       0x80
#define UART_CR_ERR       0x40
#define UART_CR_BAUD_115k 0x20
#define UART_CR_PARITY    0x10
#define UART_CR_TXEMPTY   0x08
#define UART_CR_TXIEN     0x04
#define UART_CR_RXRDY     0x02
#define UART_CR_RXIEN     0x01

#define DBG_UART UART0_BASE

static void
putDebugChar(unsigned ch)
{
  while ((UART_CR(DBG_UART) & UART_CR_TXEMPTY) == 0) ;

  UART_TXD(DBG_UART) = ch;
}

static unsigned char
getDebugChar(void)
{
  while ((UART_CR(DBG_UART) & UART_CR_RXRDY) == 0) ;

  return UART_RXD(DBG_UART);
}

void
uart_init(void)
{
  UART_CR(DBG_UART) |= (UART_CR_RUN | UART_CR_RXIEN);
}


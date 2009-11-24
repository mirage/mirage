/*
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

/*
 *   A debug packet whose contents are <data> looks like:
 *
 *        $ <data> # CSUM1 CSUM2
 *
 *        <data> must be ASCII alphanumeric and cannot include characters
 *        '$' or '#'.  If <data> starts with two characters followed by
 *        ':', then the existing stubs interpret this as a sequence number.
 *
 *       CSUM1 and CSUM2 are ascii hex representation of an 8-bit 
 *        checksum of <data>, the most significant nibble is sent first.
 *        the hex digits 0-9,a-f are used.
 *
 *   We respond with:
 *
 *        +       - if CSUM is correct and ready for next packet
 *        -       - if CSUM is incorrect
 *
 *   <data> is as follows:
 *   Most values are encoded in ascii hex digits.
 */

#include "debug.h"
#include <signal.h>

/*
 * buffers that hold the packets while they're being constructed.
 */
char packet_in_buf[BUFMAX];
char packet_out_buf[BUFMAX];
int packet_index;

/*
 * indicate to caller of mem2hex or hex2mem that there has been an error. 
 * 0 means ok, 1 means error
 */
volatile int mem_err = 0;

/*
 * 1 means print debugging messages from the target, 0 means be quiet. This is
 * changed by gdb_debug().
 */
int remote_debug = 0;

/*
 * indicate whether the debug vectors ahave been initialized
 * 0 means not yet, 1 means yep, it's ready.
 */
int initialized = 0;

/*
 * These variables are instantialted in the GDB stub code.
 */

/* this is a list of signal to exception mappings. */
extern struct trap_info hard_trap_info[];

/* this is a memory fault exception handler, used by mem2hex & hex2mem */
extern void set_mem_fault_trap();

/*
 * print debugging messages. This uses print, rather than one of the
 * stdio routines, cause if there are stack or memory problems, the
 * stdio routines don't work.
 *	params are the debug level, and the string to print
 *	it doesn't return anything.
 */
void
debuglog(int level, char *msg)
{
  char *p;
  unsigned char buf[BUFMAX];
  char newmsg[BUFMAX];
  int i;

  if (level > remote_debug)
    return;

  if ((level <0) || (level > 100)) {
    print ("ERROR: debug print level out of range");
    return;
  }

  /* convert some characters so it'll look right in the log */
  p = newmsg;
  for (i = 0 ; msg[i] != '\0'; i++) {
    if (i > BUFMAX)
      print ("\r\nERROR: Debug message too long\r\n");
    switch (msg[i]) {
    case '\n':                                  /* newlines */
      *p++ = '\\';
      *p++ = 'n';
      continue;
    case '\r':                                  /* carriage returns */
      *p++ = '\\';
      *p++ = 'r';
      continue;
    case '\033':                                /* escape */
      *p++ = '\\';
      *p++ = 'e';
      continue;
    case '\t':                                  /* tab */
      *p++ = '\\';
      *p++ = 't';
      continue;
    case '\b':                                  /* backspace */
      *p++ = '\\';
      *p++ = 'b';
      continue;
    default:                                    /* no change */
      *p++ = msg[i];
    }

    if (msg[i] < 26) {                          /* modify control characters */
      *p++ = '^';
      *p++ = msg[i] + 'A';
      continue;
    }
    if (msg[i] >= 127) {			/* modify control characters */
      *p++ = '!';
      *p++ = msg[i] + 'A';
      continue;
    }
  }
  *p = '\0';                                    /* terminate the string */
  print (newmsg);
  print ("\r\n");
}

/*
 * convert an ascii hex digit to a number.
 *	param is hex digit.
 *	returns a decimal digit.
 */
int
hex2digit (int digit)
{  
  if (digit == 0)
    return 0;

  if (digit >= '0' && digit <= '9')
    return digit - '0';
  if (digit >= 'a' && digit <= 'f')
    return digit - 'a' + 10;
  if (digit >= 'A' && digit <= 'F')
    return digit - 'A' + 10;
  
  /* shouldn't ever get this far */
  return ERROR;
}

/*
 * convert number NIB to a hex digit.
 *	param is a decimal digit.
 *	returns a hex digit.
 */
char
digit2hex(int digit)
{
  if (digit < 10)
    return '0' + digit;
  else
    return 'a' + digit - 10;
}

/* 
 * Convert the memory pointed to by mem into hex, placing result in buf.
 * Return a pointer to the last char put in buf (null), in case of mem fault,
 * return 0.
 * If MAY_FAULT is non-zero, then we will handle memory faults by returning
 * a 0, else treat a fault like any other fault in the stub.
 */
unsigned char *
mem2hex(unsigned char *mem, unsigned char *buf, int count, int may_fault)
{
  unsigned char ch;

  DEBUG (1, "In mem2hex");

  set_mem_fault_trap(MAY_FAULT);

  while (count-- > 0) {
    ch = *mem++;
    if (mem_err) {
      DEBUG (1, "memory fault in mem2hex");
      return 0;
    }
    *buf++ = digit2hex(ch >> 4);
    *buf++ = digit2hex(ch & 0xf);
  }

  *buf = 0;

  set_mem_fault_trap(OK);

  return buf;
}

/*
 * Convert the hex array pointed to by buf into binary to be placed in mem
 * return a pointer to the character AFTER the last byte written
 */
unsigned char *
hex2mem(unsigned char *buf, unsigned char *mem, int count, int may_fault)
{
  int i;
  unsigned char ch;

  DEBUG (1, "In hex2mem");

  set_mem_fault_trap(may_fault);

  for (i=0; i<count; i++) {
    ch = hex2digit(*buf++) << 4;
    ch |= hex2digit(*buf++);
    *mem++ = ch;
    if (mem_err)
      return 0;
  }

  set_mem_fault_trap(0);

  return mem;
}

/*
 * while we find nice hex chars, build an int.
 *	param is a pointer to the string.
 *	returns the int in the param field, and the number of chars processed.
 */
int
hex2int (char **ptr, int *intValue)
{
  int numChars = 0;
  int hexValue;

  *intValue = 0;

  while (**ptr)
    {
      hexValue = hex2digit(**ptr);
      if (hexValue < 0)
        break;

      *intValue = (*intValue << 4) | hexValue;
      numChars ++;
      (*ptr)++;
    }
  return (numChars);
}

/*
 * Scan for the sequence $<data>#<checksum>
 */
void
getpacket(unsigned char *buffer)
{
  unsigned char checksum;
  unsigned char xmitcsum;
  int i;
  int count;
  unsigned char ch;

  do {
    /* wait around for the start character, ignore all other characters */
    while ((ch = (inbyte() & 0x7f)) != '$') ;
    
    checksum = 0;
    xmitcsum = -1;
    
    count = 0;
    
    /* now, read until a # or end of buffer is found */
    while (count < BUFMAX) {
      ch = inbyte() & 0x7f;
      if (ch == '#')
	break;
      checksum = checksum + ch;
      buffer[count] = ch;
      count = count + 1;
    }
    
    if (count >= BUFMAX)
      continue;
    
    buffer[count] = 0;
    
    if (ch == '#') {
      xmitcsum = hex2digit(inbyte() & 0x7f) << 4;
      xmitcsum |= hex2digit(inbyte() & 0x7f);
#if 1
      /* Humans shouldn't have to figure out checksums to type to it. */
      outbyte ('+');
      return;
#endif
      if (checksum != xmitcsum)
	outbyte('-');	/* failed checksum */
      else {
	outbyte('+'); /* successful transfer */
	/* if a sequence char is present, reply the sequence ID */
	if (buffer[2] == ':') {
	  outbyte(buffer[0]);
	  outbyte(buffer[1]);
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

/*
 * Send the packet in buffer.
 */
void
putpacket(unsigned char *buffer)
{
  unsigned char checksum;
  int count;
  unsigned char ch;

  /*  $<packet info>#<checksum>. */
  do {
    outbyte('$');
    checksum = 0;
    count = 0;
    
    while (ch = buffer[count]) {
      if (! outbyte(ch))
	return;
      checksum += ch;
      count += 1;
    }
    
    outbyte('#');
    outbyte(digit2hex(checksum >> 4));
    outbyte(digit2hex(checksum & 0xf));
    
  }
  while ((inbyte() & 0x7f) != '+');
}

/*
 *
 */
void
gdb_event_loop(int sigval, unsigned long *registers)
{
  int addr;
  int length;
  unsigned char *ptr;
  ptr = packet_out_buf;

  DEBUG (1, "In gdb_event_loop");

  while (1) {
    packet_out_buf[0] = 0;
    
    getpacket(packet_in_buf);      
    ptr = &packet_in_buf[1];

    switch (packet_in_buf[0]) {
    case '?':		/* get the last known signal */
      gdb_last_signal(sigval);
      break;
      
    case 'd':		/* toggle debug messages from the stub */
      gdb_toggle();
      break;
      
    case 'g':		/* return the value of the CPU registers */
      target_read_registers(registers);
      break;
      
    case 'G':	   /* set the value of the CPU registers - return OK */
      target_write_registers(registers);
      break;
      
    case 'm':	  /* mAA..AA,LLLL  Read LLLL bytes at address AA..AA */
      /* Try to read %x,%x.  */
      if (hex2int((char **)&ptr, &addr)
	  && *ptr++ == ','
	  && hex2int((char **)&ptr, &length)) {
	gdb_read_memory(addr, length);
      } else {
	make_return_packet(1);
      }
      break;
      
    case 'M': /* MAA..AA,LLLL: Write LLLL bytes at address AA.AA return OK */
      /* Try to read '%x,%x:'.  */
      if (hex2int((char **)&ptr, &addr)
	  && *ptr++ == ','
	  && hex2int((char **)&ptr, &length)
	  && *ptr++ == ':') {
	gdb_write_memory (addr, length, ptr);
      } else {
	make_return_packet(2);
      }
      break;
      
    case 'c':    /* cAA..AA    Continue at address AA..AA(optional) */
      /* try to read optional parameter, pc unchanged if no parm */
      if (hex2int((char **)&ptr, &addr)) {
	write_pc(registers, addr);
      }
      
      /*
       * we need to flush the instruction cache here, as we may have
       * deposited a breakpoint, and the icache probably has no way of
       * knowing that a data ref to some location may have changed
       * something that is in the instruction cache. 
       */
      
      flush_i_cache();
      /* by returning, we pick up execution where we left off */
      return;

      /* kill the program */
    case 'k' :
      gdb_kill();
      break;
    case 'r':		/* Reset */
      target_reset();
      break;
    }			/* switch */
    
    /* reply to the request */
    putpacket(packet_out_buf);
  }
  DEBUG (1, "Leaving handle_exception()");
}

/* Convert the hardware trap type code to a unix signal number. */

int
computeSignal(int tt)
{
  struct trap_info *ht;

  for (ht = hard_trap_info; ht->tt && ht->signo; ht++)
    if (ht->tt == tt)
      return ht->signo;

  return SIGHUP;		/* default for things we don't know about */
}

/*
 * Set up exception handlers for tracing and breakpoints
 */
void
set_debug_traps()
{
  struct trap_info *ht;

  DEBUG (1, "Entering set_debug_traps()");

  if (hard_trap_info->tt == 0) {
    print ("ERROR: ARG#$@%^&*!! no hard trap info!!\r\n");
  }

  for (ht = hard_trap_info; ht->tt && ht->signo; ht++) {
    exception_handler(ht->tt, (unsigned long)default_trap_hook);
  }

  /* In case GDB is started before us, ack any packets (presumably
     "$?#xx") sitting there.  */

  outbyte ('+');
  initialized = 1;

  DEBUG (1, "Leaving set_debug_traps()");
}

/*
 * make a return packet.
 *	param is the value to return.
 *		0 = OK, any other value is converted to a two digit hex number.
 *	returns a string or "OK" or "ENN", where NN is the error number. Each N
 *		is an ASCII encoded hex digit.
 */
char *
make_return_packet(int val)
{
  if (val == 0) {
     packet_out_buf[0] = 'O';
     packet_out_buf[1] = 'K';
     packet_out_buf[2] = 0;  
  } else {
    packet_out_buf[0] = 'E';
    packet_out_buf[1] = digit2hex((val >> 4) & 0xf);
    packet_out_buf[2] = digit2hex(val & 0xf);
    packet_out_buf[3] = 0;
  }
  return(packet_out_buf);
}

/*
 * g - read registers.
 *	no params.
 *	returns a vector of words, size is NUM_REGS.
 */
char *
gdb_read_registers()
{
}

/*
 * G - write registers.
 *	param is a vector of words, size is NUM_REGS.
 *	returns an OK or an error number.
 */
char *
gdb_write_registers(char *regs)
{
}

/*
 * m - read memory.
 *	params are the address to start the read at and the number of
 *		bytes to read.  
 *	returns a vector of nbytes or an error number.
 *	Can be fewer bytes than requested if able to read only part of the
 *	data. 
 */
char *
gdb_read_memory(long addr, int nbytes)
{
  if (mem2hex((char *)addr, packet_out_buf, nbytes, MAY_FAULT))
    return(packet_out_buf);
  else {
    return(make_return_packet(3));
  }
}

/*
 * M write memory
 *	params are the address to start writing to, the number of
 *		bytes to write, and the new values of the bytes.
 *	returns an OK or an error number.
 */
char *
gdb_write_memory(long addr, int nbytes, char *mem)
{
 if (hex2mem(mem, (char *)addr, nbytes, MAY_FAULT))
    return(make_return_packet(OK));
  else {
    return(make_return_packet(3));
  }
}

/*
 * c - continue at address.
 *	param is the address to start at, and an optional signal. If
 *		sig is zero, then ignore it.
 *	returns an OK or an error number.
 */
char *
gdb_continue(int sig, long addr)
{
}

/*
 * s - step instruction(s)
 *	param is the address to start at, and an optional signal. If
 *		sig is zero, then ignore it.
 *	returns an OK or an error number.
 */
char *
gdb_step(int sig, long addr)
{
}

/*
 * k - kill program.
 *	no params.
 *	returns an OK or an error number.
 */
char *
gdb_kill()
{
  /* generically, we can't do anything for this command */
  return(make_return_packet(OK));
}

/*
 * ? - last signal.
 *	no params.
 *	returns the last signal number.
 */
char *
gdb_last_signal(int val)
{
  DEBUG (1, "Entering gdb_last_signal()");

  packet_out_buf[0] = 'S';
  packet_out_buf[1] = digit2hex(val >> 4);
  packet_out_buf[2] = digit2hex(val & 0xf);
  packet_out_buf[3] = 0;

  DEBUG (1, "Leaving gdb_last_signal()");
  return (packet_out_buf);
}

/*
 * b - change baud rate.
 *	param is the new baudrate
 *	returns the baud rate.
 */
char *
gdb_baudrate(int baud)
{
  /* generically, we can't do anything for this command */
  return(make_return_packet(OK));
}

/*
 * T - dump state.
 *	no params.
 *	returns the signal number, the registers, the thread ID, and
 *		possible extensions in a vector that looks like:
 *			TAAn...:r...;n...:r...;n...:r...; where:
 *                       AA = signal number
 *                       n... = register number (hex)
 *                       r... = register contents
 *                       n... = `thread'
 *                       r... = thread process ID.  This is a hex integer.
 *                       n... = other string not starting with valid hex digit.
 *                              gdb should ignore this n,r pair and go on to
 *				the next. This way we can extend the protocol.
 */
char *
gdb_dump_state()
{
}

/*
 * D - host requests a detach
 *	no params.
 *	returns either a S, T, W, or X command.
 *	returns an OK or an error number.
 */
char *
gdb_detach()
{
}

/*
 * H - set thread.
 *	params are the command to execute and the thread ID.
 *		cmd = 'c' for thread used in step and continue;
 *		cmd = 'g' for thread used in other operations.
 *		tid = -1 for all threads.
 *		tid = zero, pick a thread,any thread.
 *	returns an OK or an error number.
 */
char *
gdb_set_thread(int cmd, int tid)
{
  /* generically, we can't do anything for this command */
  return(make_return_packet(OK));
}

/*
 * p - read one register.
 *	param is the register number.
 *	returns the register value or ENN.
 */
char *
gdb_read_reg(int reg)
{
  /* generically, we can't do anything for this command */
  return(make_return_packet(OK));
}

/*
 * P - write one register.
 *	params are the register number, and it's new value.
 *	returns the register value or ENN.
 */
char *
gdb_write_reg(int reg, long val)
{
  /* generically, we can't do anything for this command */
  
  return(make_return_packet(OK));
}

/*
 * W - process exited.
 *	no params.
 *	returns the exit status.
 */
char *
gdb_exited()
{
  /* generically, we can't do anything for this command */
  return(make_return_packet(OK));
}

/*
 * X - process terminated.
 *	no params.
 *	returns the last signal.
 */
char *
gdb_terminated()
{
}

/*
 * O - hex encoding.
 *	params are a vector of bytes, and the number of bytes to encode.
 *	returns a vector of ASCII encoded hex numbers.
 */
char *
gdb_hex(char *str, int nbytes)
{
}

/*
 * A - tread alive request.
 *	param is the thread ID.
 *	returns an OK or an error number.
 */
char *
gdb_thread_alive(int tid)
{
  /* generically, we can't do anything for this command */
  return(make_return_packet(OK));
}

/*
 * ! - extended protocol.
 *	no params.
 *	returns an OK or an error number.
 */
char *
gdb_extended()
{
  /* generically, we can't do anything for this command */
  return(make_return_packet(OK));
}

/*
 * d - toggle gdb stub diagnostics.
 *	no params.
 *	returns an OK or an error number.
 */
char *
gdb_debug()
{
  if (remote_debug > 0)
    remote_debug = 0;
  else
    remote_debug = 1;

  return(make_return_packet(OK));
}

/*
 * d - toggle gdb stub.
 *	no params.
 *	returns an OK or an error number.
 */
char *
gdb_toggle()
{
  static int level = 0;

  if (remote_debug) {
    level = remote_debug;
    remote_debug = 0;
  } else {
    remote_debug = level;
  }

  return(make_return_packet(OK));
}

/*
 * r - reset target
 *	no params.
 *	returns an OK or an error number.
 */
char *
gdb_reset()
{
  /* generically, we can't do anything for this command */
  return(make_return_packet(OK));
}

/*
 * t - search backwards.
 *	params are the address to start searching from, a pattern to match, and
 *		the mask to use.
 *	FIXME: not entirely sure what this is supposed to return.
 */
char *
gdb_search(long addr, long pat, long mask)
{
  /* generically, we can't do anything for this command */
  return(make_return_packet(OK));
}

/*
 * q - general get query.
 *	param is a string, that's the query to be executed.
 *	FIXME: not entirely sure what this is supposed to return.
 */
char *
gdb_get_query(char *query)
{
  /* generically, we can't do anything for this command */
  return(make_return_packet(OK));
}

/*
 * Q - general set query
 *	param is a string, that's the query to be executed.
 *	FIXME: not entirely sure what this means.
 *	returns an OK or an error number.
 */
char *
gdb_set(char *query)
{
  /* generically, we can't do anything for this command */
  return(make_return_packet(OK));
}



/*
 * Copyright (c) 1996 Cygnus Support
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

#include <string.h>
#include <signal.h>
#include "debug.h"
#include "asm.h"
#include "slite.h"

extern unsigned long rdtbr();
extern struct trap_entry fltr_proto;
extern void trap_low();
exception_t default_trap_hook = trap_low;
void target_reset();
void flush_i_cache();
char *target_read_registers(unsigned long *);
char *target_write_registers(unsigned long *);
char *target_dump_state(unsigned long *);

#define NUMREGS 72

/* Number of bytes of registers.  */
#define NUMREGBYTES (NUMREGS * 4)

enum regnames {G0, G1, G2, G3, G4, G5, G6, G7,
		 O0, O1, O2, O3, O4, O5, SP, O7,
		 L0, L1, L2, L3, L4, L5, L6, L7,
		 I0, I1, I2, I3, I4, I5, FP, I7,

		 F0, F1, F2, F3, F4, F5, F6, F7,
		 F8, F9, F10, F11, F12, F13, F14, F15,
		 F16, F17, F18, F19, F20, F21, F22, F23,
		 F24, F25, F26, F27, F28, F29, F30, F31,
		 Y, PSR, WIM, TBR, PC, NPC, FPSR, CPSR };

/*
 * Each entry in the trap vector occupies four words, typically a jump
 * to the processing routine.
 */
struct trap_entry {
  unsigned sethi_filler:10;
  unsigned sethi_imm22:22;
  unsigned jmpl_filler:19;
  unsigned jmpl_simm13:13;
  unsigned long filler[2];
};

/*
 * This table contains the mapping between SPARC hardware trap types, and
 * signals, which are primarily what GDB understands.  It also indicates
 * which hardware traps we need to commandeer when initializing the stub.
 */
struct trap_info hard_trap_info[] = {
  {1, SIGSEGV},			/* instruction access error */
  {2, SIGILL},			/* privileged instruction */
  {3, SIGILL},			/* illegal instruction */
  {4, SIGEMT},			/* fp disabled */
  {36, SIGEMT},			/* cp disabled */
  {7, SIGBUS},			/* mem address not aligned */
  {9, SIGSEGV},			/* data access exception */
  {10, SIGEMT},			/* tag overflow */
  {128+1, SIGTRAP},		/* ta 1 - normal breakpoint instruction */
  {0, 0}			/* Must be last */
};

extern struct trap_entry fltr_proto;
void
exception_handler (int tt, unsigned long routine)
{
  struct trap_entry *tb;        /* Trap vector base address */

  DEBUG (1, "Entering exception_handler()");
  if (tt != 256) {
    tb = (struct trap_entry *) (rdtbr() & ~0xfff);
  } else {
    tt = 255;
    tb = (struct trap_entry *) 0;
  }

  tb[tt] = fltr_proto;

  tb[tt].sethi_imm22 = routine >> 10;
  tb[tt].jmpl_simm13 = routine & 0x3ff;

  DEBUG (1, "Leaving exception_handler()");
}

/*
 * This is so we can trap a memory fault when reading or writing
 * directly to memory.
 */
void
set_mem_fault_trap(enable)
     int enable;
{
  extern void fltr_set_mem_err();

  DEBUG (1, "Entering set_mem_fault_trap()");

  mem_err = 0;

  if (enable)
    exception_handler(9, (unsigned long)fltr_set_mem_err);
  else
    exception_handler(9, (unsigned long)trap_low);

  DEBUG (1, "Leaving set_mem_fault_trap()");
}

/*
 * This function does all command procesing for interfacing to gdb.  It
 * returns 1 if you should skip the instruction at the trap address, 0
 * otherwise.
 */
extern void breakinst();

void
handle_exception (registers)
     unsigned long *registers;
{
  int sigval;

  /* First, we must force all of the windows to be spilled out */

  DEBUG (1, "Entering handle_exception()");

/*  asm("mov %g0, %wim ; nop; nop; nop"); */
  asm("	save %sp, -64, %sp	\n\
	save %sp, -64, %sp	\n\
	save %sp, -64, %sp	\n\
	save %sp, -64, %sp	\n\
	save %sp, -64, %sp	\n\
	save %sp, -64, %sp	\n\
	save %sp, -64, %sp	\n\
	save %sp, -64, %sp	\n\
	restore			\n\
	restore			\n\
	restore			\n\
	restore			\n\
	restore			\n\
	restore			\n\
	restore			\n\
	restore			\n\
");

  if (registers[PC] == (unsigned long)breakinst) {
    registers[PC] = registers[NPC];
    registers[NPC] += 4;
  }

  /* get the last know signal number from the trap register */
  sigval = computeSignal((registers[TBR] >> 4) & 0xff);

  /* call the main command processing loop for gdb */
  gdb_event_loop (sigval, registers);
}

/*
 * This function will generate a breakpoint exception.  It is used at the
 * beginning of a program to sync up with a debugger and can be used
 * otherwise as a quick means to stop program execution and "break" into
 * the debugger.
 */
void
breakpoint()
{
  DEBUG (1, "Entering breakpoint()");

  if (!initialized)
    return;

  asm("	.globl " STRINGSYM(breakinst) "		\n\
	" STRINGSYM(breakinst) ": ta 128+1	\n\
	nop					\n\
	nop					\n\
      ");
}

/*
 * This is just a test vector for debugging excpetions.
 */
void
bad_trap(tt)
int tt;
{
  print ("Got a bad trap #");
  outbyte (tt);
  outbyte ('\n');
  asm("ta 0		\n\
	nop		\n\
	nop		\n\
      ");
}

/*
 * This is just a test vector for debugging excpetions.
 */
void
soft_trap(tt)
int tt;
{
  print ("Got a soft trap #");
  outbyte (tt);
  outbyte ('\n');
  asm("ta 0		\n\
	nop		\n\
	nop		\n\
      ");
}

/*
 * Flush the instruction cache.  We need to do this for the debugger stub so
 * that breakpoints, et. al. become visible to the instruction stream after
 * storing them in memory.
 * 
 * For the sparclite, we need to do something here, but for a standard
 * sparc (which SIS simulates), we don't.
 */

void
flush_i_cache ()
{
}

/*
 * This will reset the processor, so we never return from here.
 */
void
target_reset()
{
  asm ("call 0		\n\
	nop ");
}

/*
 * g - read registers.
 *	no params.
 *	returns a vector of words, size is NUM_REGS.
 */
char *
target_read_registers(unsigned long *registers)
{
  char *ptr;
  unsigned long *sp;
 
  DEBUG (1, "In target_read_registers()");

  ptr = packet_out_buf;
  ptr = mem2hex((char *)registers, ptr, 16 * 4, 0); /* G & O regs */
  ptr = mem2hex((unsigned char *)(sp + 0), ptr, 16 * 4, 0); /* L & I regs */
  memset(ptr, '0', 32 * 8); /* Floating point */
  mem2hex((char *)&registers[Y],
	  ptr + 32 * 4 * 2,
	  8 * 4,
	  0);		/* Y, PSR, WIM, TBR, PC, NPC, FPSR, CPSR */
  return (ptr);
}

/*
 * G - write registers.
 *	param is a vector of words, size is NUM_REGS.
 *	returns an OK or an error number.
 */
char *
target_write_registers(unsigned long *registers)
{	
  unsigned char *ptr;
  unsigned long *sp;
  unsigned long *newsp, psr;

  DEBUG (1, "In target_write_registers()");

  psr = registers[PSR];
  
  ptr = &packet_in_buf[1];

  hex2mem(ptr, (char *)registers, 16 * 4, 0); /* G & O regs */
  hex2mem(ptr + 16 * 4 * 2, (unsigned char *)(sp + 0), 16 * 4, 0); /* L & I regs */
  hex2mem(ptr + 64 * 4 * 2, (char *)&registers[Y],
	  8 * 4, 0);	/* Y, PSR, WIM, TBR, PC, NPC, FPSR, CPSR */
  
  /*
   * see if the stack pointer has moved.  If so, then copy the saved
   * locals and ins to the new location.  This keeps the window
   * overflow and underflow routines happy.
   */
  
  newsp = (unsigned long *)registers[SP];
  if (sp != newsp)
    sp = memcpy(newsp, sp, 16 * 4);
  
  /* Don't allow CWP to be modified. */
  
  if (psr != registers[PSR])
    registers[PSR] = (psr & 0x1f) | (registers[PSR] & ~0x1f);
  
  return (ptr);
}

char *
target_dump_state(unsigned long *registers)
{
  int tt;			/* Trap type */
  int sigval;
  char *ptr;
  unsigned long *sp;

  DEBUG (1, "In target_dump_state()");

  sp = (unsigned long *)registers[SP];

  tt = (registers[TBR] >> 4) & 0xff;

  /* reply to host that an exception has occurred */
  sigval = computeSignal(tt);
  ptr = packet_out_buf;

  *ptr++ = 'T';
  *ptr++ = hexchars[sigval >> 4];
  *ptr++ = hexchars[sigval & 0xf];

  *ptr++ = hexchars[PC >> 4];
  *ptr++ = hexchars[PC & 0xf];
  *ptr++ = ':';
  ptr = mem2hex((unsigned char *)&registers[PC], ptr, 4, 0);
  *ptr++ = ';';

  *ptr++ = hexchars[FP >> 4];
  *ptr++ = hexchars[FP & 0xf];
  *ptr++ = ':';
  ptr = mem2hex((unsigned char *)(sp + 8 + 6), ptr, 4, 0); /* FP */
  *ptr++ = ';';

  *ptr++ = hexchars[SP >> 4];
  *ptr++ = hexchars[SP & 0xf];
  *ptr++ = ':';
  ptr = mem2hex((unsigned char *)&sp, ptr, 4, 0);
  *ptr++ = ';';

  *ptr++ = hexchars[NPC >> 4];

  return (packet_out_buf);
}

void
write_pc(unsigned long *registers, unsigned long addr)
{
  DEBUG (1, "In write_pc");

  registers[PC] = addr;
  registers[NPC] = addr + 4;
}

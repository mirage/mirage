/* Stand-alone library for SPARClite
 *
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

#include "sparclite.h"
#include "asm.h"

/* LED blinking pattern can be changed by modifying __led_algorithm. */

enum ledtype
{
  led_marching,		/* marching pattern, only one led on at a time */
  led_random,		/* pseudo-random pattern */
  led_blinking,		/* all leds blink on and off */
  led_none		/* leds off all the time */
};

enum ledtype __led_algorithm = led_marching;


/* Pointer to hook for outbyte, set by stub's exception handler.  */
void (*__outbyte_hook) (int c);

#ifdef SL931
#define SDTR_BASE 0x200
#define SDTR_ASI 1
#define SDTR_SHIFT 0
#else
#define SDTR_BASE 0x10000000
#define SDTR_ASI 4
#define SDTR_SHIFT 16
#endif

#define get_uart_status(PORT) \
  (read_asi (SDTR_ASI, SDTR_BASE + 0x24 + (PORT) * 0x10) >> SDTR_SHIFT)

#define xmt_char(PORT, C) \
  write_asi (SDTR_ASI, SDTR_BASE + 0x20 + (PORT) * 0x10, (C) << SDTR_SHIFT)

#define rcv_char(PORT) \
  (read_asi (SDTR_ASI, SDTR_BASE + 0x20 + (PORT) * 0x10) >> SDTR_SHIFT)

void putDebugChar();

#if 0
void
set_uart (cmd)
     int cmd;
{
  write_asi (SDTR_ASI, SDTR_BASE + 0x24, cmd << SDTR_SHIFT);
}

void
set_timer_3 (val)
     int val;
{
  write_asi (SDTR_ASI, SDTR_BASE + 0x78, val << SDTR_SHIFT);
}
#endif


asm("
	.text
	.align 4

! Register window overflow handler.  Come here when save would move us
! into the invalid window.  This routine runs with traps disabled, and
! must be careful not to touch the condition codes, as PSR is never
! restored.
!
! We are called with %l0 = wim, %l1 = pc, %l2 = npc

	.globl " STRINGSYM(win_ovf) "
" STRINGSYM(win_ovf) ":
	mov	%g1, %l3		! Save g1, we use it to hold the wim
	srl	%l0, 1, %g1		! Rotate wim right
	sll	%l0, __WINSIZE-1, %l0
	or	%l0, %g1, %g1

	save	%g0, %g0, %g0		! Slip into next window
	mov	%g1, %wim		! Install the new wim

	std	%l0, [%sp + 0 * 4]	! save L & I registers
	std	%l2, [%sp + 2 * 4]
	std	%l4, [%sp + 4 * 4]
	std	%l6, [%sp + 6 * 4]

	std	%i0, [%sp + 8 * 4]
	std	%i2, [%sp + 10 * 4]
	std	%i4, [%sp + 12 * 4]
	std	%i6, [%sp + 14 * 4]

	restore				! Go back to trap window.
	mov	%l3, %g1		! Restore %g1

	jmpl	%l1,  %g0
	rett	%l2

! Register window underflow handler.  Come here when restore would move us
! into the invalid window.  This routine runs with traps disabled, and
! must be careful not to touch the condition codes, as PSR is never
! restored.
!
! We are called with %l0 = wim, %l1 = pc, %l2 = npc

	.globl " STRINGSYM(win_unf) "
" STRINGSYM(win_unf) ":
	sll	%l0, 1, %l3		! Rotate wim left
	srl	%l0, __WINSIZE-1, %l0
	or	%l0, %l3, %l0

	mov	%l0, %wim		! Install the new wim

	restore				! User's window
	restore				! His caller's window

	ldd	[%sp + 0 * 4], %l0	! restore L & I registers
	ldd	[%sp + 2 * 4], %l2
	ldd	[%sp + 4 * 4], %l4
	ldd	[%sp + 6 * 4], %l6

	ldd	[%sp + 8 * 4], %i0
	ldd	[%sp + 10 * 4], %i2
	ldd	[%sp + 12 * 4], %i4
	ldd	[%sp + 14 * 4], %i6

	save	%g0, %g0, %g0		! Back to trap window
	save	%g0, %g0, %g0

	jmpl	%l1,  %g0
	rett	%l2

! Read the TBR.

	.globl " STRINGSYM(rdtbr) "
" STRINGSYM(rdtbr) ":
	retl
	mov	%tbr, %o0

");

extern unsigned long rdtbr();

void
die(val)
     int val;
{
  static unsigned char *leds = (unsigned char *)0x02000003;

  *leds = val;

  while (1) ;
}

/* Each entry in the trap vector occupies four words. */

struct trap_entry
{
  unsigned sethi_filler:10;
  unsigned sethi_imm22:22;
  unsigned jmpl_filler:19;
  unsigned jmpl_simm13:13;
  unsigned long filler[2];
};

extern struct trap_entry fltr_proto;
asm ("
	.data
	.globl " STRINGSYM(fltr_proto) "
	.align 4
" STRINGSYM(fltr_proto) ":			! First level trap routine prototype
	sethi 0, %l0
	jmpl 0+%l0, %g0
	nop
	nop

	.text
	.align 4
");

/* Setup trap TT to go to ROUTINE.  If TT is between 0 and 255 inclusive, the
   normal trap vector will be used.  If TT is 256, then it's for the SPARClite
   DSU, and that always vectors off to 255 unrelocated.
*/

void
exceptionHandler (tt, routine)
     int tt;
     unsigned long routine;
{
  struct trap_entry *tb;	/* Trap vector base address */

  if (tt != 256)
    tb = (struct trap_entry *) (rdtbr() & ~0xfff);
  else
    {
      tt = 255;
      tb = (struct trap_entry *) 0;
    }

  tb[tt] = fltr_proto;

  tb[tt].sethi_imm22 = routine >> 10;
  tb[tt].jmpl_simm13 = routine & 0x3ff;
}

void
update_leds()
{
  static unsigned char *leds = (unsigned char *)0x02000003;
  static enum ledtype prev_algorithm = led_none;

  if (prev_algorithm != __led_algorithm)
    {
       *leds = 0xff;	/* turn the LEDs off */
       prev_algorithm = __led_algorithm;
    }

  switch (__led_algorithm)
    {
    case led_marching:
      {
	static unsigned char curled = 1;
	static unsigned char dir = 0;

	*leds = ~curled;

	if (dir)
	  curled <<= 1;
	else
	  curled >>= 1;

	if (curled == 0)
	  {
	    if (dir)
	      curled = 0x80;
	    else
	      curled = 1;
	    dir = ~dir;
	  }
	break;
      }

    case led_random:
      {
	static unsigned int next = 0;
	*leds = next & 0xff;
	next = (next * 1103515245 + 12345) & 0x7fff;
	break;
      }

    case led_blinking:
      {
	static unsigned char next = 0;
	*leds = next;
	next = ~next;
	break;
      }

    default:
      break;
    }
}

 /* 1/5th of a second? */

#define LEDTIME (20000000 / 500)

unsigned long ledtime = LEDTIME;

int
inbyte()
{
	return (getDebugChar());
}

int
getDebugChar()
{
  unsigned long countdown = ledtime;

  update_leds();

  while (1)
    {
      if ((get_uart_status(0) & 2) != 0) break;

      if (countdown-- == 0)
	{
	  countdown = ledtime;
	  update_leds();
	}
    }

  return rcv_char(0);
}

/* Output one character to the serial port */
void
outbyte(c)
    int c;
{
  if (__outbyte_hook)
    __outbyte_hook (c);
  else
    putDebugChar(c);
}

void
putDebugChar(c)
     int c;
{
  update_leds();

  while ((get_uart_status(0) & 1) == 0) ;

  xmt_char(0, c);
}

#if 0
int
write(fd, data, length)
     int fd;
     unsigned char *data;
     int length;
{
  int olength = length;

  while (length--)
    putDebugChar(*data++);

  return olength;
}

int
read(fd, data, length)
     int fd;
     unsigned char *data;
     int length;
{
  int olength = length;
  int c;

  while (length--)
    *data++ = getDebugChar();

  return olength;
}
#endif

/* Set the baud rate for the serial port, returns 0 for success,
   -1 otherwise */

#if 0
int
set_baud_rate(baudrate)
     int baudrate;
{
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
      return -1;
    }

  set_timer_3(baudrate);	/* Set it */
}
#endif

/*
 * cma101.c -- lo-level support for Cogent CMA101 development board.
 *
 * Copyright (c) 1996, 2001, 2002 Cygnus Support
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

#ifdef __mips16
/* The assembler portions of this file need to be re-written to
   support mips16, if and when that seems useful.
*/
#error cma101.c can not be compiled -mips16
#endif


#include <time.h>       /* standard ANSI time routines */

/* Normally these would appear in a header file for external
   use. However, we are only building a simple example world at the
   moment: */

#include "regs.S"

#if defined(MIPSEB)
#define BYTEREG(b,o)    ((volatile unsigned char *)(PHYS_TO_K1((b) + (o) + 7)))
#endif /* MIPSEB */
#if defined(MIPSEL)
#define BYTEREG(b,o)    ((volatile unsigned char *)(PHYS_TO_K1((b) + (o))))
#endif /* MIPSEL */

/* I/O addresses: */
#define RTCLOCK_BASE (0x0E800000) /* Mk48T02 NVRAM/RTC */
#define UART_BASE    (0x0E900000) /* NS16C552 DUART */
#define LCD_BASE     (0x0EB00000) /* Alphanumeric display */

/* LCD panel manifests: */
#define LCD_DATA     BYTEREG(LCD_BASE,0)
#define LCD_CMD      BYTEREG(LCD_BASE,8)

#define LCD_STAT_BUSY   (0x80)
#define LCD_SET_DDADDR  (0x80)

/* RTC manifests */
/* The lo-offsets are the NVRAM locations (0x7F8 bytes) */
#define RTC_CONTROL     BYTEREG(RTCLOCK_BASE,0x3FC0)
#define RTC_SECS        BYTEREG(RTCLOCK_BASE,0x3FC8)
#define RTC_MINS        BYTEREG(RTCLOCK_BASE,0x3FD0)
#define RTC_HOURS       BYTEREG(RTCLOCK_BASE,0x3FD8)
#define RTC_DAY         BYTEREG(RTCLOCK_BASE,0x3FE0)
#define RTC_DATE        BYTEREG(RTCLOCK_BASE,0x3FE8)
#define RTC_MONTH       BYTEREG(RTCLOCK_BASE,0x3FF0)
#define RTC_YEAR        BYTEREG(RTCLOCK_BASE,0x3FF8)

#define RTC_CTL_LOCK_READ       (0x40) /* lock RTC whilst reading */
#define RTC_CTL_LOCK_WRITE      (0x80) /* lock RTC whilst writing */

/* Macro to force out-standing memory transfers to complete before
   next sequence. For the moment we assume that the processor in the
   CMA101 board supports at least ISA II.  */
#define DOSYNC() asm(" .set mips2 ; sync ; .set mips0")

/* We disable interrupts by writing zero to all of the masks, and the
   global interrupt enable bit: */
#define INTDISABLE(sr,tmp) asm("\
 .set mips2 ; \
 mfc0 %0,$12 ; \
 lui %1,0xffff ; \
 ori %1,%1,0xfffe ; \
 and %1, %0, %1 ; \
 mtc0 %1,$12 ; \
 .set mips0" : "=d" (sr), "=d" (tmp))
#define INTRESTORE(sr) asm("\
 .set mips2 ; \
 mtc0 %0,$12 ; \
 .set mips0" : : "d" (sr))

/* TODO:FIXME: The CPU card support should be in separate source file
   from the standard CMA101 support provided in this file. */

/* The CMA101 board being used contains a CMA257 Vr4300 CPU:
   MasterClock is at 33MHz. PClock is derived from MasterClock by
   multiplying by the ratio defined by the DivMode pins:
   	DivMode(1:0)    MasterClock     PClock  Ratio
        00              100MHz          100MHz  1:1
        01              100MHz          150MHz  1.5:1
        10              100MHz          200MHz  2:1
        11              100Mhz          300MHz  3:1

   Are these pins reflected in the EC bits in the CONFIG register? or
   is that talking about a different clock multiplier?
   	110 = 1
        111 = 1.5
        000 = 2
        001 = 3
        (all other values are undefined)
*/

#define MASTERCLOCK (33) /* ticks per uS */
unsigned int pclock; /* number of PClock ticks per uS */
void
set_pclock (void)
{
  unsigned int config;
  asm volatile ("mfc0 %0,$16 ; nop ; nop" : "=r" (config)); /* nasty CP0 register constant */
  switch ((config >> 28) & 0x7) {
    case 0x7 : /* 1.5:1 */
     pclock = (MASTERCLOCK + (MASTERCLOCK / 2));
     break;

    case 0x0 : /* 2:1 */
     pclock = (2 * MASTERCLOCK);
     break;

    case 0x1 : /* 3:1 */
     pclock = (3 * MASTERCLOCK);
     break;

    case 0x6 : /* 1:1 */
    default : /* invalid configuration, so assume the lowest */
     pclock = MASTERCLOCK;
     break;
  }

  return;
}

#define PCLOCK_WAIT(x)  __cpu_timer_poll((x) * pclock)

/* NOTE: On the Cogent CMA101 board the LCD controller will sometimes
   return not-busy, even though it is. The work-around is to perform a
   ~50uS delay before checking the busy signal. */

static int
lcd_busy (void)
{
  PCLOCK_WAIT(50); /* 50uS delay */
  return(*LCD_CMD & LCD_STAT_BUSY);
}

/* Note: This code *ASSUMES* that the LCD has already been initialised
   by the monitor. It only provides code to write to the LCD, and is
   not a complete device driver. */

void
lcd_display (int line, const char *msg)
{
  int n;

  if (lcd_busy ())
   return;

  *LCD_CMD = (LCD_SET_DDADDR | (line == 1 ? 0x40 : 0x00));

  for (n = 0; n < 16; n++) {
    if (lcd_busy ())
     return;
    if (*msg)
     *LCD_DATA = *msg++;
    else
     *LCD_DATA = ' ';
  }

  return;
}

#define SM_PATTERN (0x55AA55AA)
#define SM_INCR ((256 << 10) / sizeof(unsigned int)) /* 64K words */

extern unsigned int __buserr_count(void);
extern void __default_buserr_handler(void);
extern void __restore_buserr_handler(void);

/* Allow the user to provide his/her own defaults.  */
unsigned int __sizemem_default;

unsigned int
__sizemem ()
{
  volatile unsigned int *base;
  volatile unsigned int *probe;
  unsigned int baseorig;
  unsigned int sr;
  extern char end[];
  char *endptr = (char *)&end;
  int extra;

  /* If the linker script provided a value for the memory size (or the user
     overrode it in a debugger), use that.  */
  if (__sizemem_default)
    return __sizemem_default;

  /* If we are running in kernel segment 0 (possibly cached), try sizing memory
     in kernel segment 1 (uncached) to avoid some problems with monitors.  */
  if (endptr >= K0BASE_ADDR && endptr < K1BASE_ADDR)
    endptr = (endptr - K0BASE_ADDR) + K1BASE_ADDR;

  INTDISABLE(sr,baseorig); /* disable all interrupt masks */

  __default_buserr_handler();
  __cpu_flush();

  DOSYNC();

  /* _end is the end of the user program.  _end may not be properly aligned
     for an int pointer, so we adjust the address to make sure it is safe.
     We use void * arithmetic to avoid accidentally truncating the pointer.  */

  extra = ((int) endptr & (sizeof (int) - 1));
  base = ((void *) endptr + sizeof (int) - extra);
  baseorig = *base;

  *base = SM_PATTERN;
  /* This assumes that the instructions fetched between the store, and
     the following read will have changed the data bus contents: */
  if (*base == SM_PATTERN) {
    probe = base;
    for (;;) {
      unsigned int probeorig;
      probe += SM_INCR;
      probeorig = *probe;
      /* Check if a bus error occurred: */
      if (!__buserr_count()) {
        *probe = SM_PATTERN;
        DOSYNC();
        if (*probe == SM_PATTERN) {
          *probe = ~SM_PATTERN;
          DOSYNC();
          if (*probe == ~SM_PATTERN) {
            if (*base == SM_PATTERN) {
              *probe = probeorig;
              continue;
            }
          }
        }
        *probe = probeorig;
      }
      break;
    }
  }

  *base = baseorig;
  __restore_buserr_handler();
  __cpu_flush();

  DOSYNC();

  INTRESTORE(sr); /* restore interrupt mask to entry state */

  return((probe - base) * sizeof(unsigned int));
}

/* Provided as a function, so as to avoid reading the I/O location
   multiple times: */
static int
convertbcd(byte)
     unsigned char byte;
{
  return ((((byte >> 4) & 0xF) * 10) + (byte & 0xF));
}

time_t
time (_timer)
     time_t *_timer;
{
  time_t result = 0;
  struct tm tm;
  *RTC_CONTROL |= RTC_CTL_LOCK_READ;
  DOSYNC();

  tm.tm_sec = convertbcd(*RTC_SECS);
  tm.tm_min = convertbcd(*RTC_MINS);
  tm.tm_hour = convertbcd(*RTC_HOURS);
  tm.tm_mday = convertbcd(*RTC_DATE);
  tm.tm_mon = convertbcd(*RTC_MONTH);
  tm.tm_year = convertbcd(*RTC_YEAR);

  DOSYNC();
  *RTC_CONTROL &= ~(RTC_CTL_LOCK_READ | RTC_CTL_LOCK_WRITE);

  tm.tm_isdst = 0;

  /* Check for invalid time information */
  if ((tm.tm_sec < 60) && (tm.tm_min < 60) && (tm.tm_hour < 24)
      && (tm.tm_mday < 32) && (tm.tm_mon < 13)) {

    /* Get the correct year number, but keep it in YEAR-1900 form: */
    if (tm.tm_year < 70)
      tm.tm_year += 100;

#if 0 /* NOTE: mon_printf() can only accept 4 arguments (format string + 3 fields) */
    mon_printf("[DBG: s=%d m=%d h=%d]", tm.tm_sec, tm.tm_min, tm.tm_hour);
    mon_printf("[DBG: d=%d m=%d y=%d]", tm.tm_mday, tm.tm_mon, tm.tm_year);
#endif

    /* Convert the time-structure into a second count */
    result = mktime (&tm);
  }

  if (_timer != NULL)
    *_timer = result;

  return (result);
}

/*> EOF cma101.c <*/

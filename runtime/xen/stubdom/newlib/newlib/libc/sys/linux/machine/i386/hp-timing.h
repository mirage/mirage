/* High precision, low overhead timing functions.  i686 version.
   Copyright (C) 1998 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@cygnus.com>, 1998.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

/* Modified for newlib by Jeff Johnston - June 27, 2002 */

#ifndef _HP_TIMING_H
#define _HP_TIMING_H	1

#include <string.h>
#include <stdio.h>
#include <sys/param.h>

#ifdef __i686__

/* The macros defined here use the timestamp counter in i586 and up versions
   of the x86 processors.  They provide a very accurate way to measure the
   time with very little overhead.  The time values themself have no real
   meaning, only differences are interesting.

   This version is for the i686 processors.  The difference to the i586
   version is that the timerstamp register is unconditionally used.  This is
   not the case for the i586 version where we have to perform runtime test
   whether the processor really has this capability.  We have to make this
   distinction since the sysdeps/i386/i586 code is supposed to work on all
   platforms while the i686 already contains i686-specific code.

   The list of macros we need includes the following:

   - HP_TIMING_AVAIL: test for availability.

   - HP_TIMING_INLINE: this macro is non-zero if the functionality is not
     implemented using function calls but instead uses some inlined code
     which might simply consist of a few assembler instructions.  We have to
     know this since we might want to use the macros here in places where we
     cannot make function calls.

   - hp_timing_t: This is the type for variables used to store the time
     values.

   - HP_TIMING_ZERO: clear `hp_timing_t' object.

   - HP_TIMING_NOW: place timestamp for current time in variable given as
     parameter.

   - HP_TIMING_DIFF_INIT: do whatever is necessary to be able to use the
     HP_TIMING_DIFF macro.

   - HP_TIMING_DIFF: compute difference between two times and store it
     in a third.  Source and destination might overlap.

   - HP_TIMING_ACCUM: add time difference to another variable.  This might
     be a bit more complicated to implement for some platforms as the
     operation should be thread-safe and 64bit arithmetic on 32bit platforms
     is not.

   - HP_TIMING_ACCUM_NT: this is the variant for situations where we know
     there are no threads involved.

   - HP_TIMING_PRINT: write decimal representation of the timing value into
     the given string.  This operation need not be inline even though
     HP_TIMING_INLINE is specified.

*/

/* We always assume having the timestamp register.  */
#define HP_TIMING_AVAIL		(1)

/* We indeed have inlined functions.  */
#define HP_TIMING_INLINE	(1)

/* We use 64bit values for the times.  */
typedef unsigned long long int hp_timing_t;

/* Internal variable used to store the overhead of the measurement
   opcodes.  */
extern hp_timing_t __libc_hp_timing_overhead;

/* Set timestamp value to zero.  */
#define HP_TIMING_ZERO(Var)	(Var) = (0)

/* That's quite simple.  Use the `rdtsc' instruction.  Note that the value
   might not be 100% accurate since there might be some more instructions
   running in this moment.  This could be changed by using a barrier like
   'cpuid' right before the `rdtsc' instruciton.  But we are not interested
   in accurate clock cycles here so we don't do this.  */
#define HP_TIMING_NOW(Var)	__asm__ __volatile__ ("rdtsc" : "=A" (Var))

/* Use two 'rdtsc' instructions in a row to find out how long it takes.  */
#define HP_TIMING_DIFF_INIT() \
  do {									      \
    int __cnt = 5;							      \
    __libc_hp_timing_overhead = ~0ull;					      \
    do									      \
      {									      \
	hp_timing_t __t1, __t2;						      \
	HP_TIMING_NOW (__t1);						      \
	HP_TIMING_NOW (__t2);						      \
	if (__t2 - __t1 < __libc_hp_timing_overhead)			      \
	  __libc_hp_timing_overhead = __t2 - __t1;			      \
      }									      \
    while (--__cnt > 0);						      \
  } while (0)

/* It's simple arithmetic for us.  */
#define HP_TIMING_DIFF(Diff, Start, End)	(Diff) = ((End) - (Start))

/* We have to jump through hoops to get this correctly implemented.  */
#define HP_TIMING_ACCUM(Sum, Diff) \
  do {									      \
    char __not_done;							      \
    hp_timing_t __oldval = (Sum);					      \
    hp_timing_t __diff = (Diff) - __libc_hp_timing_overhead;		      \
    do									      \
      {									      \
	hp_timing_t __newval = __oldval + __diff;			      \
	int __temp0, __temp1;						      \
	__asm__ __volatile__ ("xchgl %4, %%ebx\n\t"			      \
			      "lock; cmpxchg8b %1\n\t"			      \
			      "sete %0\n\t"				      \
			      "movl %4, %%ebx"				      \
			      : "=q" (__not_done), "=m" (Sum),		      \
				"=A" (__oldval), "=c" (__temp0),	      \
				"=SD" (__temp1)				      \
			      : "1" (Sum), "2" (__oldval),		      \
				"3" (__newval >> 32),			      \
				"4" (__newval & 0xffffffff)		      \
			      : "memory");				      \
      }									      \
    while (__not_done);							      \
  } while (0)

/* No threads, no extra work.  */
#define HP_TIMING_ACCUM_NT(Sum, Diff)	(Sum) += (Diff)

/* Print the time value.  */
#define HP_TIMING_PRINT(Buf, Len, Val) \
  do {									      \
    char __buf[20];							      \
    char *__cp = __buf + sizeof (__buf);				      \
    int __len = (Len);							      \
    char *__dest = (Buf);						      \
    do { 								      \
      *--__cp = Val % 10;						      \
      Val /= 10;							      \
    } while (Val > 0);							      \
    while (__len-- > 0 && __cp < __buf + sizeof (__buf))		      \
      *__dest++ = *__cp++;						      \
    memcpy (__dest, " clock cycles", MIN (__len, sizeof (" clock cycles")));  \
  } while (0)

#else /* !__i686__ */

/* Provide dummy definitions.  */
#define HP_TIMING_AVAIL         (0)
#define HP_TIMING_INLINE        (0)
typedef int hp_timing_t;
#define HP_TIMING_ZERO(Var)
#define HP_TIMING_NOW(var)
#define HP_TIMING_DIFF_INIT()
#define HP_TIMING_DIFF(Diff, Start, End)
#define HP_TIMING_ACCUM(Sum, Diff)
#define HP_TIMING_ACCUM_NT(Sum, Diff)
#define HP_TIMING_PRINT(Buf, Len, Val)

/* Since this implementation is not available we tell the user about it.  */
#define HP_TIMING_NONAVAIL      1

#endif

#endif	/* hp-timing.h */

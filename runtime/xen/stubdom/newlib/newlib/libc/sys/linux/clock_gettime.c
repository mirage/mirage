/* Copyright (C) 1999, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

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

#include <errno.h>
#include <stdint.h>
#include <time.h>
#include <sys/time.h>
#include <libc-internal.h>
#include <hp-timing.h>


#if HP_TIMING_AVAIL
/* Clock frequency of the processor.  We make it a 64-bit variable
   because some jokers are already playing with processors with more
   than 4GHz.  */
static hp_timing_t freq;


/* We need the starting time for the process.  */
extern hp_timing_t _dl_cpuclock_offset;


/* This function is defined in the thread library.  */
extern int __pthread_clock_gettime (hp_timing_t freq, struct timespec *tp)
     __attribute__ ((__weak__));
#endif


/* Get current value of CLOCK and store it in TP.  */
int
clock_gettime (clockid_t clock_id, struct timespec *tp)
{
  struct timeval tv;
  int retval = -1;

  switch (clock_id)
    {
    case CLOCK_REALTIME:
      retval = gettimeofday (&tv, NULL);
      if (retval == 0)
	/* Convert into `timespec'.  */
	TIMEVAL_TO_TIMESPEC (&tv, tp);
      break;

#if HP_TIMING_AVAIL
    case CLOCK_PROCESS_CPUTIME_ID:
    case CLOCK_THREAD_CPUTIME_ID:
      {
	hp_timing_t tsc;

	if (__builtin_expect (freq == 0, 0))
	  {
	    /* This can only happen if we haven't initialized the `freq'
	       variable yet.  Do this now. We don't have to protect this
	       code against multiple execution since all of them should
	       lead to the same result.  */
	    freq = __get_clockfreq ();
	    if (__builtin_expect (freq == 0, 0))
	      /* Something went wrong.  */
	      break;
	  }

	if (clock_id == CLOCK_THREAD_CPUTIME_ID
	    && __pthread_clock_gettime != NULL)
	  {
	    retval = __pthread_clock_gettime (freq, tp);
	    break;
	  }

	/* Get the current counter.  */
	HP_TIMING_NOW (tsc);

	/* Compute the offset since the start time of the process.  */
	tsc -= _dl_cpuclock_offset;

	/* Compute the seconds.  */
	tp->tv_sec = tsc / freq;

	/* And the nanoseconds.  This computation should be stable until
	   we get machines with about 16GHz frequency.  */
	tp->tv_nsec = ((tsc % freq) * UINT64_C (1000000000)) / freq;

	retval = 0;
      }
    break;
#endif

    default:
      __set_errno (EINVAL);
      break;
    }

  return retval;
}

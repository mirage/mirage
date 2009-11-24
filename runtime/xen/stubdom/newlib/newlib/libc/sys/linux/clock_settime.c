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
#include <time.h>
#include <sys/time.h>
#include <libc-internal.h>


#if HP_TIMING_AVAIL
/* Clock frequency of the processor.  We make it a 64-bit variable
   because some jokers are already playing with processors with more
   than 4GHz.  */
static hp_timing_t freq;


/* We need the starting time for the process.  */
extern hp_timing_t _dl_cpuclock_offset;


/* This function is defined in the thread library.  */
extern void __pthread_clock_settime (hp_timing_t offset)
     __attribute__ ((__weak__));
#endif


/* Set CLOCK to value TP.  */
int
clock_settime (clockid_t clock_id, const struct timespec *tp)
{
  struct timeval tv;
  int retval;

  /* Make sure the time cvalue is OK.  */
  if (tp->tv_nsec < 0 || tp->tv_nsec >= 1000000000)
    {
      __set_errno (EINVAL);
      return -1;
    }

  switch (clock_id)
    {
    case CLOCK_REALTIME:
      TIMESPEC_TO_TIMEVAL (&tv, tp);

      retval = settimeofday (&tv, NULL);
      break;

#if HP_TIMING_AVAIL
    case CLOCK_PROCESS_CPUTIME_ID:
    case CLOCK_THREAD_CPUTIME_ID:
      {
	hp_timing_t tsc;
	hp_timing_t usertime;

	/* First thing is to get the current time.  */
	HP_TIMING_NOW (tsc);

	if (__builtin_expect (freq == 0, 0))
	  {
	    /* This can only happen if we haven't initialized the `freq'
	       variable yet.  Do this now. We don't have to protect this
	       code against multiple execution since all of them should
	       lead to the same result.  */
	    freq = __get_clockfreq ();
	    if (__builtin_expect (freq == 0, 0))
	      {
		/* Something went wrong.  */
		retval = -1;
		break;
	      }
	  }

	/* Convert the user-provided time into CPU ticks.  */
	usertime = tp->tv_sec * freq + (tp->tv_nsec * freq) / 1000000000ull;

	/* Determine the offset and use it as the new base value.  */
	if (clock_id != CLOCK_THREAD_CPUTIME_ID
	    || __pthread_clock_settime == NULL)
	  _dl_cpuclock_offset = tsc - usertime;
	else
	  __pthread_clock_settime (tsc - usertime);

	retval = 0;
      }
      break;
#endif

    default:
      __set_errno (EINVAL);
      retval = -1;
      break;
    }

  return retval;
}

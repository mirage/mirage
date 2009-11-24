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
#include <unistd.h>
#include <sys/param.h>
#include <libc-internal.h>


#if HP_TIMING_AVAIL
/* Clock frequency of the processor.  */
static long int nsec;
#endif


/* Get resolution of clock.  */
int
clock_getres (clockid_t clock_id, struct timespec *res)
{
  int retval = -1;

  switch (clock_id)
    {
    case CLOCK_REALTIME:
      {
	long int clk_tck = sysconf (_SC_CLK_TCK);

	if (__builtin_expect (clk_tck != -1, 1))
	  {
	    /* This implementation assumes that the realtime clock has a
	       resolution higher than 1 second.  This is the case for any
	       reasonable implementation.  */
	    res->tv_sec = 0;
	    res->tv_nsec = 1000000000 / clk_tck;

	    retval = 0;
	  }
      }
      break;

#if HP_TIMING_AVAIL
    case CLOCK_PROCESS_CPUTIME_ID:
    case CLOCK_THREAD_CPUTIME_ID:
      {
	if (__builtin_expect (nsec == 0, 0))
	  {
	    hp_timing_t freq;

	    /* This can only happen if we haven't initialized the `freq'
	       variable yet.  Do this now. We don't have to protect this
	       code against multiple execution since all of them should
	       lead to the same result.  */
	    freq = __get_clockfreq ();
	    if (__builtin_expect (freq == 0, 0))
	      /* Something went wrong.  */
	      break;

	    nsec = MAX (UINT64_C (1000000000) / freq, 1);
	  }

	/* File in the values.  The seconds are always zero (unless we
	   have a 1Hz machine).  */
	res->tv_sec = 0;
	res->tv_nsec = nsec;

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

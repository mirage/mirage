/* Copyright (C) 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with the GNU C Library; see the file COPYING.LIB.  If not,
   write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

#include <time.h>
#include <libc-internal.h>
#include "internals.h"


#if HP_TIMING_AVAIL
int
__pthread_clock_gettime (hp_timing_t freq, struct timespec *tp)
{
  hp_timing_t tsc;
  pthread_descr self = thread_self ();

  /* Get the current counter.  */
  HP_TIMING_NOW (tsc);

  /* Compute the offset since the start time of the process.  */
  tsc -= THREAD_GETMEM (self, p_cpuclock_offset);

  /* Compute the seconds.  */
  tp->tv_sec = tsc / freq;

  /* And the nanoseconds.  This computation should be stable until
     we get machines with about 16GHz frequency.  */
  tp->tv_nsec = ((tsc % freq) * 1000000000ull) / freq;

  return 0;
}
#endif

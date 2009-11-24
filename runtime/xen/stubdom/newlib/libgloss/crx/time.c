/* time.c -- Implementation of the low-level time() routine
 *
 * Copyright (c) 2004 National Semiconductor Corporation
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

#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <sys/time.h>
#include <sys/times.h>
#include <sys/syscall.h>

time_t _Time (time_t *timer)
{
  HOST_SERVICE (SVC_TIME);
}

time_t time (time_t *tod)
{
  time_t t = _Time (NULL);

  if (tod)
    *tod = t;
  
  return (t);
}

/* _times -- no clock, so return an error.  */
clock_t times (struct tms *buf)
{
  errno = EINVAL;
  return (-1);
}

/* _gettimeofday -- implement in terms of time.  */
int gettimeofday (struct timeval *tv, void *tzvp)
{
  struct timezone *tz = tzvp;
  if (tz)
    tz->tz_minuteswest = tz->tz_dsttime = 0;

  tv->tv_usec = 0;
  tv->tv_sec = time (0);
  return 0;
}


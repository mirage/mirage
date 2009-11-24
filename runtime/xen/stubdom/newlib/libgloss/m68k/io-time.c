/*
 * io-time.c -- 
 *
 * Copyright (c) 2006 CodeSourcery Inc
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

#include <sys/time.h>
#include <errno.h>
#define IO time
#include "io.h"

/*
 * time -- get the current time
 * input parameters:
 *   0 : timeval ptr
 * output parameters:
 *   0 : result
 *   1 : errno
 */

time_t time (time_t *t)
{
#if HOSTED
  struct timeval tv;

  if (gettimeofday (&tv, NULL))
    return -1;
  if (t)
    *t = tv.tv_sec;
  return tv.tv_sec;
#else
  errno = ENOSYS;
  return -1;
#endif
}

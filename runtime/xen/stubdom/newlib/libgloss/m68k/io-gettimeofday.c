/*
 * io-gettimeofday.c -- 
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
#define IO gettimeofday
#include "io.h"

/*
 * gettimeofday -- get the current time
 * input parameters:
 *   0 : timeval ptr
 * output parameters:
 *   0 : result
 *   1 : errno
 */

int gettimeofday (struct timeval *tv, void *tzvp)
{
#if HOSTED
  gdb_parambuf_t parameters;
  struct gdb_timeval gtv;
  struct timezone *tz = tzvp;
  if (!tv)
    return 0;
  if (tz)
    {
      errno = EINVAL;
      return -1;
    }
  parameters[0] = (uint32_t) &gtv;
  __hosted (HOSTED_GETTIMEOFDAY, parameters);
  __hosted_from_gdb_timeval (&gtv, tv);
  errno = __hosted_from_gdb_errno (parameters[1]);
  return parameters[0];
#else
  errno = ENOSYS;
  return -1;
#endif
}

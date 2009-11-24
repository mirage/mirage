/*
 * io-fstat.c -- 
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

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#define IO fstat
#include "io.h"

/*
 * fstat -- get file information
 * input parameters:
 *   0 : file descriptor
 *   1 : stat buf ptr
 * output parameters:
 *   0 : result
 *   1 : errno
 */

int fstat (int fd, struct stat *buf)
{
#if HOSTED
  gdb_parambuf_t parameters;
  struct gdb_stat gbuf;
  parameters[0] = (uint32_t) fd;
  parameters[1] = (uint32_t) &gbuf;
  __hosted (HOSTED_FSTAT, parameters);
  __hosted_from_gdb_stat (&gbuf, buf);
  errno = __hosted_from_gdb_errno (parameters[1]);
  return parameters[0];
#else
  errno = ENOSYS;
  return -1;
#endif
}

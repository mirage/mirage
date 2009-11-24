/*
 * io-close.c -- 
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

#include <unistd.h>
#include <errno.h>
#define IO close
#include "io.h"

/*
 * close -- close a file descriptor.
 * input parameters:
 *   0 : file descriptor
 * output parameters:
 *   0 : result
 *   1 : errno
 */

int close (int fd)
{
#if HOSTED
  gdb_parambuf_t parameters;
  parameters[0] = (uint32_t) fd;
  __hosted (HOSTED_CLOSE, parameters);
  errno = __hosted_from_gdb_errno (parameters[1]);
  return parameters[0];
#else
  return 0;
#endif
}

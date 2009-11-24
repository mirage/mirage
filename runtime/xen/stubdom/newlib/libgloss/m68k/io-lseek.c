/*
 * io-lseek.c -- 
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
#include <unistd.h>
#include <errno.h>
#define IO lseek
#include "io.h"

/*
 * lseek -- reposition a file descriptor
 * input parameters:
 *   0 : file descriptor
 *   1 : high word of offset
 *   2 : low word of offset
 *   3 : seek flag
 * output parameters:
 *   0 : high word of result
 *   1 : low word of result
 *   2 : errno
 */

off_t lseek (int fd, off_t offset, int whence)
{
#if HOSTED
  gdb_parambuf_t parameters;
  parameters[0] = (uint32_t) fd;
  parameters[1] = (uint32_t) ((offset >> 32) & 0xffffffff);
  parameters[2] = (uint32_t) (offset & 0xffffffff);
  parameters[3] = __hosted_to_gdb_lseek_flags (whence);
  __hosted (HOSTED_LSEEK, parameters);
  errno = __hosted_from_gdb_errno (parameters[2]);
  return ((uint64_t)parameters[0] << 32) | ((uint64_t)parameters[1]);
#else
  errno = ENOSYS;
  return -1;
#endif
}

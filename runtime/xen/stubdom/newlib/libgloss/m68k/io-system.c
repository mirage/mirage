/*
 * io-system.c -- 
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

#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/wait.h>
#define IO _system
#include "io.h"

/*
 * system: execute command on (remote) host
 * input parameters:
 *   0 : command ptr
 *   1 : command length
 * output parameters:
 *   0 : result
 *   1 : errno
 */

int _system (const char *command)
{
#if HOSTED
  int e;
  gdb_parambuf_t parameters;
  
  parameters[0] = (uint32_t) command;
  parameters[1] = command ? (uint32_t) strlen (command) + 1 : 0;
  __hosted (HOSTED_SYSTEM, parameters);
  errno = __hosted_from_gdb_errno (parameters[1]);
  e = parameters[0];
  if (e >= 0 && command)
    {
      /* We have to convert e, an exit status to the encoded status of
	 the command.  To avoid hard coding the exit status, we simply
	 loop until we find the right position.  */
      int exit_code;

      for (exit_code = e; e && WEXITSTATUS (e) != exit_code; e <<= 1)
	continue;
    }
  
  return e;
#else
  if (!command)
    return 0;
  errno = ENOSYS;
  return -1;
#endif
}

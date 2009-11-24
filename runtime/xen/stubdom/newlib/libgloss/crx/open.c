/* open.c -- Implementation of the low-level open() routine
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

#include <sys/syscall.h>
#include <stdarg.h>

int open_aux (char *, int, int);

/* The prototype in <fcntl.h> for open() uses ..., meaning function 
 * parameters reside on stack, but the debugger expects the parameters 
 * to reside in registers, thus we call an auxiliary function with 
 * bounded number of parameters.
 */
int open (char *path, int flags, ...)
{
  int mode;
  va_list ap;
  
  va_start(ap, flags);
  mode = va_arg(ap, int);
  open_aux (path, flags, mode);
  va_end(ap);
}

int open_aux (char *path, int flags, int mode)
{
  HOST_SERVICE (SVC_OPEN);
}


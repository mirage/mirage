/* _getenv.c -- Implementation of the low-level _getenv() routine
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
#include <stdlib.h>

register char *R2 __asm__("r2");
register char *R3 __asm__("r3");

char * _getenv (const char *name)
{
  char *x;
  char *y;

  x  = R2;

  y  = (char *) calloc (256, 1);
  R3 = y;

  R2 = x;
 
  HOST_SERVICE (SVC_GETENV);
}


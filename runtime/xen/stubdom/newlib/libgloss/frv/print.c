/* print.c -- print a string on the output device.
 *
 * Copyright (c) 2002 Red Hat, Inc
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
#include "glue.h"

/*
 * print -- do a raw print of a string
 */ 
void
_DEFUN (_print, (ptr),
char *ptr)
{
  while (*ptr) {
    outbyte (*ptr++);
  }
}

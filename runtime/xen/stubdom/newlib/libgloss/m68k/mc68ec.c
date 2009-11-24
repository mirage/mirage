/* mc68ec.c -- Low level support for the Motorola mc68ec0x0 board.
 *             Written by rob@cygnus.com (Rob Savoye)
 *
 * Copyright (c) 1995 Cygnus Support
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
#include <_ansi.h>
#include <errno.h>
#include "leds.h"

/*
 * _exit -- exit the running program. We just cause an exception
 *          which makes the program return to the boot monitor
 *          prompt. It can be restarted from there.
 */
void
_DEFUN (_exit, (status),
	int_status)
{
  /* Use `i' constraint to get proper immediate-operand syntax for
     target assembler configuration.  */
  asm ("trap %0" : : "i" (0));	/* seems to be a harmless vector number */
}

/*
 * delay -- delay execution. This is an ugly hack. It should
 *          use the timer, but I'm waiting for docs. (sigh)
 */
void
_DEFUN (delay, (num),
        int num)
{
  while (num--)
    {
      asm ("nop");
    }
}

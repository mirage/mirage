/* cmb-exit.c -- exit trap binding.
 *
 * Copyright (c) 1999 Cygnus Support
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
#include <_ansi.h>

/*
 * _exit --  Just cause a breakpoint so user can see why we exited.
 */
void
_DEFUN (_exit, (val),
       int val)
{
    while (1) {
	asm("bkpt");
    }
}

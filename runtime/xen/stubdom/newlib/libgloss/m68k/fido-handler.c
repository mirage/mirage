/*
 * Copyright (c) 2006 CodeSourcery, Inc.
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

__attribute__((interrupt_handler)) void
HANDLER()
{
  /* Load the status register into %d0 and the program counter at
     which the interrupt occured into %d1 for ease of inspection in
     the debugger.  */
  asm("move.l %sp @(0),%d0\n\t"
      "move.l %sp @(-4),%d1\n\t"
      "sleep");
}

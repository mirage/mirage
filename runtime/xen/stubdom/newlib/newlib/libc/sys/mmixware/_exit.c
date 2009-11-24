/* _exit for MMIXware.

   Copyright (C) 2001 Hans-Peter Nilsson

   Permission to use, copy, modify, and distribute this software is
   freely granted, provided that the above copyright notice, this notice
   and the following disclaimer are preserved with no changes.

   THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE.  */

#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "sys/syscall.h"

void _exit (int n)
{
  /* The return status is passed on at exit from the simulator by all
     but the oldest versions of Knuth's mmixware simulator.  Beware,
     "TRAP 0,0,0" is the instruction corresponding to (int32_t) 0 and
     the value 0 in $255 is common enough that a program crash jumping
     to e.g. uninitialized memory will look like "exit (0)".  */
  __asm__ ("SET $255,%0\n\tTRAP 0,0,0"
	   : /* No outputs.  */
	   : "r" (n)
	   : "memory");
}

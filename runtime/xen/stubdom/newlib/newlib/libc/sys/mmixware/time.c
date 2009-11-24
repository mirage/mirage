/* time stub for MMIXware.

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

time_t
time (time_t *tloc)
{
  /* Nowhere to get time reasonably from; neither of rC, rI and rU seems
     usable without assuming some scaling of mems and oops to real time.  */
  time_t thetime = 0;

  if (tloc)
    *tloc = thetime;

  return thetime;
}

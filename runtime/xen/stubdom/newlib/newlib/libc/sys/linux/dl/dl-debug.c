/* Communicate dynamic linker state to the debugger at runtime.
   Copyright (C) 1996, 1998, 2000 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

#include <ldsodefs.h>

/* This structure communicates dl state to the debugger.  The debugger
   normally finds it via the DT_DEBUG entry in the dynamic section, but in
   a statically-linked program there is no dynamic section for the debugger
   to examine and it looks for this particular symbol name.  */
struct r_debug _r_debug;


/* Initialize _r_debug if it has not already been done.  The argument is
   the run-time load address of the dynamic linker, to be put in
   _r_debug.r_ldbase.  Returns the address of _r_debug.  */

struct r_debug *
internal_function
_dl_debug_initialize (ElfW(Addr) ldbase)
{
  if (_r_debug.r_brk == 0)
    {
      /* Tell the debugger where to find the map of loaded objects.  */
      _r_debug.r_version = 1	/* R_DEBUG_VERSION XXX */;
      _r_debug.r_ldbase = ldbase;
      _r_debug.r_map = _dl_loaded;
      _r_debug.r_brk = (ElfW(Addr)) &_dl_debug_state;
    }

  return &_r_debug;
}


/* This function exists solely to have a breakpoint set on it by the
   debugger.  The debugger is supposed to find this function's address by
   examining the r_brk member of struct r_debug, but GDB 4.15 in fact looks
   for this particular symbol name in the PT_INTERP file.  */
void
_dl_debug_state (void)
{
}

/* Helper definitions for profiling of shared libraries.
   Copyright (C) 1998, 2000 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@cygnus.com>, 1997.

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

#include <dlfcn.h>
#include <elf.h>
#include <ldsodefs.h>
#include <libc-symbols.h>

/* This is the map for the shared object we profile.  It is defined here
   only because we test for this value being NULL or not.  */
extern struct link_map *_dl_profile_map;


void
_dl_mcount_wrapper (void *selfpc)
{
  _dl_mcount ((ElfW(Addr)) RETURN_ADDRESS (0), (ElfW(Addr)) selfpc);
}


void
_dl_mcount_wrapper_check (void *selfpc)
{
  if (_dl_profile_map != NULL)
    _dl_mcount ((ElfW(Addr)) RETURN_ADDRESS (0), (ElfW(Addr)) selfpc);
}

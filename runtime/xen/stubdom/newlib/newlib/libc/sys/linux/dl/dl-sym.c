/* Look up a symbol in a shared object loaded by `dlopen'.
   Copyright (C) 1999, 2000, 2001 Free Software Foundation, Inc.
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

#include <stddef.h>
#include <setjmp.h>
#include <libintl.h>

#include <dlfcn.h>
#include <ldsodefs.h>
#include <dl-hash.h>

void *
internal_function
_dl_sym (void *handle, const char *name, void *who)
{
  const ElfW(Sym) *ref = NULL;
  lookup_t result;
  ElfW(Addr) caller = (ElfW(Addr)) who;
  struct link_map *match;
  struct link_map *l;

  /* If the address is not recognized the call comes from the main
     program (we hope).  */
  match = _dl_loaded;

  /* Find the highest-addressed object that CALLER is not below.  */
  for (l = _dl_loaded; l != NULL; l = l->l_next)
    if (caller >= l->l_map_start && caller < l->l_map_end)
      {
	/* There must be exactly one DSO for the range of the virtual
	   memory.  Otherwise something is really broken.  */
	match = l;
	break;
      }

  if (handle == RTLD_DEFAULT)
    /* Search the global scope as seen in the caller object.  */
    result = _dl_lookup_symbol (name, match, &ref, match->l_scope, 0, 0);
  else
    {
      if (handle != RTLD_NEXT)
	{
	  /* Search the scope of the given object.  */
	  struct link_map *map = handle;

	  result = _dl_lookup_symbol (name, match, &ref, map->l_local_scope,
				      0, 1);
	}
      else
	{
	  if (__builtin_expect (match == _dl_loaded, 0))
	    {
	      if (! _dl_loaded
		  || caller < _dl_loaded->l_map_start
		  || caller >= _dl_loaded->l_map_end)
	        _dl_signal_error (0, NULL, NULL, N_("\
RTLD_NEXT used in code not dynamically loaded"));
	    }

	  l = match;
	  while (l->l_loader != NULL)
	    l = l->l_loader;

	  result = _dl_lookup_symbol_skip (name, l, &ref, l->l_local_scope,
					   match);
	}
    }

  if (ref != NULL)
    return DL_SYMBOL_ADDRESS (result, ref);

  return NULL;
}

void *
internal_function
_dl_vsym (void *handle, const char *name, const char *version, void *who)
{
  const ElfW(Sym) *ref = NULL;
  struct r_found_version vers;
  lookup_t result;
  ElfW(Addr) caller = (ElfW(Addr)) who;
  struct link_map *match;
  struct link_map *l;

  /* Compute hash value to the version string.  */
  vers.name = version;
  vers.hidden = 1;
  vers.hash = _dl_elf_hash (version);
  /* We don't have a specific file where the symbol can be found.  */
  vers.filename = NULL;

  /* If the address is not recognized the call comes from the main
     program (we hope).  */
  match = _dl_loaded;

  /* Find the highest-addressed object that CALLER is not below.  */
  for (l = _dl_loaded; l != NULL; l = l->l_next)
    if (caller >= l->l_map_start && caller < l->l_map_end)
      {
	/* There must be exactly one DSO for the range of the virtual
	   memory.  Otherwise something is really broken.  */
	match = l;
	break;
      }

  if (handle == RTLD_DEFAULT)
    /* Search the global scope.  */
    result = _dl_lookup_versioned_symbol (name, match, &ref, match->l_scope,
					  &vers, 0, 0);
  else if (handle == RTLD_NEXT)
    {
      if (__builtin_expect (match == _dl_loaded, 0))
	{
	  if (! _dl_loaded
	      || caller < _dl_loaded->l_map_start
	      || caller >= _dl_loaded->l_map_end)
	    _dl_signal_error (0, NULL, NULL, N_("\
RTLD_NEXT used in code not dynamically loaded"));
	}

      l = match;
      while (l->l_loader != NULL)
	l = l->l_loader;

      result = _dl_lookup_versioned_symbol_skip (name, l, &ref,
						 l->l_local_scope,
						 &vers, match);
    }
  else
    {
      /* Search the scope of the given object.  */
      struct link_map *map = handle;
      result = _dl_lookup_versioned_symbol (name, map, &ref,
					    map->l_local_scope, &vers, 0, 1);
    }

  if (ref != NULL)
    return DL_SYMBOL_ADDRESS (result, ref);

  return NULL;
}

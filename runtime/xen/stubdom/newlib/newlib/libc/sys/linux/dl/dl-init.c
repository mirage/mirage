/* Return the next shared object initializer function not yet run.
   Copyright (C) 1995,1996,1998,1999,2000,2001 Free Software Foundation, Inc.
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
#include <ldsodefs.h>


/* Type of the initializer.  */
typedef void (*init_t) (int, char **, char **);

/* Flag, nonzero during startup phase.  */
extern int _dl_starting_up;

/* The object to be initialized first.  */
extern struct link_map *_dl_initfirst;


static void
call_init (struct link_map *l, int argc, char **argv, char **env)
{
  if (l->l_init_called)
    /* This object is all done.  */
    return;

  /* Avoid handling this constructor again in case we have a circular
     dependency.  */
  l->l_init_called = 1;

  /* Check for object which constructors we do not run here.  */
  if (__builtin_expect (l->l_name[0], 'a') == '\0'
      && l->l_type == lt_executable)
    return;

  /* Are there any constructors?  */
  if (l->l_info[DT_INIT] == NULL
      && __builtin_expect (l->l_info[DT_INIT_ARRAY] == NULL, 1))
    return;

  /* Print a debug message if wanted.  */
  if (__builtin_expect (_dl_debug_mask & DL_DEBUG_IMPCALLS, 0))
    _dl_debug_printf ("\ncalling init: %s\n\n",
		      l->l_name[0] ? l->l_name : _dl_argv[0]);

  /* Now run the local constructors.  There are two forms of them:
     - the one named by DT_INIT
     - the others in the DT_INIT_ARRAY.
  */
  if (l->l_info[DT_INIT] != NULL)
    {
      init_t init = (init_t) DL_DT_INIT_ADDRESS
	(l, l->l_addr + l->l_info[DT_INIT]->d_un.d_ptr);

      /* Call the function.  */
      init (argc, argv, env);
    }

  /* Next see whether there is an array with initialization functions.  */
  if (l->l_info[DT_INIT_ARRAY] != NULL)
    {
      unsigned int j;
      unsigned int jm;
      ElfW(Addr) *addrs;

      jm = l->l_info[DT_INIT_ARRAYSZ]->d_un.d_val / sizeof (ElfW(Addr));

      addrs = (ElfW(Addr) *) (l->l_info[DT_INIT_ARRAY]->d_un.d_ptr
			      + l->l_addr);
      for (j = 0; j < jm; ++j)
	((init_t) addrs[j]) (argc, argv, env);
    }
}


void
internal_function
_dl_init (struct link_map *main_map, int argc, char **argv, char **env)
{
  ElfW(Dyn) *preinit_array = main_map->l_info[DT_PREINIT_ARRAY];
  struct r_debug *r;
  unsigned int i;

  if (__builtin_expect (_dl_initfirst != NULL, 0))
    {
      call_init (_dl_initfirst, argc, argv, env);
      _dl_initfirst = NULL;
    }

  /* Don't do anything if there is no preinit array.  */
  if (__builtin_expect (preinit_array != NULL, 0)
      && (i = preinit_array->d_un.d_val / sizeof (ElfW(Addr))) > 0)
    {
      ElfW(Addr) *addrs;
      unsigned int cnt;

      if (__builtin_expect (_dl_debug_mask & DL_DEBUG_IMPCALLS, 0))
	_dl_debug_printf ("\ncalling preinit: %s\n\n",
			  main_map->l_name[0]
			  ? main_map->l_name : _dl_argv[0]);

      addrs = (ElfW(Addr) *) (main_map->l_info[DT_PREINIT_ARRAY]->d_un.d_ptr
			      + main_map->l_addr);
      for (cnt = 0; cnt < i; ++cnt)
	((init_t) addrs[cnt]) (argc, argv, env);
    }

  /* Notify the debugger we have added some objects.  We need to call
     _dl_debug_initialize in a static program in case dynamic linking has
     not been used before.  */
  r = _dl_debug_initialize (0);
  r->r_state = RT_ADD;
  _dl_debug_state ();

  /* Stupid users forced the ELF specification to be changed.  It now
     says that the dynamic loader is responsible for determining the
     order in which the constructors have to run.  The constructors
     for all dependencies of an object must run before the constructor
     for the object itself.  Circular dependencies are left unspecified.

     This is highly questionable since it puts the burden on the dynamic
     loader which has to find the dependencies at runtime instead of
     letting the user do it right.  Stupidity rules!  */

  i = main_map->l_searchlist.r_nlist;
  while (i-- > 0)
    call_init (main_map->l_initfini[i], argc, argv, env);

  /* Notify the debugger all new objects are now ready to go.  */
  r->r_state = RT_CONSISTENT;
  _dl_debug_state ();

  /* Finished starting up.  */
  _dl_starting_up = 0;
}

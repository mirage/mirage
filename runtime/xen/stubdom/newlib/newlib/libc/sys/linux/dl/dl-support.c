/* Support for dynamic linking code in static libc.
   Copyright (C) 1996, 97, 98, 99, 2000, 2001 Free Software Foundation, Inc.
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

/* This file defines some things that for the dynamic linker are defined in
   rtld.c and dl-sysdep.c in ways appropriate to bootstrap dynamic linking.  */

#include <errno.h>
#include <libintl.h>
#include <stdlib.h>
#include <unistd.h>
#include <dirent.h>
#include <pthread.h>
#include <ldsodefs.h>
#include <machine/dl-machine.h>
#include <dl-librecon.h>
#include <unsecvars.h>
#include <machine/hp-timing.h>

char *__progname = "newlib";
char **_dl_argv = &__progname;	/* This is checked for some error messages.  */

/* Name of the architecture.  */
const char *_dl_platform;
size_t _dl_platformlen;

int _dl_debug_mask;
int _dl_lazy;
/* XXX I know about at least one case where we depend on the old weak
   behavior (it has to do with librt).  Until we get DSO groups implemented
   we have to make this the default.  Bummer. --drepper  */
#if 0
int _dl_dynamic_weak;
#else
int _dl_dynamic_weak = 1;
#endif

/* If nonzero print warnings about problematic situations.  */
int _dl_verbose;

/* Structure to store information about search paths.  */
struct r_search_path *_dl_search_paths;

/* We never do profiling.  */
const char *_dl_profile;

/* Names of shared object for which the RUNPATHs and RPATHs should be
   ignored.  */
const char *_dl_inhibit_rpath;

/* The map for the object we will profile.  */
struct link_map *_dl_profile_map;

/* This is the address of the last stack address ever used.  */
void *__libc_stack_end;

/* Path where the binary is found.  */
const char *_dl_origin_path;

/* Nonzero if runtime lookup should not update the .got/.plt.  */
int _dl_bind_not;

/* Initially empty list of loaded objects.  */
struct link_map *_dl_loaded;
/* Number of object in the _dl_loaded list.  */
unsigned int _dl_nloaded;

/* Fake scope.  In dynamically linked binaries this is the scope of the
   main application but here we don't have something like this.  So
   create a fake scope containing nothing.  */
struct r_scope_elem _dl_initial_searchlist;
/* Variable which can be used in lookup to process the global scope.  */
struct r_scope_elem *_dl_global_scope[2] = { &_dl_initial_searchlist, NULL };
/* This is a global pointer to this structure which is public.  It is
   used by dlopen/dlclose to add and remove objects from what is regarded
   to be the global scope.  */
struct r_scope_elem *_dl_main_searchlist = &_dl_initial_searchlist;

/* Nonzero during startup.  */
int _dl_starting_up = 1;

/* We expect less than a second for relocation.  */
#ifdef HP_SMALL_TIMING_AVAIL
# undef HP_TIMING_AVAIL
# define HP_TIMING_AVAIL HP_SMALL_TIMING_AVAIL
#endif

/* Initial value of the CPU clock.  */
#ifndef HP_TIMING_NONAVAIL
hp_timing_t _dl_cpuclock_offset;
#endif

/* During the program run we must not modify the global data of
   loaded shared object simultanously in two threads.  Therefore we
   protect `_dl_open' and `_dl_close' in dl-close.c.

   This must be a recursive lock since the initializer function of
   the loaded object might as well require a call to this function.
   At this time it is not anymore a problem to modify the tables.  */
__LOCK_INIT_RECURSIVE(, _dl_load_lock)


#ifdef HAVE_AUX_VECTOR
extern int _dl_clktck;

void
internal_function
_dl_aux_init (ElfW(auxv_t) *av)
{
  for (; av->a_type != AT_NULL; ++av)
    switch (av->a_type)
      {
      case AT_PAGESZ:
	_dl_pagesize = av->a_un.a_val;
	break;
      case AT_CLKTCK:
	_dl_clktck = av->a_un.a_val;
	break;
      }
}
#endif

void non_dynamic_init (void) __attribute__ ((unused));

void
non_dynamic_init (void)
{
  if (HP_TIMING_AVAIL)
    HP_TIMING_NOW (_dl_cpuclock_offset);

  if (!_dl_pagesize)
    _dl_pagesize = __getpagesize ();

  _dl_verbose = *(getenv ("LD_WARN") ?: "") == '\0' ? 0 : 1;

  /* Initialize the data structures for the search paths for shared
     objects.  */
  _dl_init_paths (getenv ("LD_LIBRARY_PATH"));

  _dl_lazy = *(getenv ("LD_BIND_NOW") ?: "") == '\0';

  _dl_bind_not = *(getenv ("LD_BIND_NOT") ?: "") != '\0';

  _dl_dynamic_weak = *(getenv ("LD_DYNAMIC_WEAK") ?: "") == '\0';

#ifdef DL_PLATFORM_INIT
  DL_PLATFORM_INIT;
#endif

  /* Now determine the length of the platform string.  */
  if (_dl_platform != NULL)
    _dl_platformlen = strlen (_dl_platform);
}
text_set_element (__libc_subinit, non_dynamic_init);

const struct r_strlenpair *
internal_function
_dl_important_hwcaps (const char *platform, size_t platform_len, size_t *sz,
		      size_t *max_capstrlen)
{
  static struct r_strlenpair result;
  static char buf[1];

  result.str = buf;	/* Does not really matter.  */
  result.len = 0;

  *sz = 1;
  return &result;
}

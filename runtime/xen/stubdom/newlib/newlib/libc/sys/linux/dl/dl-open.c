/* Load a shared object at runtime, relocate it, and run its initializer.
   Copyright (C) 1996,1997,1998,1999,2000,2001 Free Software Foundation, Inc.
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

#include <assert.h>
#include <dlfcn.h>
#include <errno.h>
#include <libintl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>		/* Check whether MAP_COPY is defined.  */
#include <sys/param.h>
#include <ldsodefs.h>
#include <bp-sym.h>

#include <dl-dst.h>
#include <machine/weakalias.h>


extern ElfW(Addr) _dl_sysdep_start (void **start_argptr,
				    void (*dl_main) (const ElfW(Phdr) *phdr,
						     ElfW(Word) phnum,
						     ElfW(Addr) *user_entry))
				   weak_function;

/* This function is used to unload the cache file if necessary.  */
extern void _dl_unload_cache (void);

int __libc_argc = 0;
char **__libc_argv = NULL;

extern char **environ;

extern int _dl_lazy;			/* Do we do lazy relocations?  */

/* Undefine the following for debugging.  */
/* #define SCOPE_DEBUG 1 */
#ifdef SCOPE_DEBUG
static void show_scope (struct link_map *new);
#endif

extern size_t _dl_platformlen;

/* We must be carefull not to leave us in an inconsistent state.  Thus we
   catch any error and re-raise it after cleaning up.  */

struct dl_open_args
{
  const char *file;
  int mode;
  const void *caller;
  struct link_map *map;
};


static int
add_to_global (struct link_map *new)
{
  struct link_map **new_global;
  unsigned int to_add = 0;
  unsigned int cnt;

  /* Count the objects we have to put in the global scope.  */
  for (cnt = 0; cnt < new->l_searchlist.r_nlist; ++cnt)
    if (new->l_searchlist.r_list[cnt]->l_global == 0)
      ++to_add;

  /* The symbols of the new objects and its dependencies are to be
     introduced into the global scope that will be used to resolve
     references from other dynamically-loaded objects.

     The global scope is the searchlist in the main link map.  We
     extend this list if necessary.  There is one problem though:
     since this structure was allocated very early (before the libc
     is loaded) the memory it uses is allocated by the malloc()-stub
     in the ld.so.  When we come here these functions are not used
     anymore.  Instead the malloc() implementation of the libc is
     used.  But this means the block from the main map cannot be used
     in an realloc() call.  Therefore we allocate a completely new
     array the first time we have to add something to the locale scope.  */

  if (_dl_global_scope_alloc == 0)
    {
      /* This is the first dynamic object given global scope.  */
      _dl_global_scope_alloc = _dl_main_searchlist->r_nlist + to_add + 8;
      new_global = (struct link_map **)
	malloc (_dl_global_scope_alloc * sizeof (struct link_map *));
      if (new_global == NULL)
	{
	  _dl_global_scope_alloc = 0;
	nomem:
	  _dl_signal_error (ENOMEM, new->l_libname->name, NULL,
			    N_("cannot extend global scope"));
	  return 1;
	}

      /* Copy over the old entries.  */
      memcpy (new_global, _dl_main_searchlist->r_list,
	      (_dl_main_searchlist->r_nlist * sizeof (struct link_map *)));

      _dl_main_searchlist->r_list = new_global;
    }
  else if (_dl_main_searchlist->r_nlist + to_add > _dl_global_scope_alloc)
    {
      /* We have to extend the existing array of link maps in the
	 main map.  */
      new_global = (struct link_map **)
	realloc (_dl_main_searchlist->r_list,
		 ((_dl_global_scope_alloc + to_add + 8)
		  * sizeof (struct link_map *)));
      if (new_global == NULL)
	goto nomem;

      _dl_global_scope_alloc += to_add + 8;
      _dl_main_searchlist->r_list = new_global;
    }

  /* Now add the new entries.  */
  for (cnt = 0; cnt < new->l_searchlist.r_nlist; ++cnt)
    {
      struct link_map *map = new->l_searchlist.r_list[cnt];

      if (map->l_global == 0)
	{
	  map->l_global = 1;
	  _dl_main_searchlist->r_list[_dl_main_searchlist->r_nlist] = map;
	  ++_dl_main_searchlist->r_nlist;
	}
    }

  return 0;
}


static void
dl_open_worker (void *a)
{
  struct dl_open_args *args = a;
  const char *file = args->file;
  int mode = args->mode;
  struct link_map *new, *l;
  const char *dst;
  int lazy;
  unsigned int i;

  /* Maybe we have to expand a DST.  */
  dst = strchr (file, '$');
  if (dst != NULL)
    {
      const void *caller = args->caller;
      size_t len = strlen (file);
      size_t required;
      struct link_map *call_map;
      char *new_file;

      /* We have to find out from which object the caller is calling.  */
      call_map = NULL;
      for (l = _dl_loaded; l; l = l->l_next)
	if (caller >= (const void *) l->l_map_start
	    && caller < (const void *) l->l_map_end)
	  {
	    /* There must be exactly one DSO for the range of the virtual
	       memory.  Otherwise something is really broken.  */
	    call_map = l;
	    break;
	  }

      if (call_map == NULL)
	/* In this case we assume this is the main application.  */
	call_map = _dl_loaded;

      /* Determine how much space we need.  We have to allocate the
	 memory locally.  */
      required = DL_DST_REQUIRED (call_map, file, len, _dl_dst_count (dst, 0));

      /* Get space for the new file name.  */
      new_file = (char *) alloca (required + 1);

      /* Generate the new file name.  */
      DL_DST_SUBSTITUTE (call_map, file, new_file, 0);

      /* If the substitution failed don't try to load.  */
      if (*new_file == '\0')
	_dl_signal_error (0, "dlopen", NULL,
			  N_("empty dynamic string token substitution"));

      /* Now we have a new file name.  */
      file = new_file;
    }

  /* Load the named object.  */
  args->map = new = _dl_map_object (NULL, file, 0, lt_loaded, 0,
				    mode);

  /* If the pointer returned is NULL this means the RTLD_NOLOAD flag is
     set and the object is not already loaded.  */
  if (new == NULL)
    {
      assert (mode & RTLD_NOLOAD);
      return;
    }

  /* It was already open.  */
  if (new->l_searchlist.r_list != NULL)
    {
      /* Let the user know about the opencount.  */
      if (__builtin_expect (_dl_debug_mask & DL_DEBUG_FILES, 0))
	_dl_debug_printf ("opening file=%s; opencount == %u\n\n",
			  new->l_name, new->l_opencount);

      /* If the user requested the object to be in the global namespace
	 but it is not so far, add it now.  */
      if ((mode & RTLD_GLOBAL) && new->l_global == 0)
	(void) add_to_global (new);

      /* Increment just the reference counter of the object.  */
      ++new->l_opencount;

      return;
    }

  /* Load that object's dependencies.  */
  _dl_map_object_deps (new, NULL, 0, 0);

  /* So far, so good.  Now check the versions.  */
  for (i = 0; i < new->l_searchlist.r_nlist; ++i)
    if (new->l_searchlist.r_list[i]->l_versions == NULL)
      (void) _dl_check_map_versions (new->l_searchlist.r_list[i], 0, 0);

#ifdef SCOPE_DEBUG
  show_scope (new);
#endif

  /* Only do lazy relocation if `LD_BIND_NOW' is not set.  */
  lazy = (mode & RTLD_BINDING_MASK) == RTLD_LAZY && _dl_lazy;

  /* Relocate the objects loaded.  We do this in reverse order so that copy
     relocs of earlier objects overwrite the data written by later objects.  */

  l = new;
  while (l->l_next)
    l = l->l_next;
  while (1)
    {
      if (! l->l_relocated)
	{
#if 0
#ifdef SHARED
	  if (_dl_profile != NULL)
	    {
	      /* If this here is the shared object which we want to profile
		 make sure the profile is started.  We can find out whether
	         this is necessary or not by observing the `_dl_profile_map'
	         variable.  If was NULL but is not NULL afterwars we must
		 start the profiling.  */
	      struct link_map *old_profile_map = _dl_profile_map;

	      _dl_relocate_object (l, l->l_scope, 1, 1);

	      if (old_profile_map == NULL && _dl_profile_map != NULL)
		/* We must prepare the profiling.  */
		_dl_start_profile (_dl_profile_map, _dl_profile_output);
	    }
	  else
#endif
#endif
	    _dl_relocate_object (l, l->l_scope, lazy, 0);
	}

      if (l == new)
	break;
      l = l->l_prev;
    }

  /* Increment the open count for all dependencies.  If the file is
     not loaded as a dependency here add the search list of the newly
     loaded object to the scope.  */
  for (i = 0; i < new->l_searchlist.r_nlist; ++i)
    if (++new->l_searchlist.r_list[i]->l_opencount > 1
	&& new->l_searchlist.r_list[i]->l_type == lt_loaded)
      {
	struct link_map *imap = new->l_searchlist.r_list[i];
	struct r_scope_elem **runp = imap->l_scope;
	size_t cnt = 0;

	while (*runp != NULL)
	  {
	    /* This can happen if imap was just loaded, but during
	       relocation had l_opencount bumped because of relocation
	       dependency.  Avoid duplicates in l_scope.  */
	    if (__builtin_expect (*runp == &new->l_searchlist, 0))
	      break;

	    ++cnt;
	    ++runp;
	  }

	if (*runp != NULL)
	  /* Avoid duplicates.  */
	  continue;

	if (__builtin_expect (cnt + 1 >= imap->l_scope_max, 0))
	  {
	    /* The 'r_scope' array is too small.  Allocate a new one
	       dynamically.  */
	    struct r_scope_elem **newp;
	    size_t new_size = imap->l_scope_max * 2;

	    if (imap->l_scope == imap->l_scope_mem)
	      {
		newp = (struct r_scope_elem **)
		  malloc (new_size * sizeof (struct r_scope_elem *));
		if (newp == NULL)
		  _dl_signal_error (ENOMEM, "dlopen", NULL,
				    N_("cannot create scope list"));
		imap->l_scope = memcpy (newp, imap->l_scope,
					cnt * sizeof (imap->l_scope[0]));
	      }
	    else
	      {
		newp = (struct r_scope_elem **)
		  realloc (imap->l_scope,
			   new_size * sizeof (struct r_scope_elem *));
		if (newp == NULL)
		  _dl_signal_error (ENOMEM, "dlopen", NULL,
				    N_("cannot create scope list"));
		imap->l_scope = newp;
	      }

	    imap->l_scope_max = new_size;
	  }

	imap->l_scope[cnt++] = &new->l_searchlist;
	imap->l_scope[cnt] = NULL;
      }

  /* Run the initializer functions of new objects.  */
  _dl_init (new, __libc_argc, __libc_argv, environ);

  /* Now we can make the new map available in the global scope.  */
  if (mode & RTLD_GLOBAL)
    /* Move the object in the global namespace.  */
    if (add_to_global (new) != 0)
      /* It failed.  */
      return;

  /* Mark the object as not deletable if the RTLD_NODELETE flags was
     passed.  */
  if (__builtin_expect (mode & RTLD_NODELETE, 0))
    new->l_flags_1 |= DF_1_NODELETE;

  /* Let the user know about the opencount.  */
  if (__builtin_expect (_dl_debug_mask & DL_DEBUG_FILES, 0))
    _dl_debug_printf ("opening file=%s; opencount == %u\n\n",
		      new->l_name, new->l_opencount);
}


void *
internal_function
_dl_open (const char *file, int mode, const void *caller)
{
  struct dl_open_args args;
  const char *objname;
  const char *errstring;
  int errcode;

  if ((mode & RTLD_BINDING_MASK) == 0)
    /* One of the flags must be set.  */
    _dl_signal_error (EINVAL, file, NULL, N_("invalid mode for dlopen()"));

  /* Make sure we are alone.  */
#ifdef HAVE_DD_LOCK
    __lock_acquire_recursive(_dl_load_lock);
#endif

  args.file = file;
  args.mode = mode;
  args.caller = caller;
  args.map = NULL;
  errcode = _dl_catch_error (&objname, &errstring, dl_open_worker, &args);

#ifndef MAP_COPY
  /* We must munmap() the cache file.  */
  _dl_unload_cache ();
#endif

  /* Release the lock.  */
#ifdef HAVE_DD_LOCK
    __lock_release_recursive(_dl_load_lock);
#endif


  if (errstring)
    {
      /* Some error occurred during loading.  */
      char *local_errstring;
      size_t len_errstring;

      /* Remove the object from memory.  It may be in an inconsistent
	 state if relocation failed, for example.  */
      if (args.map)
	{
	  unsigned int i;

	  /* Increment open counters for all objects since this has
	     not happened yet.  */
	  for (i = 0; i < args.map->l_searchlist.r_nlist; ++i)
	    ++args.map->l_searchlist.r_list[i]->l_opencount;

	  _dl_close (args.map);
	}

      /* Make a local copy of the error string so that we can release the
	 memory allocated for it.  */
      len_errstring = strlen (errstring) + 1;
      if (objname == errstring + len_errstring)
	{
	  size_t total_len = len_errstring + strlen (objname) + 1;
	  local_errstring = alloca (total_len);
	  memcpy (local_errstring, errstring, total_len);
	  objname = local_errstring + len_errstring;
	}
      else
	{
	  local_errstring = alloca (len_errstring);
	  memcpy (local_errstring, errstring, len_errstring);
	}

      if (errstring != _dl_out_of_memory)
	free ((char *) errstring);

      /* Reraise the error.  */
      _dl_signal_error (errcode, objname, NULL, local_errstring);
    }

#ifndef SHARED
  DL_STATIC_INIT (args.map);
#endif

  return args.map;
}


#ifdef SCOPE_DEBUG
#include <unistd.h>

static void
show_scope (struct link_map *new)
{
  int scope_cnt;

  for (scope_cnt = 0; new->l_scope[scope_cnt] != NULL; ++scope_cnt)
    {
      char numbuf[2];
      unsigned int cnt;

      numbuf[0] = '0' + scope_cnt;
      numbuf[1] = '\0';
      _dl_printf ("scope %s:", numbuf);

      for (cnt = 0; cnt < new->l_scope[scope_cnt]->r_nlist; ++cnt)
	if (*new->l_scope[scope_cnt]->r_list[cnt]->l_name)
	  _dl_printf (" %s", new->l_scope[scope_cnt]->r_list[cnt]->l_name);
	else
	  _dl_printf (" <main>");

      _dl_printf ("\n");
    }
}
#endif

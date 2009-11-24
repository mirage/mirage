/* Load the dependencies of a mapped object.
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
#include <sys/param.h>
#include <ldsodefs.h>

#include <dl-dst.h>

/* Whether an shared object references one or more auxiliary objects
   is signaled by the AUXTAG entry in l_info.  */
#define AUXTAG	(DT_NUM + DT_THISPROCNUM + DT_VERSIONTAGNUM \
		 + DT_EXTRATAGIDX (DT_AUXILIARY))
/* Whether an shared object references one or more auxiliary objects
   is signaled by the AUXTAG entry in l_info.  */
#define FILTERTAG (DT_NUM + DT_THISPROCNUM + DT_VERSIONTAGNUM \
		   + DT_EXTRATAGIDX (DT_FILTER))

/* This is zero at program start to signal that the global scope map is
   allocated by rtld.  Later it keeps the size of the map.  It might be
   reset if in _dl_close if the last global object is removed.  */
size_t _dl_global_scope_alloc;

extern size_t _dl_platformlen;

/* When loading auxiliary objects we must ignore errors.  It's ok if
   an object is missing.  */
struct openaux_args
  {
    /* The arguments to openaux.  */
    struct link_map *map;
    int trace_mode;
    const char *strtab;
    const char *name;

    /* The return value of openaux.  */
    struct link_map *aux;
  };

static void
openaux (void *a)
{
  struct openaux_args *args = (struct openaux_args *) a;

  args->aux = _dl_map_object (args->map, args->name, 0,
			      (args->map->l_type == lt_executable
			       ? lt_library : args->map->l_type),
			      args->trace_mode, 0);
}



/* We use a very special kind of list to track the path
   through the list of loaded shared objects.  We have to
   produce a flat list with unique members of all involved objects.
*/
struct list
  {
    int done;			/* Nonzero if this map was processed.  */
    struct link_map *map;	/* The data.  */
    struct list *next;	/* Elements for normal list.  */
  };


/* Macro to expand DST.  It is an macro since we use `alloca'.  */
#define expand_dst(l, str, fatal) \
  ({									      \
    const char *__str = (str);						      \
    const char *__result = __str;					      \
    size_t __cnt = DL_DST_COUNT(__str, 0);				      \
									      \
    if (__cnt != 0)							      \
      {									      \
	char *__newp;							      \
									      \
	__newp = (char *) alloca (DL_DST_REQUIRED (l, __str, strlen (__str),  \
						   __cnt));		      \
									      \
	__result = DL_DST_SUBSTITUTE (l, __str, __newp, 0);		      \
									      \
	if (*__result == '\0')						      \
	  {								      \
	    /* The replacement for the DST is not known.  We can't	      \
	       processed.  */						      \
	    if (fatal)							      \
	      _dl_signal_error (0, __str, NULL, N_("\
empty dynamics string token substitution"));				      \
	    else							      \
	      {								      \
		/* This is for DT_AUXILIARY.  */			      \
		if (__builtin_expect (_dl_debug_mask & DL_DEBUG_LIBS, 0))     \
		  _dl_debug_printf ("cannot load auxiliary `%s' because of"   \
				    "empty dynamic string token "	      \
				    "substitution\n", __str);		      \
		continue;						      \
	      }								      \
	  }								      \
      }									      \
									      \
    __result; })


void
internal_function
_dl_map_object_deps (struct link_map *map,
		     struct link_map **preloads, unsigned int npreloads,
		     int trace_mode)
{
  struct list known[1 + npreloads + 1];
  struct list *runp, *tail;
  unsigned int nlist, i;
  /* Object name.  */
  const char *name;
  int errno_saved;
  int errno_reason;
  const char *errstring;
  const char *objname;

  auto inline void preload (struct link_map *map);

  inline void preload (struct link_map *map)
    {
      known[nlist].done = 0;
      known[nlist].map = map;
      known[nlist].next = &known[nlist + 1];

      ++nlist;
      /* We use `l_reserved' as a mark bit to detect objects we have
	 already put in the search list and avoid adding duplicate
	 elements later in the list.  */
      map->l_reserved = 1;
    }

  /* No loaded object so far.  */
  nlist = 0;

  /* First load MAP itself.  */
  preload (map);

  /* Add the preloaded items after MAP but before any of its dependencies.  */
  for (i = 0; i < npreloads; ++i)
    preload (preloads[i]);

  /* Terminate the lists.  */
  known[nlist - 1].next = NULL;

  /* Pointer to last unique object.  */
  tail = &known[nlist - 1];

  /* Process each element of the search list, loading each of its
     auxiliary objects and immediate dependencies.  Auxiliary objects
     will be added in the list before the object itself and
     dependencies will be appended to the list as we step through it.
     This produces a flat, ordered list that represents a
     breadth-first search of the dependency tree.

     The whole process is complicated by the fact that we better
     should use alloca for the temporary list elements.  But using
     alloca means we cannot use recursive function calls.  */
  errno_saved = errno;
  errno_reason = 0;
  errstring = NULL;
  errno = 0;
  name = NULL;
  for (runp = known; runp; )
    {
      struct link_map *l = runp->map;
      struct link_map **needed = NULL;
      unsigned int nneeded = 0;

      /* Unless otherwise stated, this object is handled.  */
      runp->done = 1;

      /* Allocate a temporary record to contain the references to the
	 dependencies of this object.  */
      if (l->l_searchlist.r_list == NULL && l->l_initfini == NULL
	  && l != map && l->l_ldnum > 0)
	needed = (struct link_map **) alloca (l->l_ldnum
					      * sizeof (struct link_map *));

      if (l->l_info[DT_NEEDED] || l->l_info[AUXTAG] || l->l_info[FILTERTAG])
	{
	  const char *strtab = (const void *) D_PTR (l, l_info[DT_STRTAB]);
	  struct openaux_args args;
	  struct list *orig;
	  const ElfW(Dyn) *d;

	  args.strtab = strtab;
	  args.map = l;
	  args.trace_mode = trace_mode;
	  orig = runp;

	  for (d = l->l_ld; d->d_tag != DT_NULL; ++d)
	    if (__builtin_expect (d->d_tag, DT_NEEDED) == DT_NEEDED)
	      {
		/* Map in the needed object.  */
		struct link_map *dep;
		int err;

		/* Recognize DSTs.  */
		name = expand_dst (l, strtab + d->d_un.d_val, 0);
		/* Store the tag in the argument structure.  */
		args.name = name;

		err = _dl_catch_error (&objname, &errstring, openaux, &args);
		if (__builtin_expect (errstring != NULL, 0))
		  {
		    if (err)
		      errno_reason = err;
		    else
		      errno_reason = -1;
		    goto out;
		  }
		else
		  dep = args.aux;

		if (! dep->l_reserved)
		  {
		    /* Allocate new entry.  */
		    struct list *newp;

		    newp = alloca (sizeof (struct list));

		    /* Append DEP to the list.  */
		    newp->map = dep;
		    newp->done = 0;
		    newp->next = NULL;
		    tail->next = newp;
		    tail = newp;
		    ++nlist;
		    /* Set the mark bit that says it's already in the list.  */
		    dep->l_reserved = 1;
		  }

		/* Remember this dependency.  */
		if (needed != NULL)
		  needed[nneeded++] = dep;
	      }
	    else if (d->d_tag == DT_AUXILIARY || d->d_tag == DT_FILTER)
	      {
		struct list *newp;

		/* Recognize DSTs.  */
		name = expand_dst (l, strtab + d->d_un.d_val,
				   d->d_tag == DT_AUXILIARY);
		/* Store the tag in the argument structure.  */
		args.name = name;

		if (d->d_tag == DT_AUXILIARY)
		  {
		    int err;

		    /* Say that we are about to load an auxiliary library.  */
		    if (__builtin_expect (_dl_debug_mask & DL_DEBUG_LIBS, 0))
		      _dl_debug_printf ("load auxiliary object=%s"
					" requested by file=%s\n", name,
					l->l_name[0]
					? l->l_name : _dl_argv[0]);

		    /* We must be prepared that the addressed shared
		       object is not available.  */
		    err = _dl_catch_error (&objname, &errstring, openaux,
					   &args);
		    if (__builtin_expect (errstring != NULL, 0))
		      {
			/* We are not interested in the error message.  */
			assert (errstring != NULL);
			if (errstring != _dl_out_of_memory)
			  free ((char *) errstring);

			/* Simply ignore this error and continue the work.  */
			continue;
		      }
		  }
		else
		  {
		    int err;

		    /* Say that we are about to load an auxiliary library.  */
		    if (__builtin_expect (_dl_debug_mask & DL_DEBUG_LIBS, 0))
		      _dl_debug_printf ("load filtered object=%s"
					" requested by file=%s\n", name,
					l->l_name[0]
					? l->l_name : _dl_argv[0]);

		    /* For filter objects the dependency must be available.  */
		    err = _dl_catch_error (&objname, &errstring, openaux,
					   &args);
		    if (__builtin_expect (errstring != NULL, 0))
		      {
			if (err)
			  errno_reason = err;
			else
			  errno_reason = -1;
			goto out;
		      }
		  }

		/* The auxiliary object is actually available.
		   Incorporate the map in all the lists.  */

		/* Allocate new entry.  This always has to be done.  */
		newp = alloca (sizeof (struct list));

		/* We want to insert the new map before the current one,
		   but we have no back links.  So we copy the contents of
		   the current entry over.  Note that ORIG and NEWP now
		   have switched their meanings.  */
		memcpy (newp, orig, sizeof (*newp));

		/* Initialize new entry.  */
		orig->done = 0;
		orig->map = args.aux;

		/* Remember this dependency.  */
		if (needed != NULL)
		  needed[nneeded++] = args.aux;

		/* We must handle two situations here: the map is new,
		   so we must add it in all three lists.  If the map
		   is already known, we have two further possibilities:
		   - if the object is before the current map in the
		   search list, we do nothing.  It is already found
		   early
		   - if the object is after the current one, we must
		   move it just before the current map to make sure
		   the symbols are found early enough
		*/
		if (args.aux->l_reserved)
		  {
		    /* The object is already somewhere in the list.
		       Locate it first.  */
		    struct list *late;

		    /* This object is already in the search list we
		       are building.  Don't add a duplicate pointer.
		       Just added by _dl_map_object.  */
		    for (late = newp; late->next != NULL; late = late->next)
		      if (late->next->map == args.aux)
			break;

		    if (late->next != NULL)
		      {
			/* The object is somewhere behind the current
			   position in the search path.  We have to
			   move it to this earlier position.  */
			orig->next = newp;

			/* Now remove the later entry from the list
			   and adjust the tail pointer.  */
			if (tail == late->next)
			  tail = late;
			late->next = late->next->next;

			/* We must move the object earlier in the chain.  */
			if (args.aux->l_prev != NULL)
			  args.aux->l_prev->l_next = args.aux->l_next;
			if (args.aux->l_next != NULL)
			  args.aux->l_next->l_prev = args.aux->l_prev;

			args.aux->l_prev = newp->map->l_prev;
			newp->map->l_prev = args.aux;
			if (args.aux->l_prev != NULL)
			  args.aux->l_prev->l_next = args.aux;
			args.aux->l_next = newp->map;
		      }
		    else
		      {
			/* The object must be somewhere earlier in the
			   list.  Undo to the current list element what
			   we did above.  */
			memcpy (orig, newp, sizeof (*newp));
			continue;
		      }
		  }
		else
		  {
		    /* This is easy.  We just add the symbol right here.  */
		    orig->next = newp;
		    ++nlist;
		    /* Set the mark bit that says it's already in the list.  */
		    args.aux->l_reserved = 1;

		    /* The only problem is that in the double linked
		       list of all objects we don't have this new
		       object at the correct place.  Correct this here.  */
		    if (args.aux->l_prev)
		      args.aux->l_prev->l_next = args.aux->l_next;
		    if (args.aux->l_next)
		      args.aux->l_next->l_prev = args.aux->l_prev;

		    args.aux->l_prev = newp->map->l_prev;
		    newp->map->l_prev = args.aux;
		    if (args.aux->l_prev != NULL)
		      args.aux->l_prev->l_next = args.aux;
		    args.aux->l_next = newp->map;
		  }

		/* Move the tail pointer if necessary.  */
		if (orig == tail)
		  tail = newp;

		/* Move on the insert point.  */
		orig = newp;
	      }
	}

      /* Terminate the list of dependencies and store the array address.  */
      if (needed != NULL)
	{
	  needed[nneeded++] = NULL;

	  l->l_initfini = (struct link_map **)
	    malloc ((nneeded + 1) * sizeof needed[0]);
	  if (l->l_initfini == NULL)
	    _dl_signal_error (ENOMEM, map->l_name, NULL,
			      N_("cannot allocate dependency list"));
	  l->l_initfini[0] = l;
	  memcpy (&l->l_initfini[1], needed, nneeded * sizeof needed[0]);
	}

      /* If we have no auxiliary objects just go on to the next map.  */
      if (runp->done)
	do
	  runp = runp->next;
	while (runp != NULL && runp->done);
    }

 out:
  if (errno == 0 && errno_saved != 0)
    __set_errno (errno_saved);

  if (map->l_initfini != NULL && map->l_type == lt_loaded)
    {
      /* This object was previously loaded as a dependency and we have
	 a separate l_initfini list.  We don't need it anymore.  */
      assert (map->l_searchlist.r_list == NULL);
      free (map->l_initfini);
    }

  /* Store the search list we built in the object.  It will be used for
     searches in the scope of this object.  */
  map->l_initfini =
    (struct link_map **) malloc ((2 * nlist + 1)
				 * sizeof (struct link_map *));
  if (map->l_initfini == NULL)
    _dl_signal_error (ENOMEM, map->l_name, NULL,
		      N_("cannot allocate symbol search list"));


  map->l_searchlist.r_list = &map->l_initfini[nlist + 1];
  map->l_searchlist.r_nlist = nlist;

  for (nlist = 0, runp = known; runp; runp = runp->next)
    {
      if (__builtin_expect (trace_mode, 0) && runp->map->l_faked)
	/* This can happen when we trace the loading.  */
	--map->l_searchlist.r_nlist;
      else
	map->l_searchlist.r_list[nlist++] = runp->map;

      /* Now clear all the mark bits we set in the objects on the search list
	 to avoid duplicates, so the next call starts fresh.  */
      runp->map->l_reserved = 0;
    }

  /* Maybe we can remove some relocation dependencies now.  */
  assert (map->l_searchlist.r_list[0] == map);
  for (i = 0; i < map->l_reldepsact; ++i)
    {
      unsigned int j;

      for (j = 1; j < nlist; ++j)
	if (map->l_searchlist.r_list[j] == map->l_reldeps[i])
	  {
	    /* A direct or transitive dependency is also on the list
	       of relocation dependencies.  Remove the latter.  */
	    --map->l_reldeps[i]->l_opencount;

	    for (j = i + 1; j < map->l_reldepsact; ++j)
	      map->l_reldeps[j - 1] = map->l_reldeps[j];

	    --map->l_reldepsact;

	    /* Account for the '++i' performed by the 'for'.  */
	    --i;
	    break;
	  }
    }

  /* Now determine the order in which the initialization has to happen.  */
  memcpy (map->l_initfini, map->l_searchlist.r_list,
	  nlist * sizeof (struct link_map *));
  /* We can skip looking for the binary itself which is at the front
     of the search list.  Look through the list backward so that circular
     dependencies are not changing the order.  */
  for (i = 1; i < nlist; ++i)
    {
      struct link_map *l = map->l_searchlist.r_list[i];
      unsigned int j;
      unsigned int k;

      /* Find the place in the initfini list where the map is currently
	 located.  */
      for (j = 1; map->l_initfini[j] != l; ++j)
	;

      /* Find all object for which the current one is a dependency and
	 move the found object (if necessary) in front.  */
      for (k = j + 1; k < nlist; ++k)
	{
	  struct link_map **runp;

	  runp = map->l_initfini[k]->l_initfini;
	  if (runp != NULL)
	    {
	      while (*runp != NULL)
		if (__builtin_expect (*runp++ == l, 0))
		  {
		    struct link_map *here = map->l_initfini[k];

		    /* Move it now.  */
		    memmove (&map->l_initfini[j] + 1,
			     &map->l_initfini[j],
			     (k - j) * sizeof (struct link_map *));
		    map->l_initfini[j] = here;

		    break;
		  }
	    }
	}
    }
  /* Terminate the list of dependencies.  */
  map->l_initfini[nlist] = NULL;

  if (errno_reason)
    _dl_signal_error (errno_reason == -1 ? 0 : errno_reason,
		      objname, NULL, errstring);
}

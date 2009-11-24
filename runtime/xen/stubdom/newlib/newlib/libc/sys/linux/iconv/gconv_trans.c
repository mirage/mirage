/* Transliteration using the locale's data.
   Copyright (C) 2000 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@cygnus.com>, 2000.

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
#include <search.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <dirent.h>
#include <ltdl.h>

#include "gconv_int.h"
#include "localeinfo.h"

int
__gconv_transliterate (struct __gconv_step *step,
		       struct __gconv_step_data *step_data,
		       void *trans_data __attribute__ ((unused)),
		       const unsigned char *inbufstart,
		       const unsigned char **inbufp,
		       const unsigned char *inbufend,
		       unsigned char **outbufstart, size_t *irreversible)
{
  return 0;
}


/* Structure to represent results of found (or not) transliteration
   modules.  */
struct known_trans
{
  /* This structure must remain the first member.  */
  struct trans_struct info;

  char *fname;
  void *handle;
  int open_count;
};


/* Tree with results of previous calls to __gconv_translit_find.  */
static void *search_tree;

/* We modify global data.   */
__LOCK_INIT(static, lock);

/* Compare two transliteration entries.  */
static int
trans_compare (const void *p1, const void *p2)
{
  const struct known_trans *s1 = (const struct known_trans *) p1;
  const struct known_trans *s2 = (const struct known_trans *) p2;

  return strcmp (s1->info.name, s2->info.name);
}


/* Open (maybe reopen) the module named in the struct.  Get the function
   and data structure pointers we need.  */
static int
open_translit (struct known_trans *trans)
{
  __gconv_trans_query_fct queryfct;

  trans->handle = __libc_dlopen (trans->fname);
  if (trans->handle == NULL)
    /* Not available.  */
    return 1;

  /* Find the required symbol.  */
  queryfct = __libc_dlsym (trans->handle, "gconv_trans_context");
  if (queryfct == NULL)
    {
      /* We cannot live with that.  */
    close_and_out:
      __libc_dlclose (trans->handle);
      trans->handle = NULL;
      return 1;
    }

  /* Get the context.  */
  if (queryfct (trans->info.name, &trans->info.csnames, &trans->info.ncsnames)
      != 0)
    goto close_and_out;

  /* Of course we also have to have the actual function.  */
  trans->info.trans_fct = __libc_dlsym (trans->handle, "gconv_trans");
  if (trans->info.trans_fct == NULL)
    goto close_and_out;

  /* Now the optional functions.  */
  trans->info.trans_init_fct =
    __libc_dlsym (trans->handle, "gconv_trans_init");
  trans->info.trans_context_fct =
    __libc_dlsym (trans->handle, "gconv_trans_context");
  trans->info.trans_end_fct =
    __libc_dlsym (trans->handle, "gconv_trans_end");

  trans->open_count = 1;

  return 0;
}


int
internal_function
__gconv_translit_find (struct trans_struct *trans)
{
  struct known_trans **found;
  const struct path_elem *runp;
  int res = 1;

  /* We have to have a name.  */
  assert (trans->name != NULL);

  /* Acquire the lock.  */
#ifdef HAVE_DD_LOCK
  __lock_acquire(lock);
#endif

  /* See whether we know this module already.  */
  found = tfind (trans, &search_tree, trans_compare);
  if (found != NULL)
    {
      /* Is this module available?  */
      if ((*found)->handle != NULL)
	{
	  /* Maybe we have to reopen the file.  */
	  if ((*found)->handle != (void *) -1)
	    /* The object is not unloaded.  */
	    res = 0;
	  else if (open_translit (*found) == 0)
	    {
	      /* Copy the data.  */
	      *trans = (*found)->info;
	      (*found)->open_count++;
	      res = 0;
	    }
	}
    }
  else
    {
      size_t name_len = strlen (trans->name) + 1;
      int need_so = 0;
      struct known_trans *newp;

      /* We have to continue looking for the module.  */
      if (__gconv_path_elem == NULL)
	__gconv_get_path ();

      /* See whether we have to append .so.  */
      if (name_len <= 4 || memcmp (&trans->name[name_len - 4], ".so", 3) != 0)
	need_so = 1;

      /* Create a new entry.  */
      newp = (struct known_trans *) malloc (sizeof (struct known_trans)
					    + (__gconv_max_path_elem_len
					       + name_len + 3)
					    + name_len);
      if (newp != NULL)
	{
	  char *cp;

	  /* Clear the struct.  */
	  memset (newp, '\0', sizeof (struct known_trans));

	  /* Store a copy of the module name.  */
	  newp->info.name = cp = (char *) (newp + 1);
	  cp = memcpy (cp, trans->name, name_len);
          cp += name_len;

	  newp->fname = cp;

	  /* Search in all the directories.  */
	  for (runp = __gconv_path_elem; runp->name != NULL; ++runp)
	    {
              strcpy ((char *) newp->fname, runp->name);
              while(newp->fname != '\0') newp->fname++;

	      cp = memcpy (newp->fname,
                            trans->name, name_len);
              cp += name_len;
	      if (need_so)
		memcpy (cp, ".so", sizeof (".so"));

	      if (open_translit (newp) == 0)
		{
		  /* We found a module.  */
		  res = 0;
		  break;
		}
	    }

	  if (res)
	    newp->fname = NULL;

	  /* In any case we'll add the entry to our search tree.  */
	  if (tsearch (newp, &search_tree, trans_compare) == NULL)
	    {
	      /* Yickes, this should not happen.  Unload the object.  */
	      res = 1;
	      /* XXX unload here.  */
	    }
	}
    }

#ifdef HAVE_DD_LOCK
  __lock_release(lock);
#endif

  return res;
}

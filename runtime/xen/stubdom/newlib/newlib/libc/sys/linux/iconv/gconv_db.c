/* Provide access to the collection of available transformation modules.
   Copyright (C) 1997,98,99,2000,2001 Free Software Foundation, Inc.
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

#include <limits.h>
#include <search.h>
#include <stdlib.h>
#include <string.h>
#include <sys/param.h>
#include <dirent.h>

#include <dlfcn.h>
#include <gconv_int.h>
#include <gconv_charset.h>


/* Simple data structure for alias mapping.  We have two names, `from'
   and `to'.  */
void *__gconv_alias_db;

/* Array with available modules.  */
struct gconv_module *__gconv_modules_db;

/* We modify global data.   */
__LOCK_INIT(static, lock);


/* Function for searching alias.  */
int
__gconv_alias_compare (const void *p1, const void *p2)
{
  const struct gconv_alias *s1 = (const struct gconv_alias *) p1;
  const struct gconv_alias *s2 = (const struct gconv_alias *) p2;
  return strcmp (s1->fromname, s2->fromname);
}


/* To search for a derivation we create a list of intermediate steps.
   Each element contains a pointer to the element which precedes it
   in the derivation order.  */
struct derivation_step
{
  const char *result_set;
  size_t result_set_len;
  int cost_lo;
  int cost_hi;
  struct gconv_module *code;
  struct derivation_step *last;
  struct derivation_step *next;
};

#define NEW_STEP(result, hi, lo, module, last_mod) \
  ({ struct derivation_step *newp = alloca (sizeof (struct derivation_step)); \
     newp->result_set = result;						      \
     newp->result_set_len = strlen (result);				      \
     newp->cost_hi = hi;						      \
     newp->cost_lo = lo;						      \
     newp->code = module;						      \
     newp->last = last_mod;						      \
     newp->next = NULL;							      \
     newp; })


/* If a specific transformation is used more than once we should not need
   to start looking for it again.  Instead cache each successful result.  */
struct known_derivation
{
  const char *from;
  const char *to;
  struct __gconv_step *steps;
  size_t nsteps;
};

/* Compare function for database of found derivations.  */
static int
derivation_compare (const void *p1, const void *p2)
{
  const struct known_derivation *s1 = (const struct known_derivation *) p1;
  const struct known_derivation *s2 = (const struct known_derivation *) p2;
  int result;

  result = strcmp (s1->from, s2->from);
  if (result == 0)
    result = strcmp (s1->to, s2->to);
  return result;
}

/* The search tree for known derivations.  */
static void *known_derivations;

/* Look up whether given transformation was already requested before.  */
static int
internal_function
derivation_lookup (const char *fromset, const char *toset,
		   struct __gconv_step **handle, size_t *nsteps)
{
  struct known_derivation key = { fromset, toset, NULL, 0 };
  struct known_derivation **result;

  result = tfind (&key, &known_derivations, derivation_compare);

  if (result == NULL)
    return __GCONV_NOCONV;

  *handle = (*result)->steps;
  *nsteps = (*result)->nsteps;

  /* Please note that we return GCONV_OK even if the last search for
     this transformation was unsuccessful.  */
  return __GCONV_OK;
}

/* Add new derivation to list of known ones.  */
static void
internal_function
add_derivation (const char *fromset, const char *toset,
		struct __gconv_step *handle, size_t nsteps)
{
  struct known_derivation *new_deriv;
  size_t fromset_len = strlen (fromset) + 1;
  size_t toset_len = strlen (toset) + 1;

  new_deriv = (struct known_derivation *)
    malloc (sizeof (struct known_derivation) + fromset_len + toset_len);
  if (new_deriv != NULL)
    {
      char *tmp;
      new_deriv->from = (char *) (new_deriv + 1);
      tmp = memcpy (new_deriv + 1, fromset, fromset_len);
      tmp += fromset_len;

      new_deriv->to = memcpy (tmp,
			      toset, toset_len);

      new_deriv->steps = handle;
      new_deriv->nsteps = nsteps;

      if (tsearch (new_deriv, &known_derivations, derivation_compare)
	  == NULL)
	/* There is some kind of memory allocation problem.  */
	free (new_deriv);
    }
  /* Please note that we don't complain if the allocation failed.  This
     is not tragically but in case we use the memory debugging facilities
     not all memory will be freed.  */
}

static void
free_derivation (void *p)
{
  struct known_derivation *deriv = (struct known_derivation *) p;
  size_t cnt;

  for (cnt = 0; cnt < deriv->nsteps; ++cnt)
    if (deriv->steps[cnt].__counter > 0
	&& deriv->steps[cnt].__end_fct != NULL)
      deriv->steps[cnt].__end_fct (&deriv->steps[cnt]);

  /* Free the name strings.  */
  free ((char *) deriv->steps[0].__from_name);
  free ((char *) deriv->steps[deriv->nsteps - 1].__to_name);

  free ((struct __gconv_step *) deriv->steps);
  free (deriv);
}


/* Decrement the reference count for a single step in a steps array.  */
void
internal_function
__gconv_release_step (struct __gconv_step *step)
{
  if (--step->__counter == 0)
    {
      /* Call the destructor.  */
      if (step->__end_fct != NULL)
	step->__end_fct (step);

#ifndef STATIC_GCONV
      /* Skip builtin modules; they are not reference counted.  */
      if (step->__shlib_handle != NULL)
	{
	  /* Release the loaded module.  */
	  __gconv_release_shlib (step->__shlib_handle);
	  step->__shlib_handle = NULL;
	}
#endif
    }
}

static int
internal_function
gen_steps (struct derivation_step *best, const char *toset,
	   const char *fromset, struct __gconv_step **handle, size_t *nsteps)
{
  size_t step_cnt = 0;
  struct __gconv_step *result;
  struct derivation_step *current;
  int status = __GCONV_NOMEM;

  /* First determine number of steps.  */
  for (current = best; current->last != NULL; current = current->last)
    ++step_cnt;

  result = (struct __gconv_step *) malloc (sizeof (struct __gconv_step)
					   * step_cnt);
  if (result != NULL)
    {
      int failed = 0;

      status = __GCONV_OK;
      *nsteps = step_cnt;
      current = best;
      while (step_cnt-- > 0)
	{
	  result[step_cnt].__from_name = (step_cnt == 0
					  ? strdup (fromset)
					  : (char *)current->last->result_set);
	  result[step_cnt].__to_name = (step_cnt + 1 == *nsteps
					? strdup (current->result_set)
					: result[step_cnt + 1].__from_name);

	  result[step_cnt].__counter = 1;
	  result[step_cnt].__data = NULL;

#ifndef STATIC_GCONV
	  if (current->code->module_name[0] == '/')
	    {
	      /* Load the module, return handle for it.  */
	      struct __gconv_loaded_object *shlib_handle =
		__gconv_find_shlib (current->code->module_name);

	      if (shlib_handle == NULL)
		{
		  failed = 1;
		  break;
		}

	      result[step_cnt].__shlib_handle = shlib_handle;
	      result[step_cnt].__modname = shlib_handle->name;
	      result[step_cnt].__fct = shlib_handle->fct;
	      result[step_cnt].__init_fct = shlib_handle->init_fct;
	      result[step_cnt].__end_fct = shlib_handle->end_fct;

	      /* Call the init function.  */
	      if (result[step_cnt].__init_fct != NULL)
		{
		  status = result[step_cnt].__init_fct (&result[step_cnt]);

		  if (__builtin_expect (status, __GCONV_OK) != __GCONV_OK)
		    {
		      failed = 1;
		      /* Make sure we unload this modules.  */
		      --step_cnt;
		      result[step_cnt].__end_fct = NULL;
		      break;
		    }
		}
	    }
	  else
#endif
	    /* It's a builtin transformation.  */
	    __gconv_get_builtin_trans (current->code->module_name,
				       &result[step_cnt]);

	  current = current->last;
	}

      if (__builtin_expect (failed, 0) != 0)
	{
	  /* Something went wrong while initializing the modules.  */
	  while (++step_cnt < *nsteps)
	    __gconv_release_step (&result[step_cnt]);
	  free (result);
	  *nsteps = 0;
	  *handle = NULL;
	  if (status == __GCONV_OK)
	    status = __GCONV_NOCONV;
	}
      else
	*handle = result;
    }
  else
    {
      *nsteps = 0;
      *handle = NULL;
    }

  return status;
}


#ifndef STATIC_GCONV
static int
internal_function
increment_counter (struct __gconv_step *steps, size_t nsteps)
{
  /* Increment the user counter.  */
  size_t cnt = nsteps;
  int result = __GCONV_OK;

  while (cnt-- > 0)
    {
      struct __gconv_step *step = &steps[cnt];

      if (step->__counter++ == 0)
	{
	  /* Skip builtin modules.  */
	  if (step->__modname != NULL)
	    {
	      /* Reopen a previously used module.  */
	      step->__shlib_handle = __gconv_find_shlib (step->__modname);
	      if (step->__shlib_handle == NULL)
		{
		  /* Oops, this is the second time we use this module
		     (after unloading) and this time loading failed!?  */
		  --step->__counter;
		  while (++cnt < nsteps)
		    __gconv_release_step (&steps[cnt]);
		  result = __GCONV_NOCONV;
		  break;
		}

	      /* The function addresses defined by the module may
		 have changed.  */
	      step->__fct = step->__shlib_handle->fct;
	      step->__init_fct = step->__shlib_handle->init_fct;
	      step->__end_fct = step->__shlib_handle->end_fct;
	    }

	  if (step->__init_fct != NULL)
	    step->__init_fct (step);
	}
    }
  return result;
}
#endif


/* The main function: find a possible derivation from the `fromset' (either
   the given name or the alias) to the `toset' (again with alias).  */
static int
internal_function
find_derivation (const char *toset, const char *toset_expand,
		 const char *fromset, const char *fromset_expand,
		 struct __gconv_step **handle, size_t *nsteps)
{
  struct derivation_step *first, *current, **lastp, *solution = NULL;
  int best_cost_hi = INT_MAX;
  int best_cost_lo = INT_MAX;
  int result;

  /* Look whether an earlier call to `find_derivation' has already
     computed a possible derivation.  If so, return it immediately.  */
  result = derivation_lookup (fromset_expand ?: fromset, toset_expand ?: toset,
			      handle, nsteps);
  if (result == __GCONV_OK)
    {
#ifndef STATIC_GCONV
      result = increment_counter (*handle, *nsteps);
#endif
      return result;
    }

  /* The task is to find a sequence of transformations, backed by the
     existing modules - whether builtin or dynamically loadable -,
     starting at `fromset' (or `fromset_expand') and ending at `toset'
     (or `toset_expand'), and with minimal cost.

     For computer scientists, this is a shortest path search in the
     graph where the nodes are all possible charsets and the edges are
     the transformations listed in __gconv_modules_db.

     For now we use a simple algorithm with quadratic runtime behaviour.
     A breadth-first search, starting at `fromset' and `fromset_expand'.
     The list starting at `first' contains all nodes that have been
     visited up to now, in the order in which they have been visited --
     excluding the goal nodes `toset' and `toset_expand' which get
     managed in the list starting at `solution'.
     `current' walks through the list starting at `first' and looks
     which nodes are reachable from the current node, adding them to
     the end of the list [`first' or `solution' respectively] (if
     they are visited the first time) or updating them in place (if
     they have have already been visited).
     In each node of either list, cost_lo and cost_hi contain the
     minimum cost over any paths found up to now, starting at `fromset'
     or `fromset_expand', ending at that node.  best_cost_lo and
     best_cost_hi represent the minimum over the elements of the
     `solution' list.  */

  if (fromset_expand != NULL)
    {
      first = NEW_STEP (fromset_expand, 0, 0, NULL, NULL);
      first->next = NEW_STEP (fromset, 0, 0, NULL, NULL);
      lastp = &first->next->next;
    }
  else
    {
      first = NEW_STEP (fromset, 0, 0, NULL, NULL);
      lastp = &first->next;
    }

  for (current = first; current != NULL; current = current->next)
    {
      /* Now match all the available module specifications against the
         current charset name.  If any of them matches check whether
         we already have a derivation for this charset.  If yes, use the
         one with the lower costs.  Otherwise add the new charset at the
         end.

	 The module database is organized in a tree form which allows
	 searching for prefixes.  So we search for the first entry with a
	 matching prefix and any other matching entry can be found from
	 this place.  */
      struct gconv_module *node;

      /* Maybe it is not necessary anymore to look for a solution for
	 this entry since the cost is already as high (or higher) as
	 the cost for the best solution so far.  */
      if (current->cost_hi > best_cost_hi
	  || (current->cost_hi == best_cost_hi
	      && current->cost_lo >= best_cost_lo))
	continue;

      node = __gconv_modules_db;
      while (node != NULL)
	{
	  int cmpres = strcmp (current->result_set, node->from_string);
	  if (cmpres == 0)
	    {
	      /* Walk through the list of modules with this prefix and
		 try to match the name.  */
	      struct gconv_module *runp;

	      /* Check all the modules with this prefix.  */
	      runp = node;
	      do
		{
		  const char *result_set = (strcmp (runp->to_string, "-") == 0
					    ? (toset_expand ?: toset)
					    : runp->to_string);
		  int cost_hi = runp->cost_hi + current->cost_hi;
		  int cost_lo = runp->cost_lo + current->cost_lo;
		  struct derivation_step *step;

		  /* We managed to find a derivation.  First see whether
		     we have reached one of the goal nodes.  */
		  if (strcmp (result_set, toset) == 0
		      || (toset_expand != NULL
			  && strcmp (result_set, toset_expand) == 0))
		    {
		      /* Append to the `solution' list if there
			 is no entry with this name.  */
		      for (step = solution; step != NULL; step = step->next)
			if (strcmp (result_set, step->result_set) == 0)
			  break;

		      if (step == NULL)
			{
			  step = NEW_STEP (result_set,
					   cost_hi, cost_lo,
					   runp, current);
			  step->next = solution;
			  solution = step;
			}
		      else if (step->cost_hi > cost_hi
			       || (step->cost_hi == cost_hi
				   && step->cost_lo > cost_lo))
			{
			  /* A better path was found for the node,
			     on the `solution' list.  */
			  step->code = runp;
			  step->last = current;
			  step->cost_hi = cost_hi;
			  step->cost_lo = cost_lo;
			}

		      /* Update best_cost accordingly.  */
		      if (cost_hi < best_cost_hi
			  || (cost_hi == best_cost_hi
			      && cost_lo < best_cost_lo))
			{
			  best_cost_hi = cost_hi;
			  best_cost_lo = cost_lo;
			}
		    }
		  else if (cost_hi < best_cost_hi
			   || (cost_hi == best_cost_hi
			       && cost_lo < best_cost_lo))
		    {
		      /* Append at the end of the `first' list if there
			 is no entry with this name.  */
		      for (step = first; step != NULL; step = step->next)
			if (strcmp (result_set, step->result_set) == 0)
			  break;

		      if (step == NULL)
			{
			  *lastp = NEW_STEP (result_set,
					     cost_hi, cost_lo,
					     runp, current);
			  lastp = &(*lastp)->next;
			}
		      else if (step->cost_hi > cost_hi
			       || (step->cost_hi == cost_hi
				   && step->cost_lo > cost_lo))
			{
			  /* A better path was found for the node,
			     on the `first' list.  */
			  step->code = runp;
			  step->last = current;

			  /* Update the cost for all steps.  */
			  for (step = first; step != NULL;
			       step = step->next)
			    /* But don't update the start nodes.  */
			    if (step->code != NULL)
			      {
				struct derivation_step *back;
				int hi, lo;

				hi = step->code->cost_hi;
				lo = step->code->cost_lo;

				for (back = step->last; back->code != NULL;
				     back = back->last)
				  {
				    hi += back->code->cost_hi;
				    lo += back->code->cost_lo;
				  }

				step->cost_hi = hi;
				step->cost_lo = lo;
			      }

			  /* Likewise for the nodes on the solution list.
			     Also update best_cost accordingly.  */
			  for (step = solution; step != NULL;
			       step = step->next)
			    {
			      step->cost_hi = (step->code->cost_hi
					       + step->last->cost_hi);
			      step->cost_lo = (step->code->cost_lo
					       + step->last->cost_lo);

			      if (step->cost_hi < best_cost_hi
				  || (step->cost_hi == best_cost_hi
				      && step->cost_lo < best_cost_lo))
				{
				  best_cost_hi = step->cost_hi;
				  best_cost_lo = step->cost_lo;
				}
			    }
			}
		    }

		  runp = runp->same;
		}
	      while (runp != NULL);

	      break;
	    }
	  else if (cmpres < 0)
	    node = node->left;
	  else
	    node = node->right;
	}
    }

  if (solution != NULL)
    {
      /* We really found a way to do the transformation.  */

      /* Choose the best solution.  This is easy because we know that
	 the solution list has at most length 2 (one for every possible
	 goal node).  */
      if (solution->next != NULL)
	{
	  struct derivation_step *solution2 = solution->next;

	  if (solution2->cost_hi < solution->cost_hi
	      || (solution2->cost_hi == solution->cost_hi
		  && solution2->cost_lo < solution->cost_lo))
	    solution = solution2;
	}

      /* Now build a data structure describing the transformation steps.  */
      result = gen_steps (solution, toset_expand ?: toset,
			  fromset_expand ?: fromset, handle, nsteps);
    }
  else
    {
      /* We haven't found a transformation.  Clear the result values.  */
      *handle = NULL;
      *nsteps = 0;
    }

  /* Add result in any case to list of known derivations.  */
  add_derivation (fromset_expand ?: fromset, toset_expand ?: toset,
		  *handle, *nsteps);

  return result;
}


/* Control of initialization.  */
__libc_once_define (static, once);


static const char *
do_lookup_alias (const char *name)
{
  struct gconv_alias key;
  struct gconv_alias **found;

  key.fromname = (char *) name;
  found = tfind (&key, &__gconv_alias_db, __gconv_alias_compare);
  return found != NULL ? (*found)->toname : NULL;
}


int
internal_function
__gconv_compare_alias (const char *name1, const char *name2)
{
  int result;

  /* Ensure that the configuration data is read.  */
  __libc_once (once, __gconv_read_conf);

  if (__gconv_compare_alias_cache (name1, name2, &result) != 0)
    result = strcmp (do_lookup_alias (name1) ?: name1,
		     do_lookup_alias (name2) ?: name2);

  return result;
}


int
internal_function
__gconv_find_transform (const char *toset, const char *fromset,
			struct __gconv_step **handle, size_t *nsteps,
			int flags)
{
  const char *fromset_expand;
  const char *toset_expand;
  int result;

  /* Ensure that the configuration data is read.  */
  __libc_once (once, __gconv_read_conf);

  /* Acquire the lock.  */
#ifdef HAVE_DD_LOCK
  __lock_acquire(lock);
#endif

  result = __gconv_lookup_cache (toset, fromset, handle, nsteps, flags);
  if (result != __GCONV_NODB)
    {
      /* We have a cache and could resolve the request, successful or not.  */
#ifdef HAVE_DD_LOCK
      __lock_release(lock);
#endif

      return result;
    }

  /* If we don't have a module database return with an error.  */
  if (__gconv_modules_db == NULL)
    {
#ifdef HAVE_DD_LOCK
  __lock_release(lock);
#endif

      return __GCONV_NOCONV;
    }

  /* See whether the names are aliases.  */
  fromset_expand = do_lookup_alias (fromset);
  toset_expand = do_lookup_alias (toset);

  if (__builtin_expect (flags & GCONV_AVOID_NOCONV, 0)
      /* We are not supposed to create a pseudo transformation (means
	 copying) when the input and output character set are the same.  */
      && (strcmp (toset, fromset) == 0
	  || (toset_expand != NULL && strcmp (toset_expand, fromset) == 0)
	  || (fromset_expand != NULL
	      && (strcmp (toset, fromset_expand) == 0
		  || (toset_expand != NULL
		      && strcmp (toset_expand, fromset_expand) == 0)))))
    {
      /* Both character sets are the same.  */
#ifdef HAVE_DD_LOCK
  __lock_release(lock);
#endif

      return __GCONV_NOCONV;
    }

  result = find_derivation (toset, toset_expand, fromset, fromset_expand,
			    handle, nsteps);

  /* Release the lock.  */
#ifdef HAVE_DD_LOCK
  __lock_release(lock);
#endif


  /* The following code is necessary since `find_derivation' will return
     GCONV_OK even when no derivation was found but the same request
     was processed before.  I.e., negative results will also be cached.  */
  return (result == __GCONV_OK
	  ? (*handle == NULL ? __GCONV_NOCONV : __GCONV_OK)
	  : result);
}


/* Release the entries of the modules list.  */
int
internal_function
__gconv_close_transform (struct __gconv_step *steps, size_t nsteps)
{
  int result = __GCONV_OK;
  size_t cnt;

  /* Acquire the lock.  */
#ifdef HAVE_DD_LOCK
  __lock_acquire(lock);
#endif


#ifndef STATIC_GCONV
  cnt = nsteps;
  while (cnt-- > 0)
    __gconv_release_step (&steps[cnt]);
#endif

  /* If we use the cache we free a bit more since we don't keep any
     transformation records around, they are cheap enough to
     recreate.  */
  __gconv_release_cache (steps, nsteps);

  /* Release the lock.  */
#ifdef HAVE_DD_LOCK
  __lock_release(lock);
#endif


  return result;
}


/* Free the modules mentioned.  */
static void
internal_function
free_modules_db (struct gconv_module *node)
{
  if (node->left != NULL)
    free_modules_db (node->left);
  if (node->right != NULL)
    free_modules_db (node->right);
  do
    {
      struct gconv_module *act = node;
      node = node->same;
      if (act->module_name[0] == '/')
	free (act);
    }
  while (node != NULL);
}


/* Free all resources if necessary.  */
static void __attribute__ ((unused))
free_mem (void)
{
  if (__gconv_alias_db != NULL)
    tdestroy (__gconv_alias_db, free);

  if (__gconv_modules_db != NULL)
    free_modules_db (__gconv_modules_db);

  if (known_derivations != NULL)
    tdestroy (known_derivations, free_derivation);
}

text_set_element (__libc_subfreeres, free_mem);

/* Find matching transformation algorithms and initialize steps.
   Copyright (C) 1997, 1998, 1999, 2000, 2001 Free Software Foundation, Inc.
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

#include <errno.h>
#include <locale.h>
#include <stdlib.h>
#include <string.h>

#include <gconv_int.h>

int
internal_function
__gconv_open (const char *toset, const char *fromset, __gconv_t *handle,
	      int flags)
{
  struct __gconv_step *steps;
  size_t nsteps;
  __gconv_t result = NULL;
  size_t cnt = 0;
  int res;
  int conv_flags = 0;
  const char *errhand;
  const char *ignore;
  struct trans_struct *trans = NULL;
  char old_locale[20], *old_locale_p;
  char *old, *new;
  size_t len;

  /* Find out whether any error handling method is specified.  */
  errhand = strchr (toset, '/');
  if (errhand != NULL)
    errhand = strchr (errhand + 1, '/');
  if (__builtin_expect (errhand != NULL, 1))
    {
      if (*++errhand == '\0')
	errhand = NULL;
      else
	{
	  /* Make copy without the error handling description.  */
	  char *newtoset = (char *) alloca (errhand - toset + 1);
	  char *tok;
	  char *ptr;

	  newtoset[errhand - toset] = '\0';
	  toset = memcpy (newtoset, toset, errhand - toset);

	  /* Find the appropriate transliteration handlers.  */
          old = (char *)(errhand);
          len = strlen (old) + 1;
          new = (char *) alloca (len);
          tok = (char *) memcpy (new, old, len);

	  tok = strtok_r (tok, ",", &ptr);

          /* Set locale to default C locale. */
          old_locale_p = setlocale(LC_ALL, "C");
          strncpy(old_locale, old_locale_p, 20);

	  while (tok != NULL)
	    {
	      if (strcasecmp (tok, "TRANSLIT") == 0)
		{
		  /* It's the builtin transliteration handling.  We only
		     support it for working on the internal encoding.  */
		  static const char *internal_trans_names[1] = { "INTERNAL" };
		  struct trans_struct *lastp = NULL;
		  struct trans_struct *runp;

		  for (runp = trans; runp != NULL; runp = runp->next)
		    if (runp->trans_fct == __gconv_transliterate)
		      break;
		    else
		      lastp = runp;

		  if (runp == NULL)
		    {
		      struct trans_struct *newp;

		      newp = (struct trans_struct *) alloca (sizeof (*newp));
		      memset (newp, '\0', sizeof (*newp));

		      /* We leave the `name' field zero to signal that
			 this is an internal transliteration step.  */
		      newp->csnames = internal_trans_names;
		      newp->ncsnames = 1;
		      newp->trans_fct = __gconv_transliterate;

		      if (lastp == NULL)
			trans = newp;
		      else
			lastp->next = newp;
		    }
		}
	      else if (strcasecmp (tok, "IGNORE") == 0)
		/* Set the flag to ignore all errors.  */
		conv_flags |= __GCONV_IGNORE_ERRORS;
	      else
		{
		  /* `tok' is possibly a module name.  We'll see later
		     whether we can find it.  But first see that we do
		     not already a module of this name.  */
		  struct trans_struct *lastp = NULL;
		  struct trans_struct *runp;

		  for (runp = trans; runp != NULL; runp = runp->next)
		    if (runp->name != NULL
			&& strcasecmp (tok, runp->name) == 0)
		      break;
		    else
		      lastp = runp;

		  if (runp == NULL)
		    {
		      struct trans_struct *newp;

		      newp = (struct trans_struct *) alloca (sizeof (*newp));
		      memset (newp, '\0', sizeof (*newp));
		      newp->name = tok;

		      if (lastp == NULL)
			trans = newp;
		      else
			lastp->next = newp;
		    }
		}

	      tok = strtok_r (NULL, ",", &ptr);
	    }
	}
    }

  /* For the source character set we ignore the error handler specification.
     XXX Is this really always the best?  */
  ignore = strchr (fromset, '/');
  if (ignore != NULL && (ignore = strchr (ignore + 1, '/')) != NULL
      && *++ignore != '\0')
    {
      char *newfromset = (char *) alloca (ignore - fromset + 1);

      newfromset[ignore - fromset] = '\0';
      fromset = memcpy (newfromset, fromset, ignore - fromset);
    }

  res = __gconv_find_transform (toset, fromset, &steps, &nsteps, flags);
  if (res == __GCONV_OK)
    {
      /* Find the modules.  */
      struct trans_struct *lastp = NULL;
      struct trans_struct *runp;

      for (runp = trans; runp != NULL; runp = runp->next)
	{
	  if (runp->name == NULL
	      || __builtin_expect (__gconv_translit_find (runp), 0) == 0)
	    lastp = runp;
	  else
	    /* This means we haven't found the module.  Remove it.  */
	    if (lastp == NULL)
	      trans = runp->next;
	    else
	      lastp->next = runp->next;
	}

      /* Allocate room for handle.  */
      result = (__gconv_t) malloc (sizeof (struct __gconv_info)
				   + (nsteps
				      * sizeof (struct __gconv_step_data)));
      if (result == NULL)
	res = __GCONV_NOMEM;
      else
	{
	  size_t n;

	  /* Remember the list of steps.  */
	  result->__steps = steps;
	  result->__nsteps = nsteps;

	  /* Clear the array for the step data.  */
	  memset (result->__data, '\0',
		  nsteps * sizeof (struct __gconv_step_data));

	  /* Call all initialization functions for the transformation
	     step implementations.  */
	  for (cnt = 0; cnt < nsteps; ++cnt)
	    {
	      size_t size;

	      /* Would have to be done if we would not clear the whole
                 array above.  */
#if 0
	      /* Reset the counter.  */
	      result->__data[cnt].__invocation_counter = 0;

	      /* It's a regular use.  */
	      result->__data[cnt].__internal_use = 0;
#endif

	      /* We use the `mbstate_t' member in DATA.  */
	      result->__data[cnt].__statep = &result->__data[cnt].__state;

	      /* Now see whether we can use any of the transliteration
		 modules for this step.  */
	      for (runp = trans; runp != NULL; runp = runp->next)
		for (n = 0; n < runp->ncsnames; ++n)
		  if (strcasecmp (steps[cnt].__from_name, runp->csnames[n]) == 0)
		    {
		      void *data = NULL;

		      /* Match!  Now try the initializer.  */
		      if (runp->trans_init_fct == NULL
			  || (runp->trans_init_fct (&data,
						    steps[cnt].__to_name)
			      == __GCONV_OK))
			{
			  /* Append at the end of the list.  */
			  struct __gconv_trans_data *newp;
			  struct __gconv_trans_data **lastp;

			  newp = (struct __gconv_trans_data *)
			    malloc (sizeof (struct __gconv_trans_data));
			  if (newp == NULL)
			    {
			      res = __GCONV_NOMEM;
			      goto bail;
			    }

			  newp->__trans_fct = runp->trans_fct;
			  newp->__trans_context_fct = runp->trans_context_fct;
			  newp->__trans_end_fct = runp->trans_end_fct;
			  newp->__data = data;
			  newp->__next = NULL;

			  lastp = &result->__data[cnt].__trans;
			  while (*lastp != NULL)
			    lastp = &(*lastp)->__next;

			  *lastp = newp;
			}
		      break;
		    }

	      /* If this is the last step we must not allocate an
		 output buffer.  */
	      if (cnt < nsteps - 1)
		{
		  result->__data[cnt].__flags = conv_flags;

		  /* Allocate the buffer.  */
		  size = (GCONV_NCHAR_GOAL * steps[cnt].__max_needed_to);

		  result->__data[cnt].__outbuf = (char *) malloc (size);
		  if (result->__data[cnt].__outbuf == NULL)
		    {
		      res = __GCONV_NOMEM;
		      goto bail;
		    }

		  result->__data[cnt].__outbufend =
		    result->__data[cnt].__outbuf + size;
		}
	      else
		{
		  /* Handle the last entry.  */
		  result->__data[cnt].__flags = conv_flags | __GCONV_IS_LAST;

		  break;
		}
	    }
	}

      if (res != __GCONV_OK)
	{
	  /* Something went wrong.  Free all the resources.  */
	  int serrno;
	bail:
	  serrno = errno;

	  if (result != NULL)
	    {
	      while (cnt-- > 0)
		{
		  struct __gconv_trans_data *transp;

		  transp = result->__data[cnt].__trans;
		  while (transp != NULL)
		    {
		      struct __gconv_trans_data *curp = transp;
		      transp = transp->__next;

		      if (__builtin_expect (curp->__trans_end_fct != NULL, 0))
			curp->__trans_end_fct (curp->__data);

		      free (curp);
		    }

		  free (result->__data[cnt].__outbuf);
		}

	      free (result);
	      result = NULL;
	    }

	  __gconv_close_transform (steps, nsteps);

	  __set_errno (serrno);
	}
    }

  *handle = result;
  setlocale(LC_ALL, old_locale);
  return res;
}

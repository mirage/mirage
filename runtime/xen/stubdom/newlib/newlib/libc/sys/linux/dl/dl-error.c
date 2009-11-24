/* Error handling for runtime dynamic linker.
   Copyright (C) 1995,96,97,98,99,2000,2001 Free Software Foundation, Inc.
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

#include <libintl.h>
#include <setjmp.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ldsodefs.h>
#include <sys/libc-tsd.h>

/* This structure communicates state between _dl_catch_error and
   _dl_signal_error.  */
struct catch
  {
    const char *objname;	/* Object/File name.  */
    const char *errstring;	/* Error detail filled in here.  */
    jmp_buf env;		/* longjmp here on error.  */
  };

/* Multiple threads at once can use the `_dl_catch_error' function.  The
   calls can come from `_dl_map_object_deps', `_dlerror_run', or from
   any of the libc functionality which loads dynamic objects (NSS, iconv).
   Therefore we have to be prepared to save the state in thread-local
   memory.  */

__libc_tsd_define (static, DL_ERROR)
#define tsd_getspecific()	__libc_tsd_get (DL_ERROR)
#define tsd_setspecific(data)	__libc_tsd_set (DL_ERROR, (data))


/* This message we return as a last resort.  We define the string in a
   variable since we have to avoid freeing it and so have to enable
   a pointer comparison.  See below and in dlfcn/dlerror.c.  */
const char _dl_out_of_memory[] = "out of memory";


/* This points to a function which is called when an continuable error is
   received.  Unlike the handling of `catch' this function may return.
   The arguments will be the `errstring' and `objname'.

   Since this functionality is not used in normal programs (only in ld.so)
   we do not care about multi-threaded programs here.  We keep this as a
   global variable.  */
static receiver_fct receiver;


void
internal_function
_dl_signal_error (int errcode, const char *objname, const char *occation,
		  const char *errstring)
{
  struct catch *lcatch;

  if (! errstring)
    errstring = N_("DYNAMIC LINKER BUG!!!");

  lcatch = tsd_getspecific ();
  if (objname == NULL)
    objname = "";
  if (lcatch != NULL)
    {
      /* We are inside _dl_catch_error.  Return to it.  We have to
	 duplicate the error string since it might be allocated on the
	 stack.  The object name is always a string constant.  */
      size_t len_objname = strlen (objname) + 1;
      size_t len_errstring = strlen (errstring) + 1;

      lcatch->errstring = (char *) malloc (len_objname + len_errstring);
      if (lcatch->errstring != NULL)
        {
          char *tmp;
          /* Make a copy of the object file name and the error string.  */
          tmp = memcpy ((char *) lcatch->errstring,
                           errstring, len_errstring);
          tmp += len_errstring;
          lcatch->objname = memcpy (tmp,
				  objname, len_objname);
        }
      else
	{
	  /* This is better than nothing.  */
	  lcatch->objname = "";
	  lcatch->errstring = _dl_out_of_memory;
	}
      longjmp (lcatch->env, errcode ?: -1);
    }
  else
    {
      /* Lossage while resolving the program's own symbols is always fatal.  */
      char buffer[1024];
      _dl_fatal_printf ("%s: %s: %s%s%s%s%s\n",
			_dl_argv[0] ?: "<program name unknown>",
			occation ?: N_("error while loading shared libraries"),
			objname, *objname ? ": " : "",
			errstring, errcode ? ": " : "",
			(errcode
			 ? __strerror_r (errcode, buffer, sizeof buffer)
			 : ""));
    }
}


void
internal_function
_dl_signal_cerror (int errcode, const char *objname, const char *occation,
		   const char *errstring)
{
  if (receiver)
    {
      /* We are inside _dl_receive_error.  Call the user supplied
	 handler and resume the work.  The receiver will still be
	 installed.  */
      (*receiver) (errcode, objname, errstring);
    }
  else
    _dl_signal_error (errcode, objname, occation, errstring);
}


int
internal_function
_dl_catch_error (const char **objname, const char **errstring,
		 void (*operate) (void *), void *args)
{
  int errcode;
  struct catch *volatile old;
  struct catch c;
  /* We need not handle `receiver' since setting a `catch' is handled
     before it.  */

  /* Some systems (e.g., SPARC) handle constructors to local variables
     inefficient.  So we initialize `c' by hand.  */
  c.errstring = NULL;

  old = tsd_getspecific ();
  errcode = setjmp (c.env);
  if (__builtin_expect (errcode, 0) == 0)
    {
      tsd_setspecific (&c);
      (*operate) (args);
      tsd_setspecific (old);
      *objname = NULL;
      *errstring = NULL;
      return 0;
    }

  /* We get here only if we longjmp'd out of OPERATE.  */
  tsd_setspecific (old);
  *objname = c.objname;
  *errstring = c.errstring;
  return errcode == -1 ? 0 : errcode;
}

void
internal_function
_dl_receive_error (receiver_fct fct, void (*operate) (void *), void *args)
{
  struct catch *old_catch;
  receiver_fct old_receiver;

  old_catch = tsd_getspecific ();
  old_receiver = receiver;

  /* Set the new values.  */
  tsd_setspecific (NULL);
  receiver = fct;

  (*operate) (args);

  tsd_setspecific (old_catch);
  receiver = old_receiver;
}

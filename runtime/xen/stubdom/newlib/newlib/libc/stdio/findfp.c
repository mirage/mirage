/*
 * Copyright (c) 1990 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Berkeley.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */
/* No user fns here.  Pesch 15apr92. */

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <sys/lock.h>
#include "local.h"

#ifdef _REENT_SMALL
const struct __sFILE_fake __sf_fake_stdin =
    {_NULL, 0, 0, 0, 0, {_NULL, 0}, 0, _NULL};
const struct __sFILE_fake __sf_fake_stdout =
    {_NULL, 0, 0, 0, 0, {_NULL, 0}, 0, _NULL};
const struct __sFILE_fake __sf_fake_stderr =
    {_NULL, 0, 0, 0, 0, {_NULL, 0}, 0, _NULL};
#endif

static _VOID
_DEFUN(std, (ptr, flags, file, data),
            FILE *ptr _AND
            int flags _AND
            int file  _AND
            struct _reent *data)
{
  ptr->_p = 0;
  ptr->_r = 0;
  ptr->_w = 0;
  ptr->_flags = flags;
  ptr->_file = file;
  ptr->_bf._base = 0;
  ptr->_bf._size = 0;
  ptr->_lbfsize = 0;
  ptr->_cookie = ptr;
  ptr->_read = __sread;
#ifndef __LARGE64_FILES
  ptr->_write = __swrite;
#else /* __LARGE64_FILES */
  ptr->_write = __swrite64;
  ptr->_seek64 = __sseek64;
  ptr->_flags |= __SL64;
#endif /* __LARGE64_FILES */
  ptr->_seek = __sseek;
  ptr->_close = __sclose;
#if !defined(__SINGLE_THREAD__) && !defined(_REENT_SMALL)
  __lock_init_recursive (ptr->_lock);
  /*
   * #else
   * lock is already initialized in __sfp
   */
#endif

#ifdef __SCLE
  if (__stextmode (ptr->_file))
    ptr->_flags |= __SCLE;
#endif
}

struct _glue *
_DEFUN(__sfmoreglue, (d, n),
       struct _reent *d _AND
       register int n)
{
  struct _glue *g;
  FILE *p;

  g = (struct _glue *) _malloc_r (d, sizeof (*g) + n * sizeof (FILE));
  if (g == NULL)
    return NULL;
  p = (FILE *) (g + 1);
  g->_next = NULL;
  g->_niobs = n;
  g->_iobs = p;
  memset (p, 0, n * sizeof (FILE));
  return g;
}

/*
 * Find a free FILE for fopen et al.
 */

FILE *
_DEFUN(__sfp, (d),
       struct _reent *d)
{
  FILE *fp;
  int n;
  struct _glue *g;

  __sfp_lock_acquire ();

  if (!_GLOBAL_REENT->__sdidinit)
    __sinit (_GLOBAL_REENT);
  for (g = &_GLOBAL_REENT->__sglue;; g = g->_next)
    {
      for (fp = g->_iobs, n = g->_niobs; --n >= 0; fp++)
	if (fp->_flags == 0)
	  goto found;
      if (g->_next == NULL &&
	  (g->_next = __sfmoreglue (d, NDYNAMIC)) == NULL)
	break;
    }
  __sfp_lock_release ();
  d->_errno = ENOMEM;
  return NULL;

found:
  fp->_file = -1;		/* no file */
  fp->_flags = 1;		/* reserve this slot; caller sets real flags */
#ifndef __SINGLE_THREAD__
  __lock_init_recursive (fp->_lock);
#endif
  __sfp_lock_release ();

  fp->_p = NULL;		/* no current pointer */
  fp->_w = 0;			/* nothing to read or write */
  fp->_r = 0;
  fp->_bf._base = NULL;		/* no buffer */
  fp->_bf._size = 0;
  fp->_lbfsize = 0;		/* not line buffered */
  /* fp->_cookie = <any>; */	/* caller sets cookie, _read/_write etc */
  fp->_ub._base = NULL;		/* no ungetc buffer */
  fp->_ub._size = 0;
  fp->_lb._base = NULL;		/* no line buffer */
  fp->_lb._size = 0;

  return fp;
}

/*
 * exit() calls _cleanup() through *__cleanup, set whenever we
 * open or buffer a file.  This chicanery is done so that programs
 * that do not use stdio need not link it all in.
 *
 * The name `_cleanup' is, alas, fairly well known outside stdio.
 */

_VOID
_DEFUN(_cleanup_r, (ptr),
       struct _reent *ptr)
{
  _CAST_VOID _fwalk(ptr, fclose);
  /* _CAST_VOID _fwalk (ptr, fflush); */	/* `cheating' */
}

#ifndef _REENT_ONLY
_VOID
_DEFUN_VOID(_cleanup)
{
  _cleanup_r (_GLOBAL_REENT);
}
#endif

/*
 * __sinit() is called whenever stdio's internal variables must be set up.
 */

_VOID
_DEFUN(__sinit, (s),
       struct _reent *s)
{
  __sinit_lock_acquire ();

  if (s->__sdidinit)
    {
      __sinit_lock_release ();
      return;
    }

  /* make sure we clean up on exit */
  s->__cleanup = _cleanup_r;	/* conservative */
  s->__sdidinit = 1;

  s->__sglue._next = NULL;
#ifndef _REENT_SMALL
  s->__sglue._niobs = 3;
  s->__sglue._iobs = &s->__sf[0];
#else
  s->__sglue._niobs = 0;
  s->__sglue._iobs = NULL;
  s->_stdin = __sfp(s);
  s->_stdout = __sfp(s);
  s->_stderr = __sfp(s);
#endif

  std (s->_stdin,  __SRD, 0, s);

  /* On platforms that have true file system I/O, we can verify
     whether stdout is an interactive terminal or not, as part of
     __smakebuf on first use of the stream.  For all other platforms,
     we will default to line buffered mode here.  Technically, POSIX
     requires both stdin and stdout to be line-buffered, but tradition
     leaves stdin alone on systems without fcntl.  */
#ifdef HAVE_FCNTL
  std (s->_stdout, __SWR, 1, s);
#else
  std (s->_stdout, __SWR | __SLBF, 1, s);
#endif

  /* POSIX requires stderr to be opened for reading and writing, even
     when the underlying fd 2 is write-only.  */
  std (s->_stderr, __SRW | __SNBF, 2, s);

  __sinit_lock_release ();
}

#ifndef __SINGLE_THREAD__

__LOCK_INIT_RECURSIVE(static, __sfp_lock);
__LOCK_INIT_RECURSIVE(static, __sinit_lock);

_VOID
_DEFUN_VOID(__sfp_lock_acquire)
{
  __lock_acquire_recursive (__sfp_lock);
}

_VOID
_DEFUN_VOID(__sfp_lock_release)
{
  __lock_release_recursive (__sfp_lock);
}

_VOID
_DEFUN_VOID(__sinit_lock_acquire)
{
  __lock_acquire_recursive (__sinit_lock);
}

_VOID
_DEFUN_VOID(__sinit_lock_release)
{
  __lock_release_recursive (__sinit_lock);
}

/* Walkable file locking routine.  */
static int
_DEFUN(__fp_lock, (ptr),
       FILE * ptr)
{
  _flockfile (ptr);

  return 0;
}

/* Walkable file unlocking routine.  */
static int
_DEFUN(__fp_unlock, (ptr),
       FILE * ptr)
{
  _funlockfile (ptr);

  return 0;
}

_VOID
_DEFUN_VOID(__fp_lock_all)
{
  __sfp_lock_acquire ();

  _CAST_VOID _fwalk (_REENT, __fp_lock);
}

_VOID
_DEFUN_VOID(__fp_unlock_all)
{
  _CAST_VOID _fwalk (_REENT, __fp_unlock);

  __sfp_lock_release ();
}
#endif

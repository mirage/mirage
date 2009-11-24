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

/*
FUNCTION
<<setvbuf>>---specify file or stream buffering

INDEX
	setvbuf

ANSI_SYNOPSIS
	#include <stdio.h>
	int setvbuf(FILE *<[fp]>, char *<[buf]>,
	            int <[mode]>, size_t <[size]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int setvbuf(<[fp]>, <[buf]>, <[mode]>, <[size]>)
	FILE *<[fp]>;
	char *<[buf]>;
	int <[mode]>;
	size_t <[size]>;

DESCRIPTION
Use <<setvbuf>> to specify what kind of buffering you want for the
file or stream identified by <[fp]>, by using one of the following
values (from <<stdio.h>>) as the <[mode]> argument:

o+
o _IONBF
Do not use a buffer: send output directly to the host system for the
file or stream identified by <[fp]>.

o _IOFBF
Use full output buffering: output will be passed on to the host system
only when the buffer is full, or when an input operation intervenes.

o _IOLBF
Use line buffering: pass on output to the host system at every
newline, as well as when the buffer is full, or when an input
operation intervenes.
o-

Use the <[size]> argument to specify how large a buffer you wish.  You
can supply the buffer itself, if you wish, by passing a pointer to a
suitable area of memory as <[buf]>.  Otherwise, you may pass <<NULL>>
as the <[buf]> argument, and <<setvbuf>> will allocate the buffer.

WARNINGS
You may only use <<setvbuf>> before performing any file operation other
than opening the file.

If you supply a non-null <[buf]>, you must ensure that the associated
storage continues to be available until you close the stream
identified by <[fp]>.

RETURNS
A <<0>> result indicates success, <<EOF>> failure (invalid <[mode]> or
<[size]> can cause failure).

PORTABILITY
Both ANSI C and the System V Interface Definition (Issue 2) require
<<setvbuf>>. However, they differ on the meaning of a <<NULL>> buffer
pointer: the SVID issue 2 specification says that a <<NULL>> buffer
pointer requests unbuffered output.  For maximum portability, avoid
<<NULL>> buffer pointers.

Both specifications describe the result on failure only as a
nonzero value.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <stdio.h>
#include <stdlib.h>
#include "local.h"

/*
 * Set one of the three kinds of buffering, optionally including a buffer.
 */

int
_DEFUN(setvbuf, (fp, buf, mode, size),
       register FILE * fp _AND
       char *buf          _AND
       register int mode  _AND
       register size_t size)
{
  int ret = 0;

  CHECK_INIT (_REENT, fp);

  _flockfile (fp);

  /*
   * Verify arguments.  The `int' limit on `size' is due to this
   * particular implementation.
   */

  if ((mode != _IOFBF && mode != _IOLBF && mode != _IONBF) || (int)(_POINTER_INT) size < 0)
    {
      _funlockfile (fp);
      return (EOF);
    }

  /*
   * Write current buffer, if any; drop read count, if any.
   * Make sure putc() will not think fp is line buffered.
   * Free old buffer if it was from malloc().  Clear line and
   * non buffer flags, and clear malloc flag.
   */

  _fflush_r (_REENT, fp);
  fp->_r = 0;
  fp->_lbfsize = 0;
  if (fp->_flags & __SMBF)
    _free_r (_REENT, (_PTR) fp->_bf._base);
  fp->_flags &= ~(__SLBF | __SNBF | __SMBF);

  if (mode == _IONBF)
    goto nbf;

  /*
   * Allocate buffer if needed. */
  if (buf == NULL)
    {
      /* we need this here because malloc() may return a pointer
	 even if size == 0 */
      if (!size) size = BUFSIZ;
      if ((buf = malloc (size)) == NULL)
	{
	  ret = EOF;
	  /* Try another size... */
	  buf = malloc (BUFSIZ);
	  size = BUFSIZ;
	}
      if (buf == NULL)
        {
          /* Can't allocate it, let's try another approach */
nbf:
          fp->_flags |= __SNBF;
          fp->_w = 0;
          fp->_bf._base = fp->_p = fp->_nbuf;
          fp->_bf._size = 1;
          _funlockfile (fp);
          return (ret);
        }
      fp->_flags |= __SMBF;
    }
  /*
   * Now put back whichever flag is needed, and fix _lbfsize
   * if line buffered.  Ensure output flush on exit if the
   * stream will be buffered at all.
   * If buf is NULL then make _lbfsize 0 to force the buffer
   * to be flushed and hence malloced on first use
   */

  switch (mode)
    {
    case _IOLBF:
      fp->_flags |= __SLBF;
      fp->_lbfsize = buf ? -size : 0;
      /* FALLTHROUGH */

    case _IOFBF:
      /* no flag */
      _REENT->__cleanup = _cleanup_r;
      fp->_bf._base = fp->_p = (unsigned char *) buf;
      fp->_bf._size = size;
      break;
    }

  /*
   * Patch up write count if necessary.
   */

  if (fp->_flags & __SWR)
    fp->_w = fp->_flags & (__SLBF | __SNBF) ? 0 : size;

  _funlockfile (fp);
  return 0;
}

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
<<fwrite>>---write array elements

INDEX
	fwrite
INDEX
	_fwrite_r

ANSI_SYNOPSIS
	#include <stdio.h>
	size_t fwrite(const void *<[buf]>, size_t <[size]>,
		      size_t <[count]>, FILE *<[fp]>);

	#include <stdio.h>
	size_t _fwrite_r(struct _reent *<[ptr]>, const void *<[buf]>, size_t <[size]>,
		      size_t <[count]>, FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	size_t fwrite(<[buf]>, <[size]>, <[count]>, <[fp]>)
	char *<[buf]>;
	size_t <[size]>;
	size_t <[count]>;
	FILE *<[fp]>;

	#include <stdio.h>
	size_t _fwrite_r(<[ptr]>, <[buf]>, <[size]>, <[count]>, <[fp]>)
	struct _reent *<[ptr]>;
	char *<[buf]>;
	size_t <[size]>;
	size_t <[count]>;
	FILE *<[fp]>;

DESCRIPTION
<<fwrite>> attempts to copy, starting from the memory location
<[buf]>, <[count]> elements (each of size <[size]>) into the file or
stream identified by <[fp]>.  <<fwrite>> may copy fewer elements than
<[count]> if an error intervenes.

<<fwrite>> also advances the file position indicator (if any) for
<[fp]> by the number of @emph{characters} actually written.

<<_fwrite_r>> is simply the reentrant version of <<fwrite>> that
takes an additional reentrant structure argument: <[ptr]>.

RETURNS
If <<fwrite>> succeeds in writing all the elements you specify, the
result is the same as the argument <[count]>.  In any event, the
result is the number of complete elements that <<fwrite>> copied to
the file.

PORTABILITY
ANSI C requires <<fwrite>>.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

#include <_ansi.h>
#include <stdio.h>
#include <string.h>
#if 0
#include <sys/stdc.h>
#endif
#include "local.h"
#if 1
#include "fvwrite.h"
#endif

/*
 * Write `count' objects (each size `size') from memory to the given file.
 * Return the number of whole objects written.
 */

size_t
_DEFUN(_fwrite_r, (ptr, buf, size, count, fp),
       struct _reent * ptr _AND
       _CONST _PTR buf _AND
       size_t size     _AND
       size_t count    _AND
       FILE * fp)
{
  size_t n;
  struct __suio uio;
  struct __siov iov;

  iov.iov_base = buf;
  uio.uio_resid = iov.iov_len = n = count * size;
  uio.uio_iov = &iov;
  uio.uio_iovcnt = 1;

  /*
   * The usual case is success (__sfvwrite_r returns 0);
   * skip the divide if this happens, since divides are
   * generally slow and since this occurs whenever size==0.
   */

  CHECK_INIT(ptr, fp);

  _flockfile (fp);
  if (__sfvwrite_r (ptr, fp, &uio) == 0)
    {
      _funlockfile (fp);
      return count;
    }
  _funlockfile (fp);
  return (n - uio.uio_resid) / size;
}

#ifndef _REENT_ONLY
size_t
_DEFUN(fwrite, (buf, size, count, fp),
       _CONST _PTR buf _AND
       size_t size     _AND
       size_t count    _AND
       FILE * fp)
{
  return _fwrite_r (_REENT, buf, size, count, fp);
}
#endif

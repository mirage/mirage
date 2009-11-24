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
<<fsetpos>>---restore position of a stream or file

INDEX
	fsetpos
INDEX
	_fsetpos_r

ANSI_SYNOPSIS
	#include <stdio.h>
	int fsetpos(FILE *<[fp]>, const fpos_t *<[pos]>);
	int _fsetpos_r(struct _reent *<[ptr]>, FILE *<[fp]>, l
	               const fpos_t *<[pos]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int fsetpos(<[fp]>, <[pos]>)
	FILE *<[fp]>;
	fpos_t *<[pos]>;

	int _fsetpos_r(<[ptr]>, <[fp]>, <[pos]>)
	struct _reent *<[ptr]>;
	FILE *<[fp]>;
	fpos_t *<[pos]>;

DESCRIPTION
Objects of type <<FILE>> can have a ``position'' that records how much
of the file your program has already read.  Many of the <<stdio>> functions
depend on this position, and many change it as a side effect.

You can use <<fsetpos>> to return the file identified by <[fp]> to a previous
position <<*<[pos]>>> (after first recording it with <<fgetpos>>).

See <<fseek>> for a similar facility.

RETURNS
<<fgetpos>> returns <<0>> when successful.  If <<fgetpos>> fails, the
result is <<1>>.  The reason for failure is indicated in <<errno>>:
either <<ESPIPE>> (the stream identified by <[fp]> doesn't support
repositioning) or <<EINVAL>> (invalid file position).

PORTABILITY
ANSI C requires <<fsetpos>>, but does not specify the nature of
<<*<[pos]>>> beyond identifying it as written by <<fgetpos>>.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>

int
_DEFUN(_fsetpos_r, (ptr, iop, pos),
       struct _reent * ptr _AND
       FILE * iop          _AND
       _CONST _fpos_t * pos)
{
  int x = _fseek_r (ptr, iop, *pos, SEEK_SET);

  if (x != 0)
    return 1;
  return 0;
}

#ifndef _REENT_ONLY

int
_DEFUN(fsetpos, (iop, pos),
       FILE * iop _AND
       _CONST _fpos_t * pos)
{
  return _fsetpos_r (_REENT, iop, pos);
}

#endif /* !_REENT_ONLY */

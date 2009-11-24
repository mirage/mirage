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
<<fgetpos>>---record position in a stream or file

INDEX
	fgetpos
INDEX
	_fgetpos_r

ANSI_SYNOPSIS
	#include <stdio.h>
	int fgetpos(FILE *<[fp]>, fpos_t *<[pos]>);
	int _fgetpos_r(struct _reent *<[ptr]>, FILE *<[fp]>, fpos_t *<[pos]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int fgetpos(<[fp]>, <[pos]>)
	FILE *<[fp]>;
	fpos_t *<[pos]>;

	int _fgetpos_r(<[ptr]>, <[fp]>, <[pos]>)
	struct _reent *<[ptr]>;
	FILE *<[fp]>;
	fpos_t *<[pos]>;

DESCRIPTION
Objects of type <<FILE>> can have a ``position'' that records how much
of the file your program has already read.  Many of the <<stdio>> functions
depend on this position, and many change it as a side effect.

You can use <<fgetpos>> to report on the current position for a file
identified by <[fp]>; <<fgetpos>> will write a value
representing that position at <<*<[pos]>>>.  Later, you can
use this value with <<fsetpos>> to return the file to this
position.

In the current implementation, <<fgetpos>> simply uses a character
count to represent the file position; this is the same number that
would be returned by <<ftell>>.

RETURNS
<<fgetpos>> returns <<0>> when successful.  If <<fgetpos>> fails, the
result is <<1>>.  Failure occurs on streams that do not support
positioning; the global <<errno>> indicates this condition with the
value <<ESPIPE>>.

PORTABILITY
<<fgetpos>> is required by the ANSI C standard, but the meaning of the
value it records is not specified beyond requiring that it be
acceptable as an argument to <<fsetpos>>.  In particular, other
conforming C implementations may return a different result from
<<ftell>> than what <<fgetpos>> writes at <<*<[pos]>>>.

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>

int
_DEFUN(_fgetpos_r, (ptr, fp, pos),
       struct _reent * ptr _AND
       FILE * fp           _AND
       _fpos_t * pos)
{
  *pos = _ftell_r (ptr, fp);

  if (*pos != -1)
    {
      return 0;
    }
  return 1;
}

#ifndef _REENT_ONLY

int
_DEFUN(fgetpos, (fp, pos),
       FILE * fp _AND
       _fpos_t * pos)
{
  return _fgetpos_r (_REENT, fp, pos);
}

#endif /* !_REENT_ONLY */

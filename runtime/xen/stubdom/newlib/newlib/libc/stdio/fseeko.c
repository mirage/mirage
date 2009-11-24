/*
 * Copyright (c) 2002, Red Hat Inc.
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

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>

int
_DEFUN(_fseeko_r, (ptr, fp, offset, whence),
       struct _reent *ptr _AND
       register FILE *fp  _AND
       _off_t offset      _AND
       int whence)
{
  return _fseek_r (ptr, fp, (long)offset, whence);
}

#ifndef _REENT_ONLY

int
_DEFUN(fseeko, (fp, offset, whence),
       register FILE *fp _AND
       _off_t offset     _AND
       int whence)
{
  /* for now we simply cast since off_t should be long */
  return _fseek_r (_REENT, fp, (long)offset, whence);
}

#endif /* !_REENT_ONLY */

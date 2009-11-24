/* read for MMIXware.

   Copyright (C) 2001 Hans-Peter Nilsson

   Permission to use, copy, modify, and distribute this software is
   freely granted, provided that the above copyright notice, this notice
   and the following disclaimer are preserved with no changes.

   THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE.  */

#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "sys/syscall.h"
#include <errno.h>

int
_read (int file,
       char *ptr,
       size_t len)
{
  long ret;

  if ((unsigned int) file >= 32 || _MMIX_allocated_filehandle[file] == 0)
    {
      errno = EBADF;
      return -1;
    }

  if (isatty(file))
    {
      ret = TRAP3f (SYS_Fgets, file, ptr, len);

      if (ret == -1)
        return 0;

      return ret;
    }

  ret = TRAP3f (SYS_Fread, file, ptr, len);

  /* Map the return codes:
     -1-len: an error.  We return -1.
     0: success.  We return len.
     n-len: end-of-file after n chars read.  We return n. */
  if (ret == 0)
    return len;

  if (ret == -1 - (long) len)
    {
      /* We don't know the nature of the failure, so this is an
	 approximation.  */
      errno = EIO;
      return -1;
    }

  return ret + len;
}

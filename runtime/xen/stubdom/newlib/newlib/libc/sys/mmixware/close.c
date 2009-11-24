/* close for MMIXware.

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
_close (int file)
{
  if ((unsigned int) file >= N_MMIX_FILEHANDLES
      || _MMIX_allocated_filehandle[file] == 0)
    {
      errno = EBADF;
      return -1;
    }

  _MMIX_allocated_filehandle[file] = 0;

  if (TRAP1f (SYS_Fclose, file) != 0)
    {
      errno = EIO;
      return -1;
    }
  return 0;
}

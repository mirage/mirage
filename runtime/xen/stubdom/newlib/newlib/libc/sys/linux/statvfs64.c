/* Return information about the filesystem on which FILE resides.
   Copyright (C) 1998, 2000, 2001 Free Software Foundation, Inc.
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

#include <errno.h>
#include <sys/statvfs.h>
#include <stddef.h>
#include <string.h>
#include <machine/weakalias.h>

/* Return information about the filesystem on which FILE resides.  */
int
__statvfs64 (const char *file, struct statvfs64 *buf)
{
  struct statvfs buf32;

  if (statvfs (file, &buf32) < 0)
    return -1;

  buf->f_bsize = buf32.f_bsize;
  buf->f_frsize = buf32.f_frsize;
  buf->f_blocks = buf32.f_blocks;
  buf->f_bfree = buf32.f_bfree;
  buf->f_bavail = buf32.f_bavail;
  buf->f_files = buf32.f_files;
  buf->f_ffree = buf32.f_ffree;
  buf->f_favail = buf32.f_favail;
  buf->f_fsid = buf32.f_fsid;
  buf->f_flag = buf32.f_flag;
  buf->f_namemax = buf32.f_namemax;
  memcpy (buf->__f_spare, buf32.__f_spare, sizeof (buf32.__f_spare));

  return 0;
}
weak_alias (__statvfs64, statvfs64)

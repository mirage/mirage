/* Copyright (C) 1991, 1996, 1997, 2000, 2001 Free Software Foundation, Inc.
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

#define _GNU_SOURCE 1

#include <stddef.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <confstr.h>

/* If BUF is not NULL and LEN > 0, fill in at most LEN - 1 bytes
   of BUF with the value corresponding to NAME and zero-terminate BUF.
   Return the number of bytes required to hold NAME's entire value.  */
size_t
confstr (name, buf, len)
     int name;
     char *buf;
     size_t len;
{
  const char *string;
  size_t string_len;

  switch (name)
    {
    case _CS_PATH:
      {
	static const char cs_path[] = CS_PATH;
	string = cs_path;
	string_len = sizeof (cs_path);
      }
      break;

    case _CS_V6_WIDTH_RESTRICTED_ENVS:
      /* We have to return a newline-separated list of named of
	 programming environements in which the widths of blksize_t,
	 cc_t, mode_t, nfds_t, pid_t, ptrdiff_t, size_t, speed_t,
	 ssize_t, suseconds_t, tcflag_t, useconds_t, wchar_t, and
	 wint_t types are no greater than the width of type long.

	 Currently this means all environment which the system allows.  */
      {
	static const char restenvs[] =
#if _POSIX_V6_ILP32_OFF32 > 0
	"_POSIX_V6_ILP32_OFF32"
#endif
#if _POSIX_V6_ILP32_OFFBIG > 0
# if _POSIX_V6_ILP32_OFF32 > 0
	"\n"
# endif
	"_POSIX_V6_ILP32_OFFBIG"
#endif
#if _POSIX_V6_LP64_OFF64 > 0
# if _POSIX_V6_ILP32_OFF32 > 0 || _POSIX_V6_ILP32_OFFBIG > 0
	"\n"
# endif
	"_POSIX_V6_LP64_OFF64"
#endif
#if _POSIX_V6_LPBIG_OFFBIG > 0
# if _POSIX_V6_ILP32_OFF32 > 0 || _POSIX_V6_ILP32_OFFBIG > 0 \
     || _POSIX_V6_LP64_OFF64 > 0
	"\n"
# endif
	"_POSIX_V6_LPBIG_OFFBIG"
#endif
	  ;
	string = restenvs;
	string_len = sizeof (restenvs);
      }
      break;

    case _CS_XBS5_ILP32_OFFBIG_CFLAGS:
    case _CS_POSIX_V6_ILP32_OFFBIG_CFLAGS:
    case _CS_LFS_CFLAGS:
#if _XBS5_LP64_OFF64 == -1 && _XBS5_LPBIG_OFFBIG == -1 && _XBS5_ILP32_OFFBIG == 1
      /* Signal that we want the new ABI.  */
      {
	static const char file_offset[] = "-D_FILE_OFFSET_BITS=64";
	string = file_offset;
	string_len = sizeof (file_offset);
      }
      break;
#endif
      /* FALLTHROUGH */

    case _CS_LFS_LINTFLAGS:
    case _CS_LFS_LDFLAGS:
    case _CS_LFS_LIBS:
    case _CS_LFS64_CFLAGS:
    case _CS_LFS64_LINTFLAGS:
    case _CS_LFS64_LDFLAGS:
    case _CS_LFS64_LIBS:

    case _CS_XBS5_ILP32_OFF32_CFLAGS:
    case _CS_XBS5_ILP32_OFF32_LDFLAGS:
    case _CS_XBS5_ILP32_OFF32_LIBS:
    case _CS_XBS5_ILP32_OFF32_LINTFLAGS:
    case _CS_XBS5_ILP32_OFFBIG_LDFLAGS:
    case _CS_XBS5_ILP32_OFFBIG_LIBS:
    case _CS_XBS5_ILP32_OFFBIG_LINTFLAGS:
    case _CS_XBS5_LP64_OFF64_CFLAGS:
    case _CS_XBS5_LP64_OFF64_LDFLAGS:
    case _CS_XBS5_LP64_OFF64_LIBS:
    case _CS_XBS5_LP64_OFF64_LINTFLAGS:
    case _CS_XBS5_LPBIG_OFFBIG_CFLAGS:
    case _CS_XBS5_LPBIG_OFFBIG_LDFLAGS:
    case _CS_XBS5_LPBIG_OFFBIG_LIBS:
    case _CS_XBS5_LPBIG_OFFBIG_LINTFLAGS:

    case _CS_POSIX_V6_ILP32_OFF32_CFLAGS:
    case _CS_POSIX_V6_ILP32_OFF32_LDFLAGS:
    case _CS_POSIX_V6_ILP32_OFF32_LIBS:
    case _CS_POSIX_V6_ILP32_OFF32_LINTFLAGS:
    case _CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS:
    case _CS_POSIX_V6_ILP32_OFFBIG_LIBS:
    case _CS_POSIX_V6_ILP32_OFFBIG_LINTFLAGS:
    case _CS_POSIX_V6_LP64_OFF64_CFLAGS:
    case _CS_POSIX_V6_LP64_OFF64_LDFLAGS:
    case _CS_POSIX_V6_LP64_OFF64_LIBS:
    case _CS_POSIX_V6_LP64_OFF64_LINTFLAGS:
    case _CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS:
    case _CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS:
    case _CS_POSIX_V6_LPBIG_OFFBIG_LIBS:
    case _CS_POSIX_V6_LPBIG_OFFBIG_LINTFLAGS:
      /* GNU libc does not require special actions to use LFS functions.  */
      string = "";
      string_len = 1;
      break;

    default:
      __set_errno (EINVAL);
      return 0;
    }

  if (len > 0 && buf != NULL)
    {
      if (string_len <= len)
	memcpy (buf, string, string_len);
      else
	{
	  memcpy (buf, string, len - 1);
	  buf[len - 1] = '\0';
	}
    }
  return string_len;
}

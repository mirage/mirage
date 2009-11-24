/* Linux specific extensions to fpathconf.
   Copyright (C) 1991,95,96,98,99,2000,2001 Free Software Foundation, Inc.
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

/* Modified for newlib July 19, 2002 by Jeff Johnston */

#include <errno.h>
#include <stddef.h>
#include <unistd.h>
#include <limits.h>
#include <sys/stat.h>
#include <sys/statfs.h>
#include <sys/statvfs.h>
#include <machine/weakalias.h>
#include "linux_fsinfo.h"

/* The Linux kernel header mentioned this as a kind of generic value.  */
#define LINUX_LINK_MAX	127

static long int posix_fpathconf (int fd, int name);

/* Get file-specific information about descriptor FD.  */
long int
__fpathconf (fd, name)
     int fd;
     int name;
{
  if (name == _PC_LINK_MAX)
    {
      struct statfs fsbuf;

      /* Determine the filesystem type.  */
      if (__fstatfs (fd, &fsbuf) < 0)
	{
	  if (errno == ENOSYS)
	    /* not possible, return the default value.  */
	    return LINUX_LINK_MAX;

	  /* Some error occured.  */
          return -1;
	}

      switch (fsbuf.f_type)
	{
	case EXT2_SUPER_MAGIC:
	  return EXT2_LINK_MAX;

	case MINIX_SUPER_MAGIC:
	case MINIX_SUPER_MAGIC2:
	  return MINIX_LINK_MAX;

	case MINIX2_SUPER_MAGIC:
	case MINIX2_SUPER_MAGIC2:
	  return MINIX2_LINK_MAX;

	case XENIX_SUPER_MAGIC:
	  return XENIX_LINK_MAX;

	case SYSV4_SUPER_MAGIC:
	case SYSV2_SUPER_MAGIC:
	  return SYSV_LINK_MAX;

	case COH_SUPER_MAGIC:
	  return COH_LINK_MAX;

	case UFS_MAGIC:
	case UFS_CIGAM:
	  return UFS_LINK_MAX;

	case REISERFS_SUPER_MAGIC:
	  return REISERFS_LINK_MAX;

	default:
	  return LINUX_LINK_MAX;
	}
    }

  return posix_fpathconf (fd, name);
}

/* Get file-specific information about descriptor FD.  */
static long int
posix_fpathconf (fd, name)
     int fd;
     int name;
{
  if (fd < 0)
    {
      __set_errno (EBADF);
      return -1;
    }

  switch (name)
    {
    default:
      __set_errno (EINVAL);
      return -1;

    case _PC_LINK_MAX:
#ifdef	LINK_MAX
      return LINK_MAX;
#else
      return -1;
#endif

    case _PC_MAX_CANON:
#ifdef	MAX_CANON
      return MAX_CANON;
#else
      return -1;
#endif

    case _PC_MAX_INPUT:
#ifdef	MAX_INPUT
      return MAX_INPUT;
#else
      return -1;
#endif

    case _PC_NAME_MAX:
#ifdef	NAME_MAX
      {
	struct statfs buf;
	int save_errno = errno;

	if (__fstatfs (fd, &buf) < 0)
	  {
	    if (errno == ENOSYS)
	      {
		__set_errno (save_errno);
		return NAME_MAX;
	      }
	    else if (errno == ENODEV)
	      __set_errno (EINVAL);

	    return -1;
	  }
	else
	  {
#ifdef _STATFS_F_NAMELEN
	    return buf.f_namelen;
#else
# ifdef _STATFS_F_NAME_MAX
	    return buf.f_name_max;
# else
	    return NAME_MAX;
# endif
#endif
	  }
      }
#else
      return -1;
#endif

    case _PC_PATH_MAX:
#ifdef	PATH_MAX
      return PATH_MAX;
#else
      return -1;
#endif

    case _PC_PIPE_BUF:
#ifdef	PIPE_BUF
      return PIPE_BUF;
#else
      return -1;
#endif

    case _PC_CHOWN_RESTRICTED:
#ifdef	_POSIX_CHOWN_RESTRICTED
      return _POSIX_CHOWN_RESTRICTED;
#else
      return -1;
#endif

    case _PC_NO_TRUNC:
#ifdef	_POSIX_NO_TRUNC
      return _POSIX_NO_TRUNC;
#else
      return -1;
#endif

    case _PC_VDISABLE:
#ifdef	_POSIX_VDISABLE
      return _POSIX_VDISABLE;
#else
      return -1;
#endif

    case _PC_SYNC_IO:
#ifdef	_POSIX_SYNC_IO
      return _POSIX_SYNC_IO;
#else
      return -1;
#endif

    case _PC_ASYNC_IO:
#ifdef	_POSIX_ASYNC_IO
      {
	/* AIO is only allowed on regular files and block devices.  */
	struct stat64 st;

	if (fstat64 (fd, &st) < 0
	    || (! S_ISREG (st.st_mode) && ! S_ISBLK (st.st_mode)))
	  return -1;
	else
	  return 1;
      }
#else
      return -1;
#endif

    case _PC_PRIO_IO:
#ifdef	_POSIX_PRIO_IO
      return _POSIX_PRIO_IO;
#else
      return -1;
#endif

    case _PC_SOCK_MAXBUF:
#ifdef	SOCK_MAXBUF
      return SOCK_MAXBUF;
#else
      return -1;
#endif

    case _PC_FILESIZEBITS:
#ifdef FILESIZEBITS
      return FILESIZEBITS;
#else
      /* We let platforms with larger file sizes overwrite this value.  */
      return 32;
#endif

    case _PC_REC_INCR_XFER_SIZE:
      /* XXX It is not entirely clear what the limit is supposed to do.
	 What is incremented?  */
      return -1;

    case _PC_REC_MAX_XFER_SIZE:
      /* XXX It is not entirely clear what the limit is supposed to do.
	 In general there is no top limit of the number of bytes which
	 case be transported at once.  */
      return -1;

    case _PC_REC_MIN_XFER_SIZE:
      {
	/* XXX It is not entirely clear what the limit is supposed to do.
	   I assume this is the block size of the filesystem.  */
	struct statvfs64 sv;

	if (__fstatvfs64 (fd, &sv) < 0)
	  return -1;
	return sv.f_bsize;
      }

    case _PC_REC_XFER_ALIGN:
      {
	/* XXX It is not entirely clear what the limit is supposed to do.
	   I assume that the number should reflect the minimal block
	   alignment.  */
	struct statvfs64 sv;

	if (__fstatvfs64 (fd, &sv) < 0)
	  return -1;
	return sv.f_frsize;
      }

    case _PC_ALLOC_SIZE_MIN:
      {
	/* XXX It is not entirely clear what the limit is supposed to do.
	   I assume that the number should reflect the minimal block
	   alignment.  */
	struct statvfs64 sv;

	if (__fstatvfs64 (fd, &sv) < 0)
	  return -1;
	return sv.f_frsize;
      }

    case _PC_SYMLINK_MAX:
      /* In general there are no limits.  If a system has one it should
	 overwrite this case.  */
      return -1;
    }
}

weak_alias (__fpathconf, fpathconf)

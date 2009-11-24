/* Copyright (C) 1991,92,93,1995-1999,2000,2001 Free Software Foundation, Inc.
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
#include <limits.h>
#include <stddef.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <machine/weakalias.h>

static int getttyname_r (char *buf, size_t buflen,
			 dev_t mydev, ino64_t myino, int save,
			 int *dostat);

extern struct dirent64 *__readdir64 (DIR *);

static int
getttyname_r (char *buf, size_t buflen, dev_t mydev, ino64_t myino,
	      int save, int *dostat)
{
  struct stat64 st;
  DIR *dirstream;
  struct dirent64 *d;
  size_t devlen = strlen (buf);

  dirstream = opendir (buf);
  if (dirstream == NULL)
    {
      *dostat = -1;
      return errno;
    }

  while ((d = __readdir64 (dirstream)) != NULL)
    {
      if ((d->d_ino == myino || *dostat)
          && strcmp (d->d_name, "stdin")
	  && strcmp (d->d_name, "stdout")
	  && strcmp (d->d_name, "stderr"))
        {
	  size_t needed = strlen (d->d_name) + 1;

	  if (needed > buflen)
	    {
	      *dostat = -1;
	      (void) closedir (dirstream);
	      __set_errno (ERANGE);
	      return ERANGE;
	    }

	  strncpy (buf + devlen, d->d_name, needed);

	  if (stat64 (buf, &st) == 0
#ifdef _STATBUF_ST_RDEV
	      && S_ISCHR (st.st_mode) && st.st_rdev == mydev
#else
	      && d->d_ino == myino && st.st_dev == mydev
#endif
	     )
	    {
	      (void) closedir (dirstream);
	      __set_errno (save);
	      return 0;
	    }
        }
    }

  (void) closedir (dirstream);
  __set_errno (save);
  /* It is not clear what to return in this case.  `isatty' says FD
     refers to a TTY but no entry in /dev has this inode.  */
  return ENOTTY;
}

/* Store at most BUFLEN character of the pathname of the terminal FD is
   open on in BUF.  Return 0 on success,  otherwise an error number.  */
int
__ttyname_r (int fd, char *buf, size_t buflen)
{
  char procname[30];
  struct stat64 st, st1;
  int dostat = 0;
  int save = errno;
  int ret;

  /* Test for the absolute minimal size.  This makes life easier inside
     the loop.  */
  if (!buf)
    {
      __set_errno (EINVAL);
      return EINVAL;
    }

  if (buflen < sizeof ("/dev/pts/"))
    {
      __set_errno (ERANGE);
      return ERANGE;
    }

  if (!isatty (fd))
    {
      __set_errno (ENOTTY);
      return ENOTTY;
    }

  /* We try using the /proc filesystem.  */
  sprintf (procname, "/proc/self/fd/%d", fd);

  ret = readlink (procname, buf, buflen - 1);
  if (ret != -1 && buf[0] != '[')
    {
      buf[ret] = '\0';
      return 0;
    }
  if (ret == -1 && errno == ENAMETOOLONG)
    {
      __set_errno (ERANGE);
      return ERANGE;
    }

  if (fstat64 (fd, &st) < 0)
    return errno;

  /* Prepare the result buffer.  */
  memcpy (buf, "/dev/pts/", sizeof ("/dev/pts/"));
  buflen -= sizeof ("/dev/pts/") - 1;

  if (stat64 (buf, &st1) == 0 && S_ISDIR (st1.st_mode))
    {
#ifdef _STATBUF_ST_RDEV
      ret = getttyname_r (buf, buflen, st.st_rdev, st.st_ino, save,
			  &dostat);
#else
      ret = getttyname_r (buf, buflen, st.st_dev, st.st_ino, save,
			  &dostat);
#endif
    }
  else
    {
      __set_errno (save);
      ret = ENOENT;
    }

  if (ret && dostat != -1)
    {
      buf[sizeof ("/dev/") - 1] = '\0';
      buflen += sizeof ("pts/") - 1;
#ifdef _STATBUF_ST_RDEV
      ret = getttyname_r (buf, buflen, st.st_rdev, st.st_ino, save,
			  &dostat);
#else
      ret = getttyname_r (buf, buflen, st.st_dev, st.st_ino, save,
			  &dostat);
#endif
    }

  if (ret && dostat != -1)
    {
      buf[sizeof ("/dev/") - 1] = '\0';
      dostat = 1;
#ifdef _STATBUF_ST_RDEV
      ret = getttyname_r (buf, buflen, st.st_rdev, st.st_ino,
			  save, &dostat);
#else
      ret = getttyname_r (buf, buflen, st.st_dev, st.st_ino,
			  save, &dostat);
#endif
    }

  return ret;
}

weak_alias (__ttyname_r, ttyname_r)

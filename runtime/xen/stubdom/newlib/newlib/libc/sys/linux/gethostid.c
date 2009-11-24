/* Copyright (C) 1995,1996,1998,1999,2000,2001 Free Software Foundation, Inc.
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

#include <alloca.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <netdb.h>

#define HOSTIDFILE "/etc/hostid"
#define OLD_HOSTIDFILE "/etc/hostid"

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 2
# define OPEN __open64
#else
# define OPEN __open
#endif

#ifdef SET_PROCEDURE
int
sethostid (id)
     long int id;
{
  int fd;
  ssize_t written;

  /* Open file for writing.  Everybody is allowed to read this file.  */
  fd = OPEN (HOSTIDFILE, O_CREAT|O_WRONLY|O_TRUNC, 0644);
  if (fd < 0)
    return -1;

  written = __write (fd, &id, sizeof (id));

  __close (fd);

  return written != sizeof (id) ? -1 : 0;
}

#else
# include <string.h>
# include <sys/param.h>
# include <netdb.h>
# include <netinet/in.h>

long int
gethostid ()
{
  char hostname[MAXHOSTNAMELEN + 1];
  size_t buflen;
  char *buffer;
  struct hostent hostbuf, *hp;
  unsigned long int id;
  struct in_addr in;
  int herr;
  int fd;

  /* First try to get the ID from a former invocation of sethostid.  */
  fd = OPEN (HOSTIDFILE, O_RDONLY);
  if (fd >= 0)
    {
      ssize_t n = __read (fd, &id, sizeof (id));

      __close (fd);

      if (n == sizeof (id))
	return id;
    }

  /* Getting from the file was not successful.  An intelligent guess for
     a unique number of a host is its IP address.  Return this.  */
  if (__gethostname (hostname, MAXHOSTNAMELEN) < 0 || hostname[0] == '\0')
    /* This also fails.  Return and arbitrary value.  */
    return 0;

  buflen = 1024;
  buffer = alloca (buflen);

  /* To get the IP address we need to know the host name.  */
  while (__gethostbyname_r (hostname, &hostbuf, buffer, buflen, &hp, &herr)
	 != 0
	 || hp == NULL)
    if (herr != NETDB_INTERNAL || errno != ERANGE)
      return 0;
    else
      {
	/* Enlarge buffer.  */
	buflen *= 2;
	buffer = alloca (buflen);
      }

  in.s_addr = 0;
  memcpy (&in, hp->h_addr,
	  (int) sizeof (in) < hp->h_length ? sizeof (in) : hp->h_length);

  /* For the return value to be not exactly the IP address we do some
     bit fiddling.  */
  return in.s_addr << 16 | in.s_addr >> 16;
}
#endif

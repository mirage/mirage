/* Copyright (C) 1992, 1995, 1996, 1997, 1998 Free Software Foundation, Inc.
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

#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>

int main (int argc, char *argv[])
{
  char *buf = NULL;
  size_t size = 0;
  ssize_t len;

  while ((len = getline (&buf, &size, stdin)) != -1)
    {
      printf ("bufsize %Zu; read %Zd: ", size, len);
      if (fwrite (buf, len, 1, stdout) != 1)
	{
	  perror ("fwrite");
	  return 1;
	}
    }

  if (ferror (stdin))
    {
      perror ("getline");
      return 1;
    }

  return 0;
}

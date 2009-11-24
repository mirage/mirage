/* Tests for non-unloading of libpthread.
   Copyright (C) 2000 Free Software Foundation, Inc.
   Contributed by Ulrich Drepper <drepper@redhat.com>, 2000.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with the GNU C Library; see the file COPYING.LIB.  If not,
   write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <gnu/lib-names.h>

int
main (void)
{
  void *p = dlopen (PREFIX LIBPTHREAD_SO, RTLD_LAZY);

  if (p == NULL)
    {
      puts ("failed to load " LIBPTHREAD_SO);
      exit (1);
    }

  if (dlclose (p) != 0)
    {
      puts ("dlclose (" LIBPTHREAD_SO ") failed");
      exit (1);
    }

  puts ("seems to work");

  exit (0);
}

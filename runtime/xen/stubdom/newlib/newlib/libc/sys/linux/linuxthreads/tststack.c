/* Tests for variable stack size handling.
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

#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

static void *f1 (void *);
static void *f2 (void *);

int
main (void)
{
  pthread_attr_t attr;
  pthread_t th1 = 0;
  pthread_t th2 = 0;
  void *res1;
  void *res2;

  pthread_attr_init (&attr);
  if (pthread_attr_setstacksize (&attr, 70*1024) != 0)
    {
      puts ("invalid stack size");
      return 1;
    }

  pthread_create (&th1, NULL, f1, NULL);
  pthread_create (&th2, &attr, f2, NULL);

  pthread_join (th1, &res1);
  pthread_join (th2, &res2);

  printf ("res1 = %p\n", res1);
  printf ("res2 = %p\n", res2);

  return res1 != (void *) 1 || res2 != (void *) 2;
}

static void *
f1 (void *parm)
{
  printf ("This is `%s'\n", __FUNCTION__);
  fflush (stdout);

  return (void *) 1;
}

static void *
f2 (void *parm)
{
  printf ("This is `%s'\n", __FUNCTION__);
  fflush (stdout);
  sleep (1);

  return (void *) 2;
}

/* sigset.c - signal set manipulation functions */

/* Copyright 2002, Red Hat Inc. */

/* Note: these are currently grouped together in one file so that
         it will override the default version in the libc/unix 
         directory which has grouped all functions in one file. */

/* sigaddset function */

#include <signal.h>
#include <bits/sigset.h>
#include <errno.h>
#include <string.h>
#include <machine/weakalias.h>

int
sigaddset (sigset_t *set, const int signo)
{
  int index, mask;
  __sigset_t *st = (__sigset_t *)set;

  if (signo > NSIG)
    {
      errno = EINVAL;
      return -1;
    }

  index = (signo - 1) / (8 * sizeof(long));
  mask = 1 << ((signo - 1) % (8 * sizeof(long)));

  st->__val[index] |= mask;
  return 0;
}

/* sigdelset function */

int
sigdelset (sigset_t *set, const int signo)
{
  int index, mask;
  __sigset_t *st = (__sigset_t *)set;

  if (signo > NSIG)
    {
      errno = EINVAL;
      return -1;
    }

  index = (signo - 1) / (8 * sizeof(long));
  mask = 1 << ((signo - 1) % (8 * sizeof(long)));

  st->__val[index] &= ~mask;
  return 0;
}

/* sigemptyset function */

int
sigemptyset (sigset_t *set)
{
  int size = NSIG / 8;
  __sigset_t *st = (__sigset_t *)set;
  memset (st->__val, 0, size);
  return 0;
}

/* sigfillset function */

int
sigfillset (sigset_t *set)
{
  int size = NSIG / 8;
  __sigset_t *st = (__sigset_t *)set;
  memset (st->__val, 0xff, size);
  return 0;
}

/* sigismember function */

int
sigismember (const sigset_t *set, int signo)
{
  int index, mask;
  __sigset_t *st = (__sigset_t *)set;

  if (signo > NSIG)
    {
      errno = EINVAL;
      return -1;
    }

  index = (signo - 1) / (8 * sizeof(long));
  mask = 1 << ((signo - 1) % (8 * sizeof(long)));

  return (st->__val[index] & mask) != 0;
}


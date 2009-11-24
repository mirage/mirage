#include <errno.h>
#include <error.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <ucontext.h>

#include "pt-machine.h"


#define N	4

#ifdef FLOATING_STACKS
static char stacks[N][8192];
static ucontext_t ctx[N][2];
static volatile int failures;

static void
fct (long int n)
{
  /* Just to use the thread local descriptor.  */
  printf ("%ld: in %s now\n", n, __FUNCTION__);
  errno = 0;
}

static void *
threadfct (void *arg)
{
  int n = (int) (long int) arg;

  if (getcontext (&ctx[n][1]) != 0)
    {
      printf ("%d: cannot get context: %m\n", n);
      exit (1);
    }

  printf ("%d: %s: before makecontext\n", n, __FUNCTION__);

  ctx[n][1].uc_stack.ss_sp = stacks[n];
  ctx[n][1].uc_stack.ss_size = 8192;
  ctx[n][1].uc_link = &ctx[n][0];
  makecontext (&ctx[n][1], (void (*) (void)) fct, 1, (long int) n);

  printf ("%d: %s: before swapcontext\n", n, __FUNCTION__);

  if (swapcontext (&ctx[n][0], &ctx[n][1]) != 0)
    {
      ++failures;
      printf ("%d: %s: swapcontext failed\n", n, __FUNCTION__);
    }
  else
    printf ("%d: back in %s\n", n, __FUNCTION__);

  return NULL;
}
#endif


#ifdef FLOATING_STACKS
static volatile int global;
#endif

int
main (void)
{
#ifndef FLOATING_STACKS
  puts ("not supported");
  return 0;
#else
  int n;
  pthread_t th[N];
  ucontext_t mctx;

  puts ("making contexts");
  if (getcontext (&mctx) != 0)
    {
      if (errno == ENOSYS)
	{
	  puts ("context handling not supported");
	  exit (0);
	}

      printf ("%s: getcontext: %m\n", __FUNCTION__);
      exit (1);
    }

  /* Play some tricks with this context.  */
  if (++global == 1)
    if (setcontext (&mctx) != 0)
      {
	printf ("%s: setcontext: %m\n", __FUNCTION__);
	exit (1);
      }
  if (global != 2)
    {
      printf ("%s: 'global' not incremented twice\n", __FUNCTION__);
      exit (1);
    }

  for (n = 0; n < N; ++n)
    if (pthread_create (&th[n], NULL, threadfct, (void *) n) != 0)
      error (EXIT_FAILURE, errno, "cannot create all threads");

  for (n = 0; n < N; ++n)
    pthread_join (th[n], NULL);

  return failures;
#endif
}

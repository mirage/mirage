/* Test case by Permaine Cheung <pcheung@cygnus.com>.  */

#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

static void *
sub1 (void *arg)
{
  /* Nothing.  */
  return NULL;
}

int
main (void)
{
  int istatus;
  int policy;
  int cnt;
  pthread_t thread1;
  struct sched_param spresult1, sp1;

  for (cnt = 0; cnt < 100; ++cnt)
    {
      printf ("Round %d\n", cnt);

      pthread_create (&thread1, NULL, &sub1, NULL);
      pthread_join (thread1, NULL);

      istatus = pthread_getschedparam (thread1, &policy, &spresult1);
      if (istatus != ESRCH)
	{
	  printf ("pthread_getschedparam returns: %d\n", istatus);
	  return 1;
	}

      sp1.__sched_priority = 0;
      istatus = pthread_setschedparam (thread1, SCHED_OTHER, &sp1);
      if (istatus != ESRCH)
	{
	  printf ("pthread_setschedparam returns: %d\n", istatus);
	  return 2;
	}
    }

  return 0;
}

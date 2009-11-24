/* Test of the error checking mutex and incidently also barriers.  */

#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>


static pthread_mutex_t locks[] =
{
  PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP,
  PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP,
  PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP,
  PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP,
  PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP
};
#define nlocks ((int) (sizeof (locks) / sizeof (locks[0])))

static pthread_barrier_t barrier;
#define SYNC pthread_barrier_wait (&barrier)

#define NTHREADS nlocks

#define ROUNDS 20


static void *
worker (void *arg)
{
  /* We are locking the and unlocked the locks and check the errors.
     Since we are using the error-checking variant the implementation
     should report them.  */
  int nr = (long int) arg;
  int i;
  void *result = NULL;
  int retval;

  for (i = 0; i < ROUNDS; ++i)
    {
      /* Skip the rounds which would make other == own.  */
      if (i % nlocks == 0)
	continue;

      /* Get the "own" mutex.  */
      if (pthread_mutex_trylock (&locks[nr]) != 0)
	{
	  printf ("thread %d failed getting own mutex\n", nr);
	  result = (void *) 1;
	}

      /* Try locking "own" mutex again.  */
      retval = pthread_mutex_lock (&locks[nr]);
      if (retval != EDEADLK)
	{
	  printf ("thread %d failed getting own mutex\n", nr);
	  result = (void *) 1;
	}

      /* Try to get a different semaphore.  */
      SYNC;
      retval = pthread_mutex_trylock (&locks[(nr + i) % nlocks]);
      if (retval != EBUSY)
	{
	  printf ("thread %d didn't deadlock on getting %d's lock\n",
		  nr, (nr + i) % nlocks);
	  result = (void *) 1;
	}

      /* Try unlocking other's lock.  */
      retval = pthread_mutex_unlock (&locks[(nr + i) % nlocks]);
      if (retval != EPERM)
	{
	  printf ("thread %d managed releasing mutex %d\n",
		  nr, (nr + i) % nlocks);
	  result = (void *) 1;
	}

      /* All lock one mutex now.  */
      SYNC;
      retval = pthread_mutex_lock (&locks[i % nlocks]);
      if (nr == (i % nlocks))
	{
	  if (retval != EDEADLK)
	    {
	      printf ("thread %d didn't deadlock on getting %d's lock\n",
		      nr, (nr + i) % nlocks);
	      result = (void *) 1;
	    }
	  if (pthread_mutex_unlock (&locks[i % nlocks]) != 0)
	    {
	      printf ("thread %d failed releasing own mutex\n", nr);
	      result = (void *) 1;
	    }
	}
      else
	{
	  if (retval != 0)
	    {
	      printf ("thread %d failed acquiring mutex %d\n",
		      nr, i % nlocks);
	      result = (void *) 1;
	    }
	  else if (pthread_mutex_unlock (&locks[i % nlocks]) != 0)
	    {
	      printf ("thread %d failed releasing mutex %d\n",
		      nr, i % nlocks);
	      result = (void *) 1;
	    }
	}

      /* Unlock the own lock.  */
      SYNC;
      if (nr != (i % nlocks) && pthread_mutex_unlock (&locks[nr]) != 0)
	{
	  printf ("thread %d failed releasing own mutex\n", nr);
	  result = (void *) 1;
	}

      /* Try unlocking again.  */
      retval = pthread_mutex_unlock (&locks[nr]);
      if (retval == 0)
	{
	  printf ("thread %d managed releasing own mutex twice\n", nr);
	  result = (void *) 1;
	}
    }

  return result;
}


#define TEST_FUNCTION do_test ()
static int
do_test (void)
{
  pthread_t threads[NTHREADS];
  int i;
  void *res;
  int result = 0;

  pthread_barrier_init (&barrier, NULL, NTHREADS);

  for (i = 0; i < NTHREADS; ++i)
    if (pthread_create (&threads[i], NULL, worker, (void *) (long int) i) != 0)
      {
	printf ("failed to create thread %d: %m\n", i);
	exit (1);
      }

  for (i = 0; i < NTHREADS; ++i)
    if (pthread_join (threads[i], &res) != 0 || res != NULL)
      result = 1;

  return result;
}

#include "../test-skeleton.c"

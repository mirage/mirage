/* Tests for cancelation handling.  */

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

int fd;

pthread_barrier_t bar;


static void
cleanup (void *arg)
{
  int nr = (int) (long int) arg;
  char s[30];
  char *cp = stpcpy (s, "cleanup ");
  *cp++ = '0' + nr;
  *cp++ = '\n';
  __libc_lseek (fd, 0, SEEK_END);
  __libc_write (fd, s, cp - s);
}


static void *
t1 (void *arg)
{
  pthread_cleanup_push (cleanup, (void *) (long int) 1);
  return NULL;
  pthread_cleanup_pop (0);
}


static void
inner (int a)
{
  pthread_cleanup_push (cleanup, (void *) (long int) a);
  if (a)
    return;
  pthread_cleanup_pop (0);
}


static void *
t2 (void *arg)
{
  pthread_cleanup_push (cleanup, (void *) (long int) 2);
  inner ((int) (long int) arg);
  return NULL;
  pthread_cleanup_pop (0);
}


/* This does not work yet.  */
volatile int cleanupokcnt;

static void
cleanupok (void *arg)
{
  ++cleanupokcnt;
}


static void *
t3 (void *arg)
{
  pthread_cleanup_push (cleanupok, (void *) (long int) 4);
  inner ((int) (long int) arg);
  pthread_exit (NULL);
  pthread_cleanup_pop (0);
}


static void
innerok (int a)
{
  pthread_cleanup_push (cleanupok, (void *) (long int) a);
  pthread_exit (NULL);
  pthread_cleanup_pop (0);
}


static void *
t4 (void *arg)
{
  pthread_cleanup_push (cleanupok, (void *) (long int) 6);
  innerok ((int) (long int) arg);
  pthread_cleanup_pop (0);
  return NULL;
}


int
main (int argc, char *argv[])
{
  pthread_t td;
  int err;
  char *tmp;
  const char *prefix;
  const char template[] = "thtstXXXXXX";
  struct stat64 st;
  int result = 0;

  prefix = argc > 1 ? argv[1] : "";
  tmp = (char *) alloca (strlen (prefix) + sizeof template);
  strcpy (stpcpy (tmp, prefix), template);

  fd = mkstemp (tmp);
  if (fd == -1)
    {
      printf ("cannot create temporary file: %m");
      exit (1);
    }
  unlink (tmp);

  err = pthread_barrier_init (&bar, NULL, 2);
  if (err != 0 )
    {
      printf ("cannot create barrier: %s\n", strerror (err));
      exit (1);
    }

#ifdef NOT_YET
  err = pthread_create (&td, NULL, t1, NULL);
  if (err != 0)
    {
      printf ("cannot create thread t1: %s\n", strerror (err));
      exit (1);
    }

  err = pthread_join (td, NULL);
  if (err != 0)
    {
      printf ("cannot join thread: %s\n", strerror (err));
      exit (1);
    }

  err = pthread_create (&td, NULL, t2, (void *) 3);
  if (err != 0)
    {
      printf ("cannot create thread t2: %s\n", strerror (err));
      exit (1);
    }

  err = pthread_join (td, NULL);
  if (err != 0)
    {
      printf ("cannot join thread: %s\n", strerror (err));
      exit (1);
    }

  err = pthread_create (&td, NULL, t3, (void *) 5);
  if (err != 0)
    {
      printf ("cannot create thread t3: %s\n", strerror (err));
      exit (1);
    }

  err = pthread_join (td, NULL);
  if (err != 0)
    {
      printf ("cannot join thread: %s\n", strerror (err));
      exit (1);
    }
#endif

  err = pthread_create (&td, NULL, t4, (void *) 7);
  if (err != 0)
    {
      printf ("cannot create thread t3: %s\n", strerror (err));
      exit (1);
    }

  err = pthread_join (td, NULL);
  if (err != 0)
    {
      printf ("cannot join thread: %s\n", strerror (err));
      exit (1);
    }

  if (fstat64 (fd, &st) < 0)
    {
      printf ("cannot stat temporary file: %m\n");
      result = 1;
    }
  else if (st.st_size != 0)
    {
      char buf[512];
      puts ("some cleanup handlers ran:");
      fflush (stdout);
      __lseek (fd, 0, SEEK_SET);
      while (1)
	{
	  ssize_t n = read (fd, buf, sizeof buf);
	  if (n <= 0)
	    break;
	  write (STDOUT_FILENO, buf, n);
	}
      result = 1;
    }

  // if (cleanupokcnt != 3)  will be three once t3 runs
  if (cleanupokcnt != 2)
    {
      printf ("cleanupokcnt = %d\n", cleanupokcnt);
      result = 1;
    }

  return result;
}

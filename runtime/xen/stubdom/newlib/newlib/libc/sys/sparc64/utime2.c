/* utime() system call for sunos4 */

#ifndef __svr4__

#include <time.h>
#include <sys/time.h>
#include <utime.h>

int
utime (char *path, struct utimbuf *times)
{
  if (times != NULL)
    {
      struct timeval timevals[2];

      timevals[0].tv_sec = (long int) times->actime;
      timevals[0].tv_usec = 0;
      timevals[1].tv_sec = (long int) times->modtime;
      timevals[1].tv_usec = 0;
      return utimes (path, timevals);
    }

  return utimes (path, (struct timeval *) 0);
}

#endif

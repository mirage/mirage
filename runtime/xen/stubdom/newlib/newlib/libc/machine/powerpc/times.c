/* Time support routines for PowerPC.
 *
 * Written by Aldy Hernandez.
 */

#include <_ansi.h>
#include <reent.h>
#include <sys/time.h>
#include <sys/times.h>
#include <sys/resource.h>

clock_t
times (struct tms *tp)
{
  struct rusage usage;
  union {
    struct rusage r;
    /* Newlib's rusage has only 2 fields.  We need to make room for
       when we call the system's rusage.  This should be enough.  */
    int filler[32];
  } host_ru;

  getrusage (RUSAGE_SELF, (void *)&host_ru);

  if (tp)
    {
      tp->tms_utime = host_ru.r.ru_utime.tv_sec * 1000
	+ host_ru.r.ru_utime.tv_usec;
      tp->tms_stime = host_ru.r.ru_stime.tv_sec * 1000
	+ host_ru.r.ru_stime.tv_usec;
      tp->tms_cutime = 0;	/* user time, children */
      tp->tms_cstime = 0;	/* system time, children */
    }

  return tp->tms_utime;
}

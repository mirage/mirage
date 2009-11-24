/* Convert a string representation of time to a time value.
   Copyright (C) 1997, 1998, 1999, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Mark Kettenis <kettenis@phys.uva.nl>, 1997.

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

/*
FUNCTION
<<getdate>>,<<getdate_r>>---convert a string representation of time to a time value

INDEX
        getdate
INDEX
        getdate_r

ANSI_SYNOPSIS
        #include <time.h>
        struct tm *getdate(const char *<[string]>);
        int getdate_r(const char *<[string]>, struct tm *<[res]>);

TRAD_SYNOPSIS
        #include <time.h>
        struct tm *getdate(<[string]>);
        const char *<[string]>;

        int getdate_r(<[string]>, <[res]>);
        const char *<[string]>;
        struct tm *<[res]>;

DESCRIPTION
<<getdate>> reads a file which is specified by the environment variable:
DATEMSK.  This file contains a number of formats valid for input to the
<<strptime>> function.  The input <[string]> is used as input to the format
strings and the first valid match that occurs is used.  The resultant
time struct is returned.  If an error occurs, the value <<getdate_err>> is
set to one of the following values.

     1  the DATEMSK environment variable is null or undefined,
     2  the template file cannot be opened for reading,
     3  failed to get file status information,
     4  the template file is not a regular file,
     5  an error is encountered while reading the template file,
     6  memory allication failed (not enough memory available),
     7  there is no line in the template that matches the input,
     8  invalid input specification

The <<getdate_r>> routine is similar, except that it returns the error
code and has the <[res]> time struct pointer passed in.  <<getdate>> is
non-reentrant.  Applications that wish to be reentrant should use 
<<getdate_r>> instead of <<getdate>>.  

RETURNS
<<getdate>> returns a pointer to the traditional time representation 
(<<struct tm>>).  <<getdate_r>> returns 0 if successful, otherwise it
returns the error code.

PORTABILITY
<<getdate>> is defined by the Single Unix specification.
<<getdate_r>> is a reentrant extension.

<<getdate>> and <<getdate_r>> optionally require <<stat>> and <<access>>.
*/


/* Modified for newlib by Jeff Johnston, June 19/2002 */

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 2
# define STAT stat64
#else
# define STAT stat
#endif

#define TM_YEAR_BASE 1900

extern ssize_t __getline (char **, size_t *, FILE *);

/* Prototypes for local functions.  */
static int first_wday (int year, int mon, int wday);
static int check_mday (int year, int mon, int mday);

#define isleap(y) ((((y) % 4) == 0 && ((y) % 100) != 0) || ((y) % 400) == 0)

/* Error code is set to one of the following values to indicate an error.
     1  the DATEMSK environment variable is null or undefined,
     2  the template file cannot be opened for reading,
     3  failed to get file status information,
     4  the template file is not a regular file,
     5  an error is encountered while reading the template file,
     6  memory allication failed (not enough memory available),
     7  there is no line in the template that matches the input,
     8  invalid input specification Example: February 31 or a time is
        specified that can not be represented in a time_t (representing
	the time in seconds since 00:00:00 UTC, January 1, 1970) */

/* Returns the first weekday WDAY of month MON in the year YEAR.  */
static int
first_wday (int year, int mon, int wday)
{
  struct tm tm;

  if (wday == INT_MIN)
    return 1;

  memset (&tm, 0, sizeof (struct tm));
  tm.tm_year = year;
  tm.tm_mon = mon;
  tm.tm_mday = 1;
  mktime (&tm);

  return (1 + (wday - tm.tm_wday + 7) % 7);
}


/* Returns 1 if MDAY is a valid day of the month in month MON of year
   YEAR, and 0 if it is not.  */
static int
check_mday (int year, int mon, int mday)
{
  switch (mon)
    {
    case 0:
    case 2:
    case 4:
    case 6:
    case 7:
    case 9:
    case 11:
      if (mday >= 1 && mday <= 31)
	return 1;
      break;
    case 3:
    case 5:
    case 8:
    case 10:
      if (mday >= 1 && mday <= 30)
	return 1;
      break;
    case 1:
      if (mday >= 1 && mday <= (isleap (year) ? 29 : 28))
	return 1;
      break;
    }

  return 0;
}


int
getdate_r (const char *string, struct tm *tp)
{
  FILE *fp;
  char *line;
  size_t len;
  char *datemsk;
  char *result = NULL;
  time_t timer;
  struct tm tm;
  struct STAT st;
  int mday_ok = 0;

  datemsk = getenv ("DATEMSK");
  if (datemsk == NULL || *datemsk == '\0')
    return 1;

  if (STAT (datemsk, &st) < 0)
    return 3;

  if (!S_ISREG (st.st_mode))
    return 4;

  if (access (datemsk, R_OK) < 0)
    return 2;

  /* Open the template file.  */
  fp = fopen (datemsk, "r");
  if (fp == NULL)
    return 2;

  line = NULL;
  len = 0;
  do
    {
      ssize_t n;

      n = __getline (&line, &len, fp);
      if (n < 0)
	break;
      if (line[n - 1] == '\n')
	line[n - 1] = '\0';

      /* Do the conversion.  */
      tp->tm_year = tp->tm_mon = tp->tm_mday = tp->tm_wday = INT_MIN;
      tp->tm_hour = tp->tm_sec = tp->tm_min = INT_MIN;
      tp->tm_isdst = -1;
      result = strptime (string, line, tp);
      if (result && *result == '\0')
	break;
    }
  while (!__sfeof (fp));

  /* Free the buffer.  */
  free (line);

  /* Check for errors. */
  if (__sferror (fp))
    {
      fclose (fp);
      return 5;
    }

  /* Close template file.  */
  fclose (fp);

  if (result == NULL || *result != '\0')
    return 7;

  /* Get current time.  */
  time (&timer);
  localtime_r (&timer, &tm);

  /* If only the weekday is given, today is assumed if the given day
     is equal to the current day and next week if it is less.  */
  if (tp->tm_wday >= 0 && tp->tm_wday <= 6 && tp->tm_year == INT_MIN
      && tp->tm_mon == INT_MIN && tp->tm_mday == INT_MIN)
    {
      tp->tm_year = tm.tm_year;
      tp->tm_mon = tm.tm_mon;
      tp->tm_mday = tm.tm_mday + (tp->tm_wday - tm.tm_wday + 7) % 7;
      mday_ok = 1;
    }

  /* If only the month is given, the current month is assumed if the
     given month is equal to the current month and next year if it is
     less and no year is given (the first day of month is assumed if
     no day is given.  */
  if (tp->tm_mon >= 0 && tp->tm_mon <= 11 && tp->tm_mday == INT_MIN)
    {
      if (tp->tm_year == INT_MIN)
	tp->tm_year = tm.tm_year + (((tp->tm_mon - tm.tm_mon) < 0) ? 1 : 0);
      tp->tm_mday = first_wday (tp->tm_year, tp->tm_mon, tp->tm_wday);
      mday_ok = 1;
    }

  /* If no hour, minute and second are given the current hour, minute
     and second are assumed.  */
  if (tp->tm_hour == INT_MIN && tp->tm_min == INT_MIN && tp->tm_sec == INT_MIN)
    {
      tp->tm_hour = tm.tm_hour;
      tp->tm_min = tm.tm_min;
      tp->tm_sec = tm.tm_sec;
    }

  /* If no date is given, today is assumed if the given hour is
     greater than the current hour and tomorrow is assumed if
     it is less.  */
  if (tp->tm_hour >= 0 && tp->tm_hour <= 23
      && tp->tm_year == INT_MIN && tp->tm_mon == INT_MIN
      && tp->tm_mday == INT_MIN && tp->tm_wday == INT_MIN)
    {
      tp->tm_year = tm.tm_year;
      tp->tm_mon = tm.tm_mon;
      tp->tm_mday = tm.tm_mday + ((tp->tm_hour - tm.tm_hour) < 0 ? 1 : 0);
      mday_ok = 1;
    }

  /* Fill in the gaps.  */
  if (tp->tm_year == INT_MIN)
    tp->tm_year = tm.tm_year;
  if (tp->tm_hour == INT_MIN)
    tp->tm_hour = 0;
  if (tp->tm_min == INT_MIN)
    tp->tm_min = 0;
  if (tp->tm_sec == INT_MIN)
    tp->tm_sec = 0;

  /* Check if the day of month is within range, and if the time can be
     represented in a time_t.  We make use of the fact that the mktime
     call normalizes the struct tm.  */
  if ((!mday_ok && !check_mday (TM_YEAR_BASE + tp->tm_year, tp->tm_mon,
				tp->tm_mday))
      || mktime (tp) == (time_t) -1)
    return 8;

  return 0;
}

#ifndef _REENT_ONLY
struct tm *
getdate (const char *string)
{
  /* Buffer returned by getdate.  */
  static struct tm tmbuf;
  int errval = getdate_r (string, &tmbuf);

  if (errval != 0)
    {
      getdate_err = errval;
      return NULL;
    }

  return &tmbuf;
}
#endif /* _REENT_ONLY */

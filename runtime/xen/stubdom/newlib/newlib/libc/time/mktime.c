/*
 * mktime.c
 * Original Author:	G. Haley
 *
 * Converts the broken-down time, expressed as local time, in the structure
 * pointed to by tim_p into a calendar time value. The original values of the
 * tm_wday and tm_yday fields of the structure are ignored, and the original
 * values of the other fields have no restrictions. On successful completion
 * the fields of the structure are set to represent the specified calendar
 * time. Returns the specified calendar time. If the calendar time can not be
 * represented, returns the value (time_t) -1.
 */

/*
FUNCTION
<<mktime>>---convert time to arithmetic representation

INDEX
	mktime

ANSI_SYNOPSIS
	#include <time.h>
	time_t mktime(struct tm *<[timp]>);

TRAD_SYNOPSIS
	#include <time.h>
	time_t mktime(<[timp]>)
	struct tm *<[timp]>;

DESCRIPTION
<<mktime>> assumes the time at <[timp]> is a local time, and converts
its representation from the traditional representation defined by
<<struct tm>> into a representation suitable for arithmetic.

<<localtime>> is the inverse of <<mktime>>.

RETURNS
If the contents of the structure at <[timp]> do not form a valid
calendar time representation, the result is <<-1>>.  Otherwise, the
result is the time, converted to a <<time_t>> value.

PORTABILITY
ANSI C requires <<mktime>>.

<<mktime>> requires no supporting OS subroutines.
*/

#include <stdlib.h>
#include <time.h>
#include "local.h"

#define _SEC_IN_MINUTE 60L
#define _SEC_IN_HOUR 3600L
#define _SEC_IN_DAY 86400L

static _CONST int DAYS_IN_MONTH[12] =
{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

#define _DAYS_IN_MONTH(x) ((x == 1) ? days_in_feb : DAYS_IN_MONTH[x])

static _CONST int _DAYS_BEFORE_MONTH[12] =
{0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334};

#define _ISLEAP(y) (((y) % 4) == 0 && (((y) % 100) != 0 || (((y)+1900) % 400) == 0))
#define _DAYS_IN_YEAR(year) (_ISLEAP(year) ? 366 : 365)

static void 
validate_structure (tim_p)
     struct tm *tim_p;
{
  div_t res;
  int days_in_feb = 28;

  /* calculate time & date to account for out of range values */
  if (tim_p->tm_sec < 0 || tim_p->tm_sec > 59)
    {
      res = div (tim_p->tm_sec, 60);
      tim_p->tm_min += res.quot;
      if ((tim_p->tm_sec = res.rem) < 0)
	{
	  tim_p->tm_sec += 60;
	  --tim_p->tm_min;
	}
    }

  if (tim_p->tm_min < 0 || tim_p->tm_min > 59)
    {
      res = div (tim_p->tm_min, 60);
      tim_p->tm_hour += res.quot;
      if ((tim_p->tm_min = res.rem) < 0)
	{
	  tim_p->tm_min += 60;
	  --tim_p->tm_hour;
        }
    }

  if (tim_p->tm_hour < 0 || tim_p->tm_hour > 23)
    {
      res = div (tim_p->tm_hour, 24);
      tim_p->tm_mday += res.quot;
      if ((tim_p->tm_hour = res.rem) < 0)
	{
	  tim_p->tm_hour += 24;
	  --tim_p->tm_mday;
        }
    }

  if (tim_p->tm_mon > 11)
    {
      res = div (tim_p->tm_mon, 12);
      tim_p->tm_year += res.quot;
      if ((tim_p->tm_mon = res.rem) < 0)
        {
	  tim_p->tm_mon += 12;
	  --tim_p->tm_year;
        }
    }

  if (_DAYS_IN_YEAR (tim_p->tm_year) == 366)
    days_in_feb = 29;

  if (tim_p->tm_mday <= 0)
    {
      while (tim_p->tm_mday <= 0)
	{
	  if (--tim_p->tm_mon == -1)
	    {
	      tim_p->tm_year--;
	      tim_p->tm_mon = 11;
	      days_in_feb =
		((_DAYS_IN_YEAR (tim_p->tm_year) == 366) ?
		 29 : 28);
	    }
	  tim_p->tm_mday += _DAYS_IN_MONTH (tim_p->tm_mon);
	}
    }
  else
    {
      while (tim_p->tm_mday > _DAYS_IN_MONTH (tim_p->tm_mon))
	{
	  tim_p->tm_mday -= _DAYS_IN_MONTH (tim_p->tm_mon);
	  if (++tim_p->tm_mon == 12)
	    {
	      tim_p->tm_year++;
	      tim_p->tm_mon = 0;
	      days_in_feb =
		((_DAYS_IN_YEAR (tim_p->tm_year) == 366) ?
		 29 : 28);
	    }
	}
    }
}

time_t 
mktime (tim_p)
     struct tm *tim_p;
{
  time_t tim = 0;
  long days = 0;
  int year, isdst;
  __tzinfo_type *tz = __gettzinfo ();

  /* validate structure */
  validate_structure (tim_p);

  /* compute hours, minutes, seconds */
  tim += tim_p->tm_sec + (tim_p->tm_min * _SEC_IN_MINUTE) +
    (tim_p->tm_hour * _SEC_IN_HOUR);

  /* compute days in year */
  days += tim_p->tm_mday - 1;
  days += _DAYS_BEFORE_MONTH[tim_p->tm_mon];
  if (tim_p->tm_mon > 1 && _DAYS_IN_YEAR (tim_p->tm_year) == 366)
    days++;

  /* compute day of the year */
  tim_p->tm_yday = days;

  if (tim_p->tm_year > 10000
      || tim_p->tm_year < -10000)
    {
      return (time_t) -1;
    }

  /* compute days in other years */
  if (tim_p->tm_year > 70)
    {
      for (year = 70; year < tim_p->tm_year; year++)
	days += _DAYS_IN_YEAR (year);
    }
  else if (tim_p->tm_year < 70)
    {
      for (year = 69; year > tim_p->tm_year; year--)
	days -= _DAYS_IN_YEAR (year);
      days -= _DAYS_IN_YEAR (year);
    }

  /* compute day of the week */
  if ((tim_p->tm_wday = (days + 4) % 7) < 0)
    tim_p->tm_wday += 7;

  /* compute total seconds */
  tim += (days * _SEC_IN_DAY);

  isdst = tim_p->tm_isdst;

  if (_daylight)
    {
      int y = tim_p->tm_year + YEAR_BASE;
      if (y == tz->__tzyear || __tzcalc_limits (y))
	{
	  /* calculate start of dst in dst local time and 
	     start of std in both std local time and dst local time */
          time_t startdst_dst = tz->__tzrule[0].change
	    - (time_t) tz->__tzrule[1].offset;
	  time_t startstd_dst = tz->__tzrule[1].change
	    - (time_t) tz->__tzrule[1].offset;
	  time_t startstd_std = tz->__tzrule[1].change
	    - (time_t) tz->__tzrule[0].offset;
	  /* if the time is in the overlap between dst and std local times */
	  if (tim >= startstd_std && tim < startstd_dst)
	    ; /* we let user decide or leave as -1 */
          else
	    {
	      isdst = (tz->__tznorth
		       ? (tim >= startdst_dst && tim < startstd_std)
		       : (tim >= startdst_dst || tim < startstd_std));
	      /* if user committed and was wrong, perform correction */
	      if ((isdst ^ tim_p->tm_isdst) == 1)
		{
		  /* we either subtract or add the difference between
		     time zone offsets, depending on which way the user got it
		     wrong. The diff is typically one hour, or 3600 seconds,
		     and should fit in a 16-bit int, even though offset
		     is a long to accomodate 12 hours. */
		  int diff = (int) (tz->__tzrule[0].offset
				    - tz->__tzrule[1].offset);
		  if (!isdst)
		    diff = -diff;
		  tim_p->tm_sec += diff;
		  validate_structure (tim_p);
		  tim += diff;  /* we also need to correct our current time calculation */
		}
	    }
	}
    }

  /* add appropriate offset to put time in gmt format */
  if (isdst == 1)
    tim += (time_t) tz->__tzrule[1].offset;
  else /* otherwise assume std time */
    tim += (time_t) tz->__tzrule[0].offset;

  /* reset isdst flag to what we have calculated */
  tim_p->tm_isdst = isdst;

  return tim;
}

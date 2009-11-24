/*
 * mktm_r.c
 * Original Author:	Adapted from tzcode maintained by Arthur David Olson.
 * Modifications:       Changed to mktm_r and added __tzcalc_limits - 04/10/02, Jeff Johnston
 *                      Fixed bug in mday computations - 08/12/04, Alex Mogilnikov <alx@intellectronika.ru>
 *                      Fixed bug in __tzcalc_limits - 08/12/04, Alex Mogilnikov <alx@intellectronika.ru>
 *
 * Converts the calendar time pointed to by tim_p into a broken-down time
 * expressed as local time. Returns a pointer to a structure containing the
 * broken-down time.
 */

#include <stdlib.h>
#include <time.h>
#include "local.h"

static _CONST int mon_lengths[2][MONSPERYEAR] = {
  {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31},
  {31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
} ;

static _CONST int year_lengths[2] = {
  365,
  366
} ;

struct tm *
_DEFUN (_mktm_r, (tim_p, res, is_gmtime),
	_CONST time_t * tim_p _AND
	struct tm *res _AND
	int is_gmtime)
{
  long days, rem;
  time_t lcltime;
  int y;
  int yleap;
  _CONST int *ip;
   __tzinfo_type *tz = __gettzinfo ();

  /* base decision about std/dst time on current time */
  lcltime = *tim_p;
   
  days = ((long)lcltime) / SECSPERDAY;
  rem = ((long)lcltime) % SECSPERDAY;
  while (rem < 0) 
    {
      rem += SECSPERDAY;
      --days;
    }
  while (rem >= SECSPERDAY)
    {
      rem -= SECSPERDAY;
      ++days;
    }
 
  /* compute hour, min, and sec */  
  res->tm_hour = (int) (rem / SECSPERHOUR);
  rem %= SECSPERHOUR;
  res->tm_min = (int) (rem / SECSPERMIN);
  res->tm_sec = (int) (rem % SECSPERMIN);

  /* compute day of week */
  if ((res->tm_wday = ((EPOCH_WDAY + days) % DAYSPERWEEK)) < 0)
    res->tm_wday += DAYSPERWEEK;

  /* compute year & day of year */
  y = EPOCH_YEAR;
  if (days >= 0)
    {
      for (;;)
	{
	  yleap = isleap(y);
	  if (days < year_lengths[yleap])
	    break;
	  y++;
	  days -= year_lengths[yleap];
	}
    }
  else
    {
      do
	{
	  --y;
	  yleap = isleap(y);
	  days += year_lengths[yleap];
	} while (days < 0);
    }

  res->tm_year = y - YEAR_BASE;
  res->tm_yday = days;
  ip = mon_lengths[yleap];
  for (res->tm_mon = 0; days >= ip[res->tm_mon]; ++res->tm_mon)
    days -= ip[res->tm_mon];
  res->tm_mday = days + 1;

  if (!is_gmtime)
    {
      long offset;
      int hours, mins, secs;

      TZ_LOCK;
      if (_daylight)
	{
	  if (y == tz->__tzyear || __tzcalc_limits (y))
	    res->tm_isdst = (tz->__tznorth 
			     ? (*tim_p >= tz->__tzrule[0].change 
				&& *tim_p < tz->__tzrule[1].change)
			     : (*tim_p >= tz->__tzrule[0].change 
				|| *tim_p < tz->__tzrule[1].change));
	  else
	    res->tm_isdst = -1;
	}
      else
	res->tm_isdst = 0;

      offset = (res->tm_isdst == 1 
		  ? tz->__tzrule[1].offset 
		  : tz->__tzrule[0].offset);

      hours = (int) (offset / SECSPERHOUR);
      offset = offset % SECSPERHOUR;
      
      mins = (int) (offset / SECSPERMIN);
      secs = (int) (offset % SECSPERMIN);

      res->tm_sec -= secs;
      res->tm_min -= mins;
      res->tm_hour -= hours;

      if (res->tm_sec >= SECSPERMIN)
	{
	  res->tm_min += 1;
	  res->tm_sec -= SECSPERMIN;
	}
      else if (res->tm_sec < 0)
	{
	  res->tm_min -= 1;
	  res->tm_sec += SECSPERMIN;
	}
      if (res->tm_min >= MINSPERHOUR)
	{
	  res->tm_hour += 1;
	  res->tm_min -= MINSPERHOUR;
	}
      else if (res->tm_min < 0)
	{
	  res->tm_hour -= 1;
	  res->tm_min += MINSPERHOUR;
	}
      if (res->tm_hour >= HOURSPERDAY)
	{
	  ++res->tm_yday;
	  ++res->tm_wday;
	  if (res->tm_wday > 6)
	    res->tm_wday = 0;
	  ++res->tm_mday;
	  res->tm_hour -= HOURSPERDAY;
	  if (res->tm_mday > ip[res->tm_mon])
	    {
	      res->tm_mday -= ip[res->tm_mon];
	      res->tm_mon += 1;
	      if (res->tm_mon == 12)
		{
		  res->tm_mon = 0;
		  res->tm_year += 1;
		  res->tm_yday = 0;
		}
	    }
	}
       else if (res->tm_hour < 0)
	{
	  res->tm_yday -= 1;
	  res->tm_wday -= 1;
	  if (res->tm_wday < 0)
	    res->tm_wday = 6;
	  res->tm_mday -= 1;
	  res->tm_hour += 24;
	  if (res->tm_mday == 0)
	    {
	      res->tm_mon -= 1;
	      if (res->tm_mon < 0)
		{
		  res->tm_mon = 11;
		  res->tm_year -= 1;
		  res->tm_yday = 365 + isleap(res->tm_year);
		}
	      res->tm_mday = ip[res->tm_mon];
	    }
	}
      TZ_UNLOCK;
    }
  else
    res->tm_isdst = 0;

  return (res);
}

int
_DEFUN (__tzcalc_limits, (year),
	int year)
{
  int days, year_days, years;
  int i, j;
  __tzinfo_type *tz = __gettzinfo ();

  if (year < EPOCH_YEAR)
    return 0;

  tz->__tzyear = year;

  years = (year - EPOCH_YEAR);

  year_days = years * 365 +
    (years - 1 + EPOCH_YEARS_SINCE_LEAP) / 4 - (years - 1 + EPOCH_YEARS_SINCE_CENTURY) / 100 + 
    (years - 1 + EPOCH_YEARS_SINCE_LEAP_CENTURY) / 400;
  
  for (i = 0; i < 2; ++i)
    {
      if (tz->__tzrule[i].ch == 'J')
	days = year_days + tz->__tzrule[i].d + 
		(isleap(year) && tz->__tzrule[i].d >= 60);
      else if (tz->__tzrule[i].ch == 'D')
	days = year_days + tz->__tzrule[i].d;
      else
	{
	  int yleap = isleap(year);
	  int m_day, m_wday, wday_diff;
	  _CONST int *ip = mon_lengths[yleap];

	  days = year_days;

	  for (j = 1; j < tz->__tzrule[i].m; ++j)
	    days += ip[j-1];

	  m_wday = (EPOCH_WDAY + days) % DAYSPERWEEK;
	  
	  wday_diff = tz->__tzrule[i].d - m_wday;
	  if (wday_diff < 0)
	    wday_diff += DAYSPERWEEK;
	  m_day = (tz->__tzrule[i].n - 1) * DAYSPERWEEK + wday_diff;

	  while (m_day >= ip[j-1])
	    m_day -= DAYSPERWEEK;

	  days += m_day;
	}

      /* store the change-over time in GMT form by adding offset */
      tz->__tzrule[i].change = days * SECSPERDAY + 
	      			tz->__tzrule[i].s + tz->__tzrule[i].offset;
    }

  tz->__tznorth = (tz->__tzrule[0].change < tz->__tzrule[1].change);

  return 1;
}


/*
FUNCTION
<<tzset>>---set timezone characteristics from TZ environment variable

INDEX
	tzset

ANSI_SYNOPSIS
	#include <time.h>
	void tzset(void);
	void _tzset_r (struct _reent *);

TRAD_SYNOPSIS
	#include <time.h>
	void tzset();
	void _tzset_r (reent_ptr)
        struct _reent *reent_ptr;

DESCRIPTION
<<tzset>> examines the TZ environment variable and sets up the three
external variables: <<_timezone>>, <<_daylight>>, and <<tzname>>.  The
value of <<_timezone>> shall be the offset from the current time zone
to GMT.  The value of <<_daylight>> shall be 0 if there is no daylight
savings time for the current time zone, otherwise it will be non-zero.
The <<tzname>> array has two entries: the first is the name of the
standard time zone, the second is the name of the daylight-savings time
zone.

The TZ environment variable is expected to be in the following POSIX
format:

  stdoffset1[dst[offset2][,start[/time1],end[/time2]]]

where: std is the name of the standard time-zone (minimum 3 chars)
       offset1 is the value to add to local time to arrive at Universal time
         it has the form:  hh[:mm[:ss]]
       dst is the name of the alternate (daylight-savings) time-zone (min 3 chars)
       offset2 is the value to add to local time to arrive at Universal time
         it has the same format as the std offset
       start is the day that the alternate time-zone starts
       time1 is the optional time that the alternate time-zone starts
         (this is in local time and defaults to 02:00:00 if not specified)
       end is the day that the alternate time-zone ends
       time2 is the time that the alternate time-zone ends
         (it is in local time and defaults to 02:00:00 if not specified)

Note that there is no white-space padding between fields.  Also note that
if TZ is null, the default is Universal GMT which has no daylight-savings
time.  If TZ is empty, the default EST5EDT is used.

The function <<_tzset_r>> is identical to <<tzset>> only it is reentrant
and is used for applications that use multiple threads.

RETURNS
There is no return value.

PORTABILITY
<<tzset>> is part of the POSIX standard.

Supporting OS subroutine required: None
*/

#include <_ansi.h>
#include <reent.h>
#include <time.h>
#include "local.h"

_VOID
_DEFUN_VOID (tzset)
{
  _tzset_r (_REENT);
}

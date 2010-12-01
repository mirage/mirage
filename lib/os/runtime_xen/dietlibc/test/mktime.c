#include <stdio.h>
#include <time.h>

int main() {
  struct tm t;
  t.tm_sec=1;
  t.tm_min=2;
  t.tm_hour=3;
  t.tm_mday=29;
  t.tm_mon=2;
  t.tm_year=100;
  printf("%d\n",mktime(&t));
  t.tm_mday=1;
  t.tm_mon=3;
  t.tm_year=102;
  printf("%d\n",mktime(&t));
  t.tm_mday=1;
  t.tm_mon=6;
  t.tm_year=102;
  printf("%d\n",mktime(&t));
  return 0;
}

#if 0
                      int     tm_sec;         /* seconds */
                      int     tm_min;         /* minutes */
                      int     tm_hour;        /* hours */
                      int     tm_mday;        /* day of the month */
                      int     tm_mon;         /* month */
                      int     tm_year;        /* year */
                      int     tm_wday;        /* day of the week */
                      int     tm_yday;        /* day in the year */
                      int     tm_isdst;       /* daylight saving time */
#endif

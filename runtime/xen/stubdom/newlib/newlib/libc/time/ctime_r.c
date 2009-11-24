/*
 * ctime_r.c
 */

#include <time.h>

char *
_DEFUN (ctime_r, (tim_p, result),
	_CONST time_t * tim_p _AND
        char * result)

{
  struct tm tm;
  return asctime_r (localtime_r (tim_p, &tm), result);
}

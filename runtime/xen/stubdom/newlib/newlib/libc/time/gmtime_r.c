/*
 * gmtime_r.c
 */

#include <time.h>
#include "local.h"

struct tm *
_DEFUN (gmtime_r, (tim_p, res),
	_CONST time_t * tim_p _AND
	struct tm *res)
{
  return (_mktm_r (tim_p, res, 1));
}

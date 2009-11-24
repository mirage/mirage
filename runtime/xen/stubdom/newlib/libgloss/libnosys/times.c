/*
 * Stub version of times.
 */

#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <sys/times.h>
#include <errno.h>
#undef errno
extern int errno;
#include "warning.h"

clock_t
_DEFUN (_times, (buf),
        struct tms *buf)
{
  errno = ENOSYS;
  return -1;
}

stub_warning(_times)

/*
 * Stub version of getpid.
 */

#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <errno.h>
#undef errno
extern int errno;
#include "warning.h"

int
_DEFUN (_getpid, (),
        _NOARGS)
{
  errno = ENOSYS;
  return -1;
}

stub_warning(_getpid)

/*
 * Stub version of isatty.
 */

#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <errno.h>
#undef errno
extern int errno;
#include "warning.h"

int
_DEFUN (isatty, (file),
        int file)
{
  errno = ENOSYS;
  return 0;
}

stub_warning(isatty)

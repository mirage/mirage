/*
 * Stub version of symlink.
 */

#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <errno.h>
#undef errno
extern int errno;
#include "warning.h"

int
_DEFUN (_symlink, (path1, path2),
        const char *path1 _AND
        const char *path2)
{
  errno = ENOSYS;
  return -1;
}

stub_warning(_symlink)

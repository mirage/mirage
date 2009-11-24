/* FIXME: dummy stub for now.  */
#include <errno.h>
#include <unistd.h>

char *
_DEFUN_VOID (getlogin)
{
  errno = ENOSYS;
  return NULL;
}


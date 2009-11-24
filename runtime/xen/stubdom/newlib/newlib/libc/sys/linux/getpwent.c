/* FIXME: dummy stub for now.  */
#include <errno.h>
#include <pwd.h>

struct passwd *
_DEFUN (getpwnam, (name),
	_CONST char *name)
{
  errno = ENOSYS;
  return NULL;
}

/* FIXME: dummy stub for now.  */
struct passwd *
_DEFUN (getpwuid, (uid),
	uid_t uid)
{
  errno = ENOSYS;
  return NULL;
}

/* FIXME: dummy stub for now.  */
struct passwd *
_DEFUN (getpwent, (uid),
	uid_t uid)
{
  errno = ENOSYS;
  return NULL;
}


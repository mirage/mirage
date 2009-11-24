/* Stub for kill.  */

#include <_ansi.h>
#include <errno.h>

/* The pid argument should be of type pid_t.  */

int
_DEFUN (_kill, (pid, sig),
	int pid _AND
	int sig)
{
  if (pid == 1 || pid < 0)
    {
      if (sig == 0)
	return 0;
      return raise (sig);
    }
  errno = EINVAL;
  return -1;
}

/* creat() "system call" */

/* This is needed by f2c and therefore the SPEC benchmarks.  */

#include <fcntl.h>

int
_DEFUN(creat, (path, mode), 
       const char *path _AND 
       mode_t mode)
{
  return open (path, O_WRONLY | O_CREAT | O_TRUNC, mode);
}

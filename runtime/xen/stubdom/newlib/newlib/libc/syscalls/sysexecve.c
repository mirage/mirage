/* connector for execve */

#include <reent.h>

int
_DEFUN (execve, (name, argv, env),
     char *name _AND
     char **argv _AND
     char **env)
{
#ifdef REENTRANT_SYSCALLS_PROVIDED
  return _execve_r (_REENT, name, argv, env);
#else
  return _execve (name, argv, env);
#endif
}

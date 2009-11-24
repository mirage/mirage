/* connector for link */

#include <reent.h>

int
_DEFUN (link, (old, new),
     char *old _AND
     char *new)
{
#ifdef REENTRANT_SYSCALLS_PROVIDED
  return _link_r (_REENT, old, new);
#else
  return _link (old, new);
#endif
}

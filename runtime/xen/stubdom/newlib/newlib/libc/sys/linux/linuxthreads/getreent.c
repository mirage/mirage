/* get thread-specific reentrant pointer */

#include <internals.h>

struct _reent *
__getreent (void)
{
  pthread_descr self = thread_self();
  return THREAD_GETMEM(self, p_reentp);
}


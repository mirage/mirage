/* Define the location of _REENT for the newlib C library */

#include <reent.h>
#include "pthread.h"
#include "internals.h"

struct _reent * __thread_reent()
{
  pthread_descr self = thread_self();
  return THREAD_GETMEM (self, p_reentp);
}

/* Return thread specific resolver state.  */
struct __res_state * __res_state()
{
  pthread_descr self = thread_self();
  return THREAD_GETMEM (self, p_resp);
}

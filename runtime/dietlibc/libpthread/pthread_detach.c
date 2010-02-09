#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_detach(pthread_t th) {
  int ret=ESRCH;
  _pthread_descr td,this=__thread_self();
  __NO_ASYNC_CANCEL_BEGIN_(this);
  if ((td=__thread_find(th))) {
    if (td->detached) {
      ret=EINVAL;
    }
    else if (td->joined.__spinlock==PTHREAD_SPIN_UNLOCKED) {
      td->detached=1;
      ret^=ret; /* short ret=0; */
    }
    UNLOCK(td);
  }
  __NO_ASYNC_CANCEL_END_(this);
  return ret;
}

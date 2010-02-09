#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

/* set thread schedul parameters */
int pthread_setschedparam(pthread_t th,int policy,const struct sched_param*param) {
  int ret=ESRCH;
  _pthread_descr td,this=__thread_self();
  __NO_ASYNC_CANCEL_BEGIN_(this);
  if ((td=__thread_find(th))) {
    UNLOCK(td);
    ret=EINVAL;
    if (((policy==SCHED_OTHER)&&(param->sched_priority==0)) ||
	(((policy==SCHED_RR)||(policy==SCHED_FIFO))&&
	 ((param->sched_priority>0)&&(param->sched_priority<100))))
      ret=(sched_setscheduler(th,policy,param))?_errno_:0;
  }
  __NO_ASYNC_CANCEL_END_(this);
  return ret;
}

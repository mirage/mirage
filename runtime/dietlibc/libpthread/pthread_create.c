#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <string.h>

#include <pthread.h>
#include "thread_internal.h"

#ifdef WANT_TLS
#include <sys/tls.h>

extern size_t __tmemsize;
#endif

int pthread_attr_init(pthread_attr_t*attr) {
  memset(attr,0,sizeof(pthread_attr_t));
  attr->__stacksize=PTHREAD_STACK_SIZE;
/* no need to do this initalisation (all are zero values)
 * attr->__detachstate = PTHREAD_CREATE_JOINABLE;
 * attr->__scope = PTHREAD_SCOPE_SYSTEM;
 * attr->__inheritsched=PTHREAD_EXPLICIT_SCHED;
 * attr->__schedpolicy=SCHED_OTHER;
 * attr->__schedparam.sched_priority=0;
 */
  return 0;
}
int pthread_attr_destroy(pthread_attr_t *attr) __attribute__((alias("pthread_attr_init")));

int pthread_create(pthread_t*thread,const pthread_attr_t*d_attr,
		void*(*start_routine)(void*),void*arg) {
#if 0
  /* first try the linux 2.6 way */
  if (__likely(__modern_linux>=0)) {
    /* try new way; if it fails, assume old kernel */
  }
#endif
  struct __thread_descr request;
  pthread_attr_t attr;
  _pthread_descr td,this;
  this=__thread_self();
  char*stack;
  int ret;
#ifdef WANT_TLS
  size_t origsize;
  size_t additional;
#endif

  if (thread==0) kill(getpid(),SIGSEGV);
  if (start_routine==0) return EINVAL;

  __TEST_CANCEL_(this);
  __NO_ASYNC_CANCEL_BEGIN_(this);
  if (d_attr)
    attr=*d_attr;
  else
    pthread_attr_init(&attr);

#ifdef WANT_TLS
  origsize=attr.__stacksize;
  additional=__tmemsize+sizeof(tcbhead_t);
  additional=(additional+15)&-16;
  if (additional < sizeof(tcbhead_t) ||
      origsize < sizeof(struct _pthread_descr_struct) ||
      origsize+additional < origsize) {
    ret=EINVAL;
    goto func_out;
  }
  attr.__stacksize=origsize+additional;
#endif

  {
    register char*stb,*st=0;
    if ((stack=attr.__stackaddr)==0) {
      /* YES we need PROT_EXEC for signal-handling :( */
      if ((st=stack=(char*)mmap(0,attr.__stacksize,PROT_READ|PROT_WRITE|PROT_EXEC,MAP_PRIVATE|MAP_ANONYMOUS,-1,0))==MAP_FAILED)
      {
	ret=EINVAL;
	goto func_out;
      }
    }

    stb=stack;
#ifdef __parisc__
    td=(_pthread_descr)stack;
    stack+=sizeof(struct _pthread_descr_struct);
#else
    stack+=attr.__stacksize-sizeof(struct _pthread_descr_struct);
    td=(_pthread_descr)stack;
#endif
    memset(td,0,sizeof(struct _pthread_descr_struct));
    td->stack_begin	= stb;
    td->stack_end	= stb+attr.__stacksize;
    td->stack_free	= (st)?1:0;
    attr.__stackaddr	= stack;
  }

  request.attr	= &attr;
  request.td	= td;
  request.tr	= this;

  if (attr.__inheritsched==PTHREAD_INHERIT_SCHED) {
    if ((ret=__thread_getschedparam(request.tr->pid,&attr.__schedpolicy,&attr.__schedparam))!=0)
      goto func_out;
  }
  td->lock.__spinlock	= PTHREAD_SPIN_UNLOCKED;
  td->joined.__spinlock	= PTHREAD_SPIN_UNLOCKED;
  td->detached		= attr.__detachstate;

  td->stack_size	= attr.__stacksize;

  td->func		= start_routine;
  td->arg		= arg;

  /* let the "child thread" inherit the procmask (hope this works) */
  sigprocmask(SIG_SETMASK,0,&(td->thread_sig_mask));
  sigaddset(&(td->thread_sig_mask),PTHREAD_SIG_RESTART);
  sigdelset(&(td->thread_sig_mask),PTHREAD_SIG_CANCEL);

  if ((ret=__thread_start_new(&request))==-1) {
    ret=EAGAIN;
    goto func_out;
  }
  *thread=ret;
  ret^=ret;
func_out:
  __NO_ASYNC_CANCEL_END_(this);
  return ret;
}

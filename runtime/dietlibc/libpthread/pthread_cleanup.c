#include <unistd.h>
#include <stdlib.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

void pthread_cleanup_push(void(*func)(void*),void*arg) {
  _pthread_descr this=__thread_self();
  struct thread_cleanup_t*tmp;

  __NO_ASYNC_CANCEL_BEGIN_(this);
  tmp=(struct thread_cleanup_t*)malloc(sizeof(struct thread_cleanup_t));
  tmp->func=func;
  tmp->arg =arg;

  LOCK(this);

  tmp->next=this->cleanup_stack;
  this->cleanup_stack=tmp;

  UNLOCK(this);
  __NO_ASYNC_CANCEL_END_(this);
}

void pthread_cleanup_pop(int execute) {
  _pthread_descr this=__thread_self();
  struct thread_cleanup_t*tmp;

  __NO_ASYNC_CANCEL_BEGIN_(this);
  LOCK(this);

  tmp=this->cleanup_stack;
  this->cleanup_stack=tmp->next;

  UNLOCK(this);

  if (execute) tmp->func(tmp->arg);

  free(tmp);
  __NO_ASYNC_CANCEL_END_(this);
}

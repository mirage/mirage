#include <unistd.h>

#include <pthread.h>
#include "thread_internal.h"

#include <stdlib.h>

static pthread_mutex_t mutex_alloc=PTHREAD_MUTEX_INITIALIZER;

void free(void *ptr) {
  _pthread_descr this=__thread_self();
  __NO_ASYNC_CANCEL_BEGIN_(this);
  __pthread_mutex_lock(&mutex_alloc,this);
  __libc_free(ptr);
  __pthread_mutex_unlock(&mutex_alloc,this);
  __NO_ASYNC_CANCEL_END_(this);
}

void *malloc(size_t size) {
  _pthread_descr this=__thread_self();
  register void *ret;
  __NO_ASYNC_CANCEL_BEGIN_(this);
  __pthread_mutex_lock(&mutex_alloc,this);
  ret=__libc_malloc(size);
  __pthread_mutex_unlock(&mutex_alloc,this);
  __NO_ASYNC_CANCEL_END_(this);
  return ret;
}

void* realloc(void* ptr, size_t size) {
  _pthread_descr this=__thread_self();
  register void *ret;
  __NO_ASYNC_CANCEL_BEGIN_(this);
  __pthread_mutex_lock(&mutex_alloc,this);
  ret=__libc_realloc(ptr, size);
  __pthread_mutex_unlock(&mutex_alloc,this);
  __NO_ASYNC_CANCEL_END_(this);
  return ret;
}

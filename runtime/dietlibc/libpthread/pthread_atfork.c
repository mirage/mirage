#include <unistd.h>
#include <errno.h>
#include <stdlib.h>

#include <pthread.h>
#include "thread_internal.h"

static struct _pthread_fastlock __atfork_struct_lock;
static struct __thread_atfork {
  struct __thread_atfork*next,*prev;

  void (*prepare)(void);
  void (*parent)(void);
  void (*child)(void);
} pthread_atfork_buf={&pthread_atfork_buf,&pthread_atfork_buf,0,0,0};

int pthread_atfork(void (*prepare)(void),
		   void (*parent)(void),
		   void (*child)(void)) {
  _pthread_descr this=__thread_self();
  struct __thread_atfork*new;
  int ret=0;

  __NO_ASYNC_CANCEL_BEGIN_(this);
  __pthread_lock(&__atfork_struct_lock);

  if ((new=(struct __thread_atfork*)malloc(sizeof(struct __thread_atfork)))) {
    new->prepare=prepare;
    new->parent=parent;
    new->child=child;

    new->next=pthread_atfork_buf.next;
    new->prev=&pthread_atfork_buf;
    pthread_atfork_buf.next->prev=new;
    pthread_atfork_buf.next=new;
  }
  else ret=ENOMEM;

  __pthread_unlock(&__atfork_struct_lock);
  __NO_ASYNC_CANCEL_END_(this);

  return ret;
}

pid_t fork(void) {
  _pthread_descr this=__thread_self();
  struct __thread_atfork*tmp;
  pid_t pid;

  __NO_ASYNC_CANCEL_BEGIN_(this);
  __TEST_CANCEL_(this);

  __pthread_lock(&__atfork_struct_lock);

  for (tmp=pthread_atfork_buf.next;tmp!=&pthread_atfork_buf;tmp=tmp->next)
    if (tmp->prepare) tmp->prepare();

  pid=__libc_fork();

  if (pid) {
    for (tmp=pthread_atfork_buf.prev;tmp!=&pthread_atfork_buf;tmp=tmp->prev) {
      if (tmp->parent) tmp->parent();
    }
  }
  else {
    __thread_manager_close();
    for (tmp=pthread_atfork_buf.prev;tmp!=&pthread_atfork_buf;tmp=tmp->prev) {
      if (tmp->child) tmp->child();
    }
  }
  __pthread_unlock(&__atfork_struct_lock);
  __NO_ASYNC_CANCEL_END_(this);
  return pid;
}

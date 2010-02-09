#include <unistd.h>
#include <errno.h>
#include <string.h>

#include <pthread.h>
#include "thread_internal.h"

/* global key data */
static struct _pthread_fastlock __thread_keys_lock;
static struct _thread_key __thread_keys[PTHREAD_KEYS_MAX];

/* glue functions ... */
void __thread_start__key(_pthread_descr th);
void __thread_exit__key(_pthread_descr th);

void __thread_start__key(_pthread_descr th) {
  memset(th->tkd,0,sizeof(th->tkd));
}

void __thread_exit__key(_pthread_descr th) {
  int i;
  void (*dstr)(void*);

  for (i=0;i<PTHREAD_KEYS_MAX;++i) {
    if ((__thread_keys[i].used)&&(dstr=__thread_keys[i].destructor)) {
      void*data=th->tkd[i];
      if (data) dstr(data);
    }
  }
}

/* "create" a thread specific data key */
int pthread_key_create(pthread_key_t*key,void(*destructor)(void*)) {
  _pthread_descr this=__thread_self();
  int ret=EAGAIN,i;

  __NO_ASYNC_CANCEL_BEGIN_(this);
  __pthread_lock(&__thread_keys_lock);

  for (i=0;i<PTHREAD_KEYS_MAX;++i) {
    if (__thread_keys[i].used==0) {
      __thread_keys[i].used=1;
      __thread_keys[i].destructor=destructor;
      *key=i;
      ret=0;
      break;
    }
  }

  __pthread_unlock(&__thread_keys_lock);
  __NO_ASYNC_CANCEL_END_(this);

  return ret;
}

/* "destroy" a thread specific data key */
int pthread_key_delete(pthread_key_t key) {
  _pthread_descr this=__thread_self();

  if (key>=PTHREAD_KEYS_MAX) return EINVAL;

  __NO_ASYNC_CANCEL_BEGIN_(this);
  __pthread_lock(&__thread_keys_lock);

  __thread_keys[key].used=0;
  __thread_keys[key].destructor=0;

  __pthread_unlock(&__thread_keys_lock);
  __NO_ASYNC_CANCEL_END_(this);
  return 0;
}


/* get thread specific data */
void*pthread_getspecific(pthread_key_t key) {
  _pthread_descr this=__thread_self();
  void*ret=0;

  if ((key<PTHREAD_KEYS_MAX) && (__thread_keys[key].used)) {
    ret=this->tkd[key];
  }
  return ret;
}

/* get thread specific data */
int pthread_setspecific(pthread_key_t key, const void *value) {
  _pthread_descr this=__thread_self();

  if ((key<PTHREAD_KEYS_MAX)&&(__thread_keys[key].used)) {
    this->tkd[key]=(void *)value; /* UNCONST */
    return 0;
  }
  return EINVAL;
}


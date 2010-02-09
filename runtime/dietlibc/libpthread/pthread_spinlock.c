#include <time.h>

#include <pthread.h>
#include "thread_internal.h"

void __pthread_lock(struct _pthread_fastlock*lock) {
  int cnt=0;
  struct timespec tm;
  while (__testandset(&lock->__spinlock)) {
    if (cnt<MAX_SPIN_COUNT) {
      sched_yield();
      cnt++;
    } else {
      tm.tv_sec=0;
      tm.tv_nsec=SPIN_SLEEP_DURATION;
      __libc_nanosleep(&tm, 0);
      cnt = 0;
    }
  }
}

int __pthread_trylock(struct _pthread_fastlock*lock) {
  return __testandset(&lock->__spinlock);
}

int __pthread_unlock(struct _pthread_fastlock*lock) {
  lock->__spinlock=PTHREAD_SPIN_UNLOCKED;
  return 0;
}


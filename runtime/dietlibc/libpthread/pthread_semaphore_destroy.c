#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <semaphore.h>
#include "thread_internal.h"

int sem_destroy(sem_t*sem) {
  int n;
  if (sem->magic!=SEM_MAGIC) { _errno_=EINVAL; return -1; }
  if ((n=pthread_cond_destroy(&sem->cond))) { _errno_=n; return -1; }
  sem->magic=0;
  return 0;
}


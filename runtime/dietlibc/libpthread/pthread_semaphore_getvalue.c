#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <semaphore.h>
#include "thread_internal.h"

int sem_getvalue(sem_t*sem,int*sval) {
  if (sem->magic!=SEM_MAGIC) { _errno_=EINVAL; return -1; }
  *sval=sem->value;
  return 0;
}


#ifndef __SEMAPHORE_H__
#define __SEMAPHORE_H__

#include <time.h>
#include <pthread.h>

__BEGIN_DECLS

typedef struct {
  pthread_mutex_t lock;
  pthread_cond_t cond;
  int value;
  uint32_t magic;
} sem_t;

#define SEM_FAILED	((sem_t*)0)
#define SEM_VALUE_MAX	((int)((~0u)>>1))
#define SEM_MAGIC	0x35d108f2

int sem_destroy(sem_t*sem) __THROW;
int sem_getvalue(sem_t*sem,int*sval) __THROW;
int sem_init(sem_t*sem,int pshared,unsigned int value) __THROW;
int sem_post(sem_t*sem) __THROW;
int sem_trywait(sem_t*sem) __THROW;
int sem_wait(sem_t*sem) __THROW;

sem_t*sem_open(const char*name,int oflag,...) __THROW;
int sem_close(sem_t*sem) __THROW;
int sem_unlink(const char*name) __THROW;

int sem_timedwait(sem_t*sem,const struct timespec*abstime) __THROW;

__END_DECLS

#endif

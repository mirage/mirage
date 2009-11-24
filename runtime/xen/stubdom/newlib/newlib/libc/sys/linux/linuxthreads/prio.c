#include <stddef.h>
#include <unistd.h>
#include <errno.h>
#include "pthread.h"
#include "internals.h"
#include <bits/posix_opt.h>

#ifndef _POSIX_THREAD_PRIO_PROTECT
int
__pthread_mutexattr_getprotocol (const pthread_mutexattr_t *attr,
                                 int *priority)
{
  errno = ENOSYS;
  return ENOSYS;
}
weak_alias(__pthread_mutexattr_getprotocol,pthread_mutexattr_getprotocol)

int
__pthread_mutexattr_setprotocol (pthread_mutexattr_t *attr,
                                 int priority)
{
  errno = ENOSYS;
  return ENOSYS;
}
weak_alias(__pthread_mutexattr_setprotocol,pthread_mutexattr_setprotocol)

int
__pthread_mutexattr_getprioceiling (const pthread_mutexattr_t *attr,
                                    int *prioceiling)
{
  errno = ENOSYS;
  return ENOSYS;
}
weak_alias(__pthread_mutexattr_getprioceiling,pthread_mutexattr_getprioceiling)

int
__pthread_mutexattr_setprioceiling (pthread_mutexattr_t *attr,
                                    int prioceiling)
{
  errno = ENOSYS;
  return ENOSYS;
}
weak_alias(__pthread_mutexattr_setprioceiling,pthread_mutexattr_setprioceiling)
#endif /* !_POSIX_THREAD_PRIO_PROTECT */

#if !defined(_POSIX_THREAD_PRIO_PROTECT) && !defined(_POSIX_THREAD_PRIO_INHERIT)
int
__pthread_mutex_getprioceiling (const pthread_mutex_t *mutex,
                                int *prioceiling)
{
  errno = ENOSYS;
  return ENOSYS;
}
weak_alias(__pthread_mutex_getprioceiling,pthread_mutex_getprioceiling)

int
__pthread_mutex_setprioceiling (pthread_mutex_t *mutex,
                                int prioceiling, int *oldceiling)
{
  errno = ENOSYS;
  return ENOSYS;
}
weak_alias(__pthread_mutex_setprioceiling,pthread_mutex_setprioceiling)
#endif /* !_POSIX_THREAD_PRIO_PROTECT && !_POSIX_THREAD_PRIO_INHERIT) */


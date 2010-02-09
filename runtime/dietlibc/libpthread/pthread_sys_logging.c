#include <unistd.h>
#include <stdarg.h>

#include <pthread.h>
#include "thread_internal.h"

#include <syslog.h>

static pthread_mutex_t mutex_syslog=PTHREAD_MUTEX_INITIALIZER;

void closelog(void) {
  pthread_cleanup_push((void(*)(void*))pthread_mutex_unlock,&mutex_syslog);
  pthread_mutex_lock(&mutex_syslog);
  __libc_closelog();
  pthread_cleanup_pop(1);
}

void openlog(const char*ident,int option,int facility) {
  pthread_cleanup_push((void(*)(void*))pthread_mutex_unlock,&mutex_syslog);
  pthread_mutex_lock(&mutex_syslog);
  __libc_openlog(ident, option, facility);
  pthread_cleanup_pop(1);
}

void vsyslog(int priority,const char*format,va_list arg_ptr) {
  pthread_cleanup_push((void(*)(void*))pthread_mutex_unlock,&mutex_syslog);
  pthread_mutex_lock(&mutex_syslog);
  __libc_vsyslog(priority, format, arg_ptr);
  pthread_cleanup_pop(1);
}

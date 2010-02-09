#include <unistd.h>
#include <pthread.h>

int pthread_self() {
  return getpid();
}


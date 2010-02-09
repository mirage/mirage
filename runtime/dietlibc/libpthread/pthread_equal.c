#include <pthread.h>

int pthread_equal(pthread_t thread1, pthread_t thread2) {
  return (thread1==thread2);
}

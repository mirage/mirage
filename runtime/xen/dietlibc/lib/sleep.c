#include <unistd.h>
#include <time.h>

unsigned int sleep(unsigned int secs) {
  struct timespec t;
  t.tv_sec=secs;
  t.tv_nsec=0;
  nanosleep(&t,&t);
  return secs-t.tv_sec;
}


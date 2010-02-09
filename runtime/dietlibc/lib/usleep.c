#include <time.h>
#include <unistd.h>

/* nano * 1000 == usecs
 * usecs * 1000 == msecs
 * msecs * 1000 = secs */
int usleep(unsigned long usecs) {
  struct timespec t;
  t.tv_sec=usecs/1000000;
  t.tv_nsec=(usecs%1000000)*1000;
  return nanosleep(&t,&t);
}

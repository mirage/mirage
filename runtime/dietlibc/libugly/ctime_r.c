#include <time.h>

char *ctime_r(const time_t *timep, char* buf) {
  return asctime_r(localtime(timep),buf);
}

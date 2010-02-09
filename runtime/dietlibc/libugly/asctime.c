#include <time.h>

static char buf[25];

char *asctime(const struct tm *timeptr) {
  return asctime_r(timeptr,buf);
}

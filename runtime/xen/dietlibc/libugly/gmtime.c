#include <time.h>

struct tm* gmtime(const time_t *t) {
  static struct tm tmp;
  return gmtime_r(t,&tmp);
}

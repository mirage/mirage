#include <time.h>

struct tm* localtime(const time_t* t) {
  static struct tm tmp;
  return localtime_r(t,&tmp);
}

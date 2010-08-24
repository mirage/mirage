#include <time.h>
#include <sys/timex.h>

int adjtime (const struct timeval *itv, struct timeval *otv) {
  struct timex tmp;
  if (itv) {
    tmp.offset = (itv->tv_usec % 1000000L) + (itv->tv_sec + itv->tv_usec / 1000000L) * 1000000L;
    tmp.modes = ADJ_OFFSET_SINGLESHOT;
  } else
    tmp.modes = 0;
  if (adjtimex(&tmp)==-1)
    return -1;
  if (otv) {
    otv->tv_usec = tmp.offset % 1000000;
    otv->tv_sec  = tmp.offset / 1000000;
  }
  return 0;
}

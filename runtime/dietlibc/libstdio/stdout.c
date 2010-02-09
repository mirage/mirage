#include <dietstdio.h>

static char __stdout_buf[BUFSIZE];
static FILE __stdout = {
  .fd=1,
  .flags=BUFLINEWISE|STATICBUF|CANWRITE,
  .bs=0, .bm=0,
  .buflen=BUFSIZE,
  .buf=__stdout_buf,
  .next=0,
  .popen_kludge=0,
  .ungetbuf=0,
  .ungotten=0,
#ifdef WANT_THREAD_SAFE
  .m=PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP,
#endif
};

FILE *stdout=&__stdout;

int __fflush_stdout(void) {
  return fflush(stdout);
}

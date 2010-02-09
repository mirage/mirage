#include <dietstdio.h>

static char __stdin_buf[BUFSIZE];
static FILE __stdin = {
  .fd=0,
  .flags=BUFINPUT|BUFLINEWISE|STATICBUF|CANREAD,
  .bs=0, .bm=0,
  .buflen=BUFSIZE,
  .buf=__stdin_buf,
  .next=0,
  .popen_kludge=0,
  .ungetbuf=0,
  .ungotten=0,
#ifdef WANT_THREAD_SAFE
  .m=PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP,
#endif
};

int __stdin_is_tty() {
  static int iknow;
  if (!iknow) iknow=isatty(0)+1;
  return (iknow-1);
}

FILE *stdin=&__stdin;

int __fflush_stdin(void) {
  return fflush(stdin);
}

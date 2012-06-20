#include <stdlib.h>
#include <unistd.h>

typedef void (*function)(void);

#define NUM_ATEXIT	32

static function __atexitlist[NUM_ATEXIT];
static int atexit_counter;

int atexit(function t) {
  if (atexit_counter<NUM_ATEXIT) {
    __atexitlist[atexit_counter]=t;
    ++atexit_counter;
    return 0;
  }
  return -1;
}

void __libc_exit(int code) {
  register int i=atexit_counter;
  while(i) {
    __atexitlist[--i]();
  }
  _exit(code);
}
void exit(int code) __attribute__((alias("__libc_exit")));

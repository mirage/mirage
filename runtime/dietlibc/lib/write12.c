#include <unistd.h>
#include <string.h>
#include <write12.h>

#if defined(__i386__)
#define REGPARM(x) __attribute__((regparm(x)))
#else
#define REGPARM(x)
#endif

ssize_t REGPARM(1) __write1 (const char* s) {
  return write(1, s, strlen(s));
}

ssize_t REGPARM(1) __write2 (const char* s) {
  return write(2, s, strlen(s));
}

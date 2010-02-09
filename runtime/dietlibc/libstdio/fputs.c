#include "dietstdio.h"
#include <string.h>

int fputs_unlocked(const char*s,FILE*stream) {
  return fwrite_unlocked(s,strlen(s),1,stream);
}

int fputs(const char*s,FILE*stream) __attribute__((weak,alias("fputs_unlocked")));

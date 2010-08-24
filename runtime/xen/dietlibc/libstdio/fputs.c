#include "dietstdio.h"
#include <string.h>

int fputs(const char*s,FILE*stream) {
  return fwrite(s,strlen(s),1,stream);
}

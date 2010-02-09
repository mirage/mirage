#include <stdlib.h>
#include <unistd.h>

char* getlogin(void) {
  return getenv("LOGNAME");
}

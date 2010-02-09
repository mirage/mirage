#define _GNU_SOURCE
#include <stdlib.h>

int clearenv(void) {
  environ=0;
  return 0;
}

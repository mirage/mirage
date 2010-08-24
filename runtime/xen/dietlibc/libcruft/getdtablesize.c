#include <unistd.h>
#include <limits.h>

int getdtablesize(void) {
  return OPEN_MAX;
}

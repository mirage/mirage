#include <stdio.h>
#include <mntent.h>

FILE *setmntent(const char *filename, const char *type) {
  return fopen(filename,type);
}


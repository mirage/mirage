#define _FILE_OFFSET_BITS 64
#include <dirent.h>
#include <stdio.h>
#include <errno.h>

int main() {
  DIR* D=opendir(".");
  struct dirent* d;
  if (!D) {
    perror("opendir");
    return 1;
  }
  while ((d=readdir(D))) {
    printf("found %s\n",d->d_name);
  }
  return 0;
}

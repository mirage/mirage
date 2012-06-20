#include <stdio.h>
#include <ftw.h>

int traverse(const char* file, const struct stat* sb, int flag) {
  printf("found %s\n",file);
  return 0;
}

int main() {
  ftw("/tmp",traverse,10);
  return 0;
}

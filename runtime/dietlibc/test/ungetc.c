#include <stdio.h>

int main() {
  ungetc(23,stdin);
  if (fgetc(stdin) != 23) return 1;
  ungetc(230,stdin);
  if (fgetc(stdin) != 230) return 1;
  return 0;
}

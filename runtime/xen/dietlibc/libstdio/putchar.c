#include <stdio.h>

#undef putchar
int putchar(int c) {
  return fputc(c,stdout);
}

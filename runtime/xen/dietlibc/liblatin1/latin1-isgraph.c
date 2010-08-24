#include <ctype.h>

int isgraph(int x) {
  unsigned char c=x&0xff;
  return (c>=33 && c<=126) || c>=161;
}


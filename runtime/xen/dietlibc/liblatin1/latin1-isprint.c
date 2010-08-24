#include <ctype.h>

int isprint(int x) {
  unsigned char c=x&0xff;
  return (c>=32 && c<=126) || (c>=160);
}

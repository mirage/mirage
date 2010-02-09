#include <ctype.h>

int iscntrl(int x) {
  unsigned char c=x&0xff;
  return (c<32) || (c>=127 && c<=160);
}

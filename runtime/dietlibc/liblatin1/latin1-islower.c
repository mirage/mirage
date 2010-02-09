#include <ctype.h>

int islower(int c) {
  unsigned char x=c&0xff;
  return (x>='a' && x<='z') || (x>=223 && x!=247);
}

#include <ctype.h>

int isupper(int c) {
  unsigned char x=c&0xff;
  return (x>='A' && x<='Z') || (x>=192 && x<=222 && x!=215);
}

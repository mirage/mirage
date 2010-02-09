#ifndef __GNU_HASH_H__
#define __GNU_HASH_H__

#include <stdint.h>

static uint_fast32_t gnu_hash(const unsigned char *s) {
  unsigned char c;
  uint_fast32_t h=5381;
  for(c=*s;(c!='\0');c=*++s) {
//    h=h*33+c;
    h=((h<<5)+h)+c;
  }
  return (h&0xffffffff);
}

#endif

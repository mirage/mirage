#include <endian.h>
#include <netinet/in.h>

uint16_t htons(uint16_t hostshort) {
#if __BYTE_ORDER==__LITTLE_ENDIAN
  return ((hostshort>>8)&0xff) | (hostshort<<8);
#else
  return hostshort;
#endif
}

uint16_t ntohs(uint16_t hostshort) __attribute__((weak,alias("htons")));

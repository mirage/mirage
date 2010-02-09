#include <endian.h>
#include <netinet/in.h>

uint32_t htonl(uint32_t hostlong) {
#if __BYTE_ORDER==__LITTLE_ENDIAN
  return (hostlong>>24) | ((hostlong&0xff0000)>>8) |
	  ((hostlong&0xff00)<<8) | (hostlong<<24);
#else
  return hostlong;
#endif
}

uint32_t ntohl(uint32_t hostlong) __attribute__((weak,alias("htonl")));

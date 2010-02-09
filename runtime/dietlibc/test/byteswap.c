#include <assert.h>
#include <byteswap.h>
#include <stdio.h>
#include <string.h>

int main() {
  char buf[100];
  printf("%x %x\n",bswap_16(0x1234),bswap_16(0x5678));
  snprintf(buf,100,"%x %x", bswap_16(0x1234), bswap_16(0x5678));
  assert(strcmp(buf, "3412 7856") == 0);
  
  printf("%lx\n",bswap_32(0x12345678));
  snprintf(buf,100,"%lx", bswap_32(0x12345678));
  assert(strcmp(buf, "78563412") == 0);

  printf("%qx\n",bswap_64(0x123456789ABCDEFull));
  snprintf(buf,100,"%qx", bswap_64(0x123456789ABCDEFull));
  assert(strcmp(buf, "efcdab8967452301") == 0);
  return 0; 
}

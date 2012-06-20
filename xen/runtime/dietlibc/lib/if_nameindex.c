#include <net/if.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <stdio.h>

struct if_nameindex* if_nameindex(void) {
  struct ifconf ic;
  int fd,len,i;
  struct if_nameindex* x=0,* y;
  char *dest;
  fd=socket(AF_INET6,SOCK_DGRAM,0);
  if (fd<0) fd=socket(AF_INET,SOCK_DGRAM,0);
  ic.ifc_buf=0;
  ic.ifc_len=0;
  if (ioctl(fd,SIOCGIFCONF,&ic)<0) goto b0rken;
  ic.ifc_buf=alloca((size_t)ic.ifc_len);
  if (ioctl(fd,SIOCGIFCONF,&ic)<0) goto b0rken;
  len=(ic.ifc_len/sizeof(struct ifreq));
  x=(struct if_nameindex*)malloc((len+1)*sizeof(struct if_nameindex)+len*IFNAMSIZ);
  if (!x) goto b0rken;
  dest=(char*)(x+len+1);
  y=x;
  for (i=0; i<len; ++i) {
    struct ifreq* ir=(struct ifreq*)&ic.ifc_req[i];
    y->if_name=dest;
    memcpy(dest,ir->ifr_name,IFNAMSIZ);
    if (ioctl(fd,SIOCGIFINDEX,ir)==-1) continue;
    y->if_index=ir->ifr_ifindex;
    dest+=IFNAMSIZ;
    ++y;
  }
  y->if_name=0; y->if_index=0;
b0rken:
  close(fd);
  return x;
}

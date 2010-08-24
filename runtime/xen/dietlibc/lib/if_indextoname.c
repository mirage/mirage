#include <net/if.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <sys/socket.h>

#ifndef SOCK_DGRAM
#define SOCK_DGRAM 2
#endif

char* if_indextoname(unsigned int interface,char* blub) {
  struct ifreq ifr;
  int fd;

  fd=socket(AF_INET6,SOCK_DGRAM,0);
  if (fd<0) fd=socket(AF_INET,SOCK_DGRAM,0);
  ifr.ifr_ifindex=interface;
  if (ioctl(fd,SIOCGIFNAME,&ifr)==0) {
    int i;
    close(fd);
    for (i=0; i<IFNAMSIZ-1; i++)
      if (!(blub[i]=ifr.ifr_name[i]))
	return blub;
    blub[i]=0;
    return blub;
  }
  close(fd);
  return 0;
}

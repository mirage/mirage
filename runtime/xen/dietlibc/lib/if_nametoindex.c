#include <net/if.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <sys/socket.h>

#ifndef SOCK_DGRAM
#define SOCK_DGRAM 2
#endif

unsigned int if_nametoindex(const char* blub) {
  struct ifreq ifr;
  int fd;
  int ret=0;
  char *tmp;
  int len=sizeof(ifr.ifr_name);
  fd=socket(AF_INET6,SOCK_DGRAM,0);
  if (fd<0) fd=socket(AF_INET,SOCK_DGRAM,0);
  for (tmp=ifr.ifr_name; len>0; --len) {
    if ((*tmp++=*blub++)==0) break;
  }
  if (ioctl(fd,SIOCGIFINDEX,&ifr)==0)
    ret=ifr.ifr_ifindex;
  close(fd);
  return ret;
}

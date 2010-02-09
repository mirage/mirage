#include <string.h>
#include <netdb.h>

extern struct servent __servent_pw;
extern char __servent_buf[1000];

struct servent *getservbyport(int port, const char *proto) {
  struct servent* tmp;
  if (getservbyport_r(port,proto,&__servent_pw,__servent_buf,sizeof(__servent_buf),&tmp)==0)
    return tmp;
  return 0;
}

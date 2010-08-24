#include <string.h>
#include <netdb.h>

extern struct servent __servent_pw;
extern char __servent_buf[1000];

struct servent *getservbyname(const char *name, const char *proto) {
  struct servent* tmp;
  if (getservbyname_r(name,proto,&__servent_pw,__servent_buf,sizeof(__servent_buf),&tmp)==0)
    return tmp;
  return 0;
}

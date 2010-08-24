#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include "dietwarning.h"

static const int hostentsize=((sizeof(struct hostent)+15)&(-16));

extern size_t __dns_buflen;
extern char* __dns_buf;
extern void __dns_makebuf(size_t x);

struct hostent* gethostbyname2(const char *host,int AF) {
  struct hostent *hostbuf;
  struct hostent *hp;
  int res;
  int herr;

  __dns_buflen=512;
  do {
    __dns_makebuf(__dns_buflen*2); if (!__dns_buf) return 0;
    hostbuf=(struct hostent*)__dns_buf;
  } while ((res = gethostbyname2_r (host, AF, hostbuf,
				    __dns_buf+hostentsize,
				    __dns_buflen-hostentsize, &hp,
				    &herr)) == ERANGE);
  if (res) hp=0;
  return hp;
}

link_warning("gethostbyname2","warning: gethostbyname2() leaks memory.  Use gethostbyname2_r instead!")

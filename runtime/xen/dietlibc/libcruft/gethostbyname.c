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

struct hostent* gethostbyname (const char *host) {
  struct hostent *hostbuf;
  struct hostent *hp;
  int res;

  __dns_buflen=512;
  do {
    __dns_makebuf(__dns_buflen*2); if (!__dns_buf) return 0;
    hostbuf=(struct hostent*)__dns_buf;
  } while ((res = gethostbyname_r (host, hostbuf, __dns_buf+hostentsize,
				   __dns_buflen-hostentsize, &hp,
				   &h_errno)) == ERANGE);
  if (res) hp=0;
  return hp;
}

link_warning("gethostbyname","warning: gethostbyname() leaks memory.  Use gethostbyname_r instead!")

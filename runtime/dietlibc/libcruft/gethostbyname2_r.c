#include <string.h>
#include <strings.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include "dietfeatures.h"
#include <errno.h>
#include "dietdns.h"

/* Oh boy, this interface sucks so badly, there are no words for it.
 * Not one, not two, but _three_ error signalling methods!  (*h_errnop
 * nonzero?  return value nonzero?  *RESULT zero?)  The glibc goons
 * really outdid themselves with this one. */
int gethostbyname2_r(const char* name, int AF, struct hostent* result,
				char *buf, size_t buflen,
				struct hostent **RESULT, int *h_errnop) {
  size_t L=strlen(name);
  int lookfor=0;
  switch (AF) {
  case AF_INET: lookfor=1; break;
  case AF_INET6: lookfor=28; break;
  default: *h_errnop=EINVAL; return 1;
  }
  result->h_name=buf;
  if (buflen<L) { *h_errnop=ERANGE; return 1; }
#ifdef WANT_ETC_HOSTS
  {
    int foundsomething=0;
    struct hostent* r;
    while ((r=gethostent_r(buf,buflen))) {
      int i;
      if (!strcasecmp(r->h_name,name)) {
	foundsomething=1;
        if (r->h_addrtype==AF) {	/* found it! */
found:
	  memmove(result,r,sizeof(struct hostent));
	  *RESULT=result;
	  *h_errnop=0;
	  endhostent();
	  return 0;
	}
      }
      for (i=0; i<16; ++i) {
	if (r->h_aliases[i]) {
	  if (!strcasecmp(r->h_aliases[i],name)) {
	    foundsomething=1;
	    if (r->h_addrtype==AF)
	      goto found;
	  }
	} else break;
      }
    }
    endhostent();
    if (foundsomething) {
      *h_errnop=NO_DATA;
      return -1;
    }
  }
#endif
  strcpy(buf,name);
  return __dns_gethostbyx_r(name,result,buf+L,buflen-L,RESULT,h_errnop,lookfor);
}

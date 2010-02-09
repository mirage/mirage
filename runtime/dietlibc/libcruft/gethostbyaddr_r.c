#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include "dietfeatures.h"
#include "dietdns.h"

static int i2a(char* dest,unsigned int x) {
  register unsigned int tmp=x;
  register int len=0;
  if (x>=100) { *dest++=tmp/100+'0'; tmp=tmp%100; ++len; }
  if (x>=10) { *dest++=tmp/10+'0'; tmp=tmp%10; ++len; }
  *dest++=tmp+'0';
  return len+1;
}

static char hexdigit(char c) {
  return c>9?c-10+'a':c+'0';
}

/* Oh boy, this interface sucks so badly, there are no words for it.
 * Not one, not two, but _three_ error signalling methods!  (*h_errnop
 * nonzero?  return value nonzero?  *RESULT zero?)  The glibc goons
 * really outdid themselves with this one. */
int gethostbyaddr_r(const char* addr, size_t length, int format,
		    struct hostent* result, char *buf, size_t buflen,
		    struct hostent **RESULT, int *h_errnop) {
  char tmpbuf[100];
  char* tmp;
  int res;
  (void)length;	/* shut gcc up about unused length.  The length is implicit with format */
#ifdef WANT_ETC_HOSTS
  {
    struct hostent* r;
    while ((r=gethostent_r(buf,buflen))) {
      if (r->h_addrtype==format && !memcmp(r->h_addr_list[0],addr,r->h_length)) {	/* found it! */
	memmove(result,r,sizeof(struct hostent));
	*RESULT=result;
	*h_errnop=0;
	return 0;
      }
    }
    endhostent();
  }
#endif
  if (format==AF_INET) {
    tmp=tmpbuf+i2a(tmpbuf,(unsigned char)addr[3]); *tmp++='.';
    tmp+=i2a(tmp,(unsigned char)addr[2]); *tmp++='.';
    tmp+=i2a(tmp,(unsigned char)addr[1]); *tmp++='.';
    tmp+=i2a(tmp,(unsigned char)addr[0]); strcpy(tmp,".in-addr.arpa");
  } else if (format==AF_INET6) {
    int i;
    tmp=tmpbuf;
    for (i=15; i>=0; --i) {
      tmp[0]=hexdigit(addr[i]&0xf);
      tmp[1]='.';
      tmp[2]=hexdigit((addr[i]>>4)&0xf);
      tmp[3]='.';
      tmp+=4;
    }
    strcpy(tmp,".ip6.arpa");
  } else return 1;
  if (buflen<sizeof(struct hostent)+16) {
    errno=ENOMEM;
    *h_errnop=NO_RECOVERY;
    return 1;
  }
  res= __dns_gethostbyx_r(tmpbuf,result,buf+16,buflen-16,RESULT,h_errnop,12);	/* 12 == ns_t_ptr */
  if (res==0) {
    if (format==AF_INET) {
      result->h_length=4;
      result->h_addrtype=format;
    }
    memcpy(buf,addr,result->h_length);
    result->h_addr_list[0]=buf;
    result->h_addr_list[1]=0;
  }
  return res;
}

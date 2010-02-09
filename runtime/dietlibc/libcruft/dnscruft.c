#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#include <fcntl.h>
#include <arpa/inet.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <resolv.h>
#include <net/if.h>
#include "dietfeatures.h"

int __dns_fd=-1;
#ifdef WANT_IPV6_DNS
int __dns_fd6=-1;
#endif

/* the ad-hoc internal API from hell ;-) */
void __dns_make_fd(void);
void __dns_make_fd6(void);
void __dns_readstartfiles(void);
int __dns_decodename(const unsigned char *packet,unsigned int offset,unsigned char *dest,
		     unsigned int maxlen,const unsigned char* behindpacket);

void __dns_make_fd(void) {
  int tmp;
  struct sockaddr_in si;
  if (__dns_fd>=0) return;
  tmp=socket(PF_INET,SOCK_DGRAM,IPPROTO_UDP);
  if (tmp<0) return;
  fcntl(tmp,F_SETFD,FD_CLOEXEC);
  si.sin_family=AF_INET;
  si.sin_port=0;
  si.sin_addr.s_addr=INADDR_ANY;
  if (bind(tmp,(struct sockaddr*)&si,sizeof(si))) return;
  __dns_fd=tmp;
}

#ifdef WANT_IPV6_DNS
void __dns_make_fd6(void) {
  int tmp;
  struct sockaddr_in6 si;
  if (__dns_fd6>=0) return;
  tmp=socket(PF_INET6,SOCK_DGRAM,IPPROTO_UDP);
  if (tmp<0) return;
  fcntl(tmp,F_SETFD,FD_CLOEXEC);
  memset(&si,0,sizeof(si));
  si.sin6_family=AF_INET6;
  if (bind(tmp,(struct sockaddr*)&si,sizeof(si))) return;
  __dns_fd6=tmp;
}
#endif

static int parsesockaddr(const char* c,void* x) {
  struct sockaddr_in to;
  if (inet_aton(c,&to.sin_addr)) {
    to.sin_port=htons(53);
    to.sin_family=AF_INET;
    memmove(x,&to,sizeof(struct sockaddr_in_pad));
    return 1;
#ifdef WANT_IPV6_DNS
  } else {
    struct sockaddr_in6 to6;
    char* d=strchr(c,'%');
    to6.sin6_flowinfo=to6.sin6_scope_id=0;
    if (d)
      to6.sin6_scope_id=if_nametoindex(d+1);
    if (inet_pton(AF_INET6,c,&to6.sin6_addr)) {
      to6.sin6_port=htons(53);
      to6.sin6_family=AF_INET6;
      memmove(x,&to6,sizeof(struct sockaddr_in_pad));
      return 1;
    }
#endif
  }
  return 0;
}

#ifdef WANT_FULL_RESOLV_CONF
unsigned int __dns_search;
char *__dns_domains[8];
#endif

void __dns_readstartfiles(void) {
  int fd;
  char __buf[4096];
  char *buf=__buf;
  int len;
  if (_res.nscount>0) return;
  {
    char *cacheip=getenv("DNSCACHEIP");
#ifdef WANT_FULL_RESOLV_CONF
    __dns_search=0;
#endif
    if (cacheip)
      if (parsesockaddr(cacheip,_res.nsaddr_list))
	++_res.nscount;
  }
  _res.options=RES_RECURSE;
  if ((fd=open("/etc/resolv.conf",O_RDONLY))<0) return;
  len=read(fd,buf,4096);
  close(fd);
  {
    char *last=buf+len;
    for (; buf<last;) {
      if (!strncmp(buf,"nameserver",10)) {
	buf+=10;
	while (buf<last && *buf!='\n') {
	  while (buf<last && isblank(*buf)) ++buf;
	  {
	    char *tmp=buf;
	    struct sockaddr_in i;
	    char save;
	    while (buf<last && !isspace(*buf)) ++buf;
	    if (buf>=last) break;
	    save=*buf;
	    *buf=0;
	    if (parsesockaddr(tmp,&_res.nsaddr_list[_res.nscount]))
	      if (_res.nscount<MAXNS) ++_res.nscount;
	    *buf=save;
	  }
	}
      }
#ifdef WANT_FULL_RESOLV_CONF
      else if ((!strncmp(buf,"search",6) || !strncmp(buf,"domain",6)) &&
	       (__dns_search < sizeof(__dns_domains)/sizeof(__dns_domains[0]))) {
	buf+=6;
	while (buf<last && *buf!='\n') {
	  char save;
	  while (buf<last && (*buf==',' || isblank(*buf))) ++buf;
	  __dns_domains[__dns_search]=buf;
	  while (buf<last && (*buf=='.' || *buf=='-' || isalnum(*buf))) ++buf;
	  save=*buf;
	  if (buf<last) *buf=0;
	  if (__dns_domains[__dns_search]<buf &&
	      (__dns_domains[__dns_search]=strdup(__dns_domains[__dns_search])))
	    ++__dns_search;
	  if (buf<last) *buf=save;
	}
	continue;
      }
#endif
      while (buf<last && *buf!='\n') ++buf;
      while (buf<last && *buf=='\n') ++buf;
    }
  }
}

/* return length of decoded data or -1 */
int __dns_decodename(const unsigned char *packet,unsigned int offset,unsigned char *dest,
		     unsigned int maxlen,const unsigned char* behindpacket) {
  const unsigned char *tmp;
  const unsigned char *max=dest+maxlen;
  const unsigned char *after=packet+offset;
  int ok=0;
  for (tmp=after; maxlen>0&&*tmp; ) {
    if (tmp>=behindpacket) return -1;
    if ((*tmp>>6)==3) {		/* goofy DNS decompression */
      unsigned int ofs=((unsigned int)(*tmp&0x3f)<<8)|*(tmp+1);
      if (ofs>=(unsigned int)offset) return -1;	/* RFC1035: "pointer to a _prior_ occurrance" */
      if (after<tmp+2) after=tmp+2;
      tmp=packet+ofs;
      ok=0;
    } else {
      unsigned int duh;
      if (dest+*tmp+1>max) return -1;
      if (tmp+*tmp+1>=behindpacket) return -1;
      for (duh=*tmp; duh>0; --duh)
	*dest++=*++tmp;
      *dest++='.'; ok=1;
      ++tmp;
      if (tmp>after) { after=tmp; if (!*tmp) ++after; }
    }
  }
  if (ok) --dest;
  *dest=0;
  return after-packet;
}

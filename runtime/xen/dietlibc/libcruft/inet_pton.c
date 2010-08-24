#include <stdlib.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <errno.h>
#include <string.h>
#include "dietfeatures.h"

static unsigned int scan_ip6(const char *s,char ip[16])
{
  unsigned int i;
  unsigned int len=0;
  unsigned long u;

  char suffix[16];
  unsigned int prefixlen=0;
  unsigned int suffixlen=0;

  for (i=0; i<16; i++) ip[i]=0;

  for (;;) {
    if (*s == ':') {
      len++;
      if (s[1] == ':') {	/* Found "::", skip to part 2 */
	s+=2;
	len++;
	break;
      }
      s++;
    }
    {
      char *tmp;
      u=strtoul(s,&tmp,16);
      i=tmp-s;
    }

    if (!i) return 0;
    if (prefixlen==12 && s[i]=='.') {
      /* the last 4 bytes may be written as IPv4 address */
      if (inet_aton(s,(struct in_addr*)(ip+12)))
	return i+len;
      else
	return 0;
    }
    ip[prefixlen++] = (u >> 8);
    ip[prefixlen++] = (u & 255);
    s += i; len += i;
    if (prefixlen==16)
      return len;
  }

/* part 2, after "::" */
  for (;;) {
    if (*s == ':') {
      if (suffixlen==0)
	break;
      s++;
      len++;
    } else if (suffixlen!=0)
      break;
    {
      char *tmp;
      u=strtol(s,&tmp,16);
      i=tmp-s;
    }
    if (!i) {
      if (*s) len--;
      break;
    }
    if (suffixlen+prefixlen<=12 && s[i]=='.') {
      if (inet_aton(s,(struct in_addr*)(suffix+suffixlen))) {
	suffixlen+=4;
	len+=strlen(s);
	break;
      } else
	prefixlen=12-suffixlen;	/* make end-of-loop test true */
    }
    suffix[suffixlen++] = (u >> 8);
    suffix[suffixlen++] = (u & 255);
    s += i; len += i;
    if (prefixlen+suffixlen==16)
      break;
  }
  for (i=0; i<suffixlen; i++)
    ip[16-suffixlen+i] = suffix[i];
  return len;
}

int inet_pton(int AF, const char *CP, void *BUF) {
  int len;
  if (AF==AF_INET) {
    if (!inet_aton(CP,(struct in_addr*)BUF))
      return 0;
  } else if (AF==AF_INET6) {
    if (CP[len=scan_ip6(CP,BUF)])
      if (CP[len]!='%')	/* allow "fe80::220:e0ff:fe69:ad92%eth0" */
	return 0;
  } else {
    errno=EAFNOSUPPORT;
    return -1;
  }
  return 1;
}

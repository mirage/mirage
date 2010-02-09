#include <resolv.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include <arpa/nameser.h>
#include "dietfeatures.h"

static char dnspacket[]="\xfe\xfe\001\000\000\001\000\000\000\000\000\000";

/*
                                    1  1  1  1  1  1
      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      ID                       |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |QR|   Opcode  |AA|TC|RD|RA|   Z    |   RCODE   |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    QDCOUNT                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    ANCOUNT                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    NSCOUNT                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    ARCOUNT                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
*/

extern void __dns_make_fd(void);
extern int __dns_fd;

extern int __dns_servers;
extern struct sockaddr __dns_server_ips[];

extern void __dns_readstartfiles(void);

int res_mkquery(int op, const char *dname, int class, int type, char* data,
		int datalen, const unsigned char* newrr, char* buf, int buflen) {
  unsigned char packet[512];
  unsigned long len;

  memcpy(packet,dnspacket,12);
  len=rand();
  packet[0]=len;
  packet[1]=len>>8;
  len=0;
  if ((_res.options&RES_RECURSE)==0) packet[2]=0;
  {
    unsigned char* x;
    const char* y,* tmp;
    x=packet+12; y=dname;
    while (*y) {
      while (*y=='.') ++y;
      for (tmp=y; *tmp && *tmp!='.'; ++tmp) ;
      if (tmp-y > 63) return -1;
      *x=tmp-y;
      if (!(tmp-y)) break;
      if ((len+=*x+1) > 254) return -1;
      ++x;
//      if (x>=packet+510-(tmp-y)) { return -1; }
      memmove(x,y,tmp-y);
      x+=tmp-y;
      if (!*tmp) {
	*x=0;
	break;
      }
      y=tmp;
    }
    *++x= 0; *++x= type;	/* A */
    *++x= 0; *++x= class;	/* IN */
    ++x;
    if (x-packet>buflen) return -1;
    memmove(buf,packet,x-packet);
    return x-packet;
  }
}


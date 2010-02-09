
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
#include <resolv.h>
#include "dietfeatures.h"

#ifdef WANT_FULL_RESOLV_CONF
extern int __dns_search;
extern char *__dns_domains[];

int res_search(const char *dname, int class, int type, unsigned char *answer, int anslen) {
  const char *tmp=dname;
  char Buf[MAXDNAME+1];
  int res;
  int len=strlen(dname);
  int count=0;
  memmove(Buf,dname,len);
  Buf[len]=Buf[MAXDNAME]=0;
//  printf("appending %d: %p\n",count,__dns_domains[count]);
  while ((res=res_query(tmp,class,type,answer,anslen))<0) {
    if (count==__dns_search) break;
    Buf[len]='.';
//    printf("appending %d: %p (%s)\n",count,__dns_domains[count],__dns_domains[count]);
    memccpy(Buf+len+1,__dns_domains[count],0,MAXDNAME-len-1);
    tmp=Buf;
    ++count;
  }
  return res;
}
#endif

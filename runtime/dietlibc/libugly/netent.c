#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <errno.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>
#include <ctype.h>
#include "dietfeatures.h"
#include <netdb.h>
#include <arpa/inet.h>

static int netfd=-1;
static char* netmap;
static unsigned int netlen;

static char* aliases[10];

static char *cur;

/* loopback	127.0.0.0	lo	# comment */
struct netent *getnetent(void) {
  static struct netent ne;
  char *last;
  int aliasidx;
  if (netfd<0) {
    netfd=open(_PATH_NETWORKS,O_RDONLY);
    if (netfd<0) return 0;
    fcntl (netfd, F_SETFD, FD_CLOEXEC);
    netlen=lseek(netfd,0,SEEK_END);
    netmap=mmap(0,netlen,PROT_READ|PROT_WRITE,MAP_PRIVATE,netfd,0);
    if ((long)netmap==(-1)) goto error;
    cur=netmap;
  }
  last=netmap+netlen;
again:
  ne.n_name=0;
  ne.n_aliases=aliases; aliases[0]=0;
  ne.n_addrtype=AF_INET;
  ne.n_net=0;
  if (cur>=last) return 0;
  if (*cur=='#' || *cur=='\n') goto parseerror;
  /* first, the primary name */
  if (!isalpha(*cur)) goto parseerror;
  ne.n_name=cur;
  ne.n_aliases=aliases;
  while (cur<last && isalnum(*cur)) cur++;
  if (cur>=last) return 0;
  if (*cur=='\n') goto parseerror;
  *cur=0; cur++;
  /* second, the ip */
  while (cur<last && isblank(*cur)) cur++;
  {
    const char *tmp=cur;
    char save;
    while (cur<last && (isdigit(*cur) || *cur=='.')) ++cur;
    save=*cur; *cur=0;
    if (inet_aton(tmp,(struct in_addr*)&ne.n_net)==0) goto parseerror;
    *cur=save;
  }
  if (cur>=last) return 0;
  /* now the aliases */
  for (aliasidx=0;aliasidx<10;++aliasidx) {
    while (cur<last && isblank(*cur)) ++cur;
    aliases[aliasidx]=cur;
    while (cur<last && isalpha(*cur)) ++cur;
    if (*cur=='\n') { *cur++=0; ++aliasidx; break; }
    if (cur>=last || !isblank(*cur)) break;
    *cur++=0;
  }
  aliases[aliasidx]=0;
  return &ne;
parseerror:
  while (cur<last && *cur!='\n') cur++;
  cur++;
  goto again;
error:
  if (netmap!=(char*)-1) munmap(netmap,netlen);
  if (netfd!=-1) close(netfd);
  netmap=(char*)-1;
  netfd=-1;
  errno=ENOMEM;
  return 0;
}

struct netent *getnetbyaddr(unsigned long net, int type) {
  struct netent *s;
  for (s=getnetent(); s; s=getnetent()) {
    if (net==s->n_net && type==s->n_addrtype)
      return s;
  }
  return 0;
}

void endnetent(void) {
  if (netmap!=(char*)-1) munmap(netmap,netlen);
  if (netfd!=-1) close(netfd);
  netmap=(char*)-1;
  netfd=-1;
}

void setnetent(int stayopen) {
  (void)stayopen;
  endnetent();
}

struct netent *getnetbyname(const char *name) {
  struct netent *s;
  setnetent(0);
  for (s=getnetent(); s; s=getnetent()) {
    char **tmp;
#if 0
    write(1,"found ",6);
    write(1,s->s_name,strlen(s->s_name));
    write(1,"/",1);
    write(1,s->s_proto,strlen(s->s_proto));
    write(1,"\n",1);
    if (!strcmp(s->s_name,"ssh")) {
      write(2,"ssh!\n",5);
    }
#endif
    if (!strcmp(name,s->n_name))
      return s;
    tmp=s->n_aliases;
    while (*tmp)
      if (!strcmp(name,*tmp++)) return s;
  }
  return 0;
}


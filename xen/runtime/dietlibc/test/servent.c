#include <stdio.h>
#include <netdb.h>
#include <netinet/in.h>

int main(int argc,char *argv[]) {
#ifdef NEW
  struct servent se,*tmp;
  char buf[1000];
  while (getservent_r(&se,buf,sizeof(buf),&tmp)==0) {
    int i;
    printf("name %s\tport %d\tproto %s\n",se.s_name,ntohs(se.s_port),se.s_proto);
    for (i=0; i<16; ++i) {
      if (!se.s_aliases[i]) break;
      printf("  alias %s\n",se.s_aliases[i]);
    }
  }
#else
  struct servent* se;
  while ((se=getservent())) {
    int i;
    printf("name %s\tport %d\tproto %s\n",se->s_name,ntohs(se->s_port),se->s_proto);
    for (i=0; i<16; ++i) {
      if (!se->s_aliases[i]) break;
      printf("  alias %s\n",se->s_aliases[i]);
    }
  }
#endif
  return 0;
}

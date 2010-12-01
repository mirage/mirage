#include <stdio.h>
#include <netdb.h>
#include <netinet/in.h>

int main(int argc,char *argv[]) {
  struct servent* se;
  if ((se=getservbyport(htons(80),"tcp"))) {
    int i;
    printf("name %s\tport %d\tproto %s\n",se->s_name,ntohs(se->s_port),se->s_proto);
    for (i=0; i<16; ++i) {
      if (!se->s_aliases[i]) break;
      printf("  alias %s\n",se->s_aliases[i]);
    }
  }
  return 0;
}

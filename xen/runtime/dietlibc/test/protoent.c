#include <stdio.h>
#include <netdb.h>

int main(int argc,char *argv[]) {
#ifdef NEW
  struct protoent se,*tmp;
  char buf[1000];
  while (getprotoent_r(&se,buf,sizeof(buf),&tmp)==0) {
    int i;
    printf("name %s\tproto %s\n",se.p_name,se.s_proto);
    for (i=0; i<16; ++i) {
      if (!se.p_aliases[i]) break;
      printf("  alias %s\n",se.p_aliases[i]);
    }
  }
#else
  struct protoent* se;
  while ((se=getprotoent())) {
    int i;
    printf("name %s\tproto %d\n",se->p_name,se->p_proto);
    for (i=0; i<16; ++i) {
      if (!se->p_aliases[i]) break;
      printf("  alias %s\n",se->p_aliases[i]);
    }
  }
#endif
  return 0;
}

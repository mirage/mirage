#include <netinet/in.h>
#include <netdb.h>
#include <stdio.h>
#include <arpa/inet.h>


int main() {
  struct hostent *foo;
  foo=gethostbyname("zeit.fu-berlin.de");
  if (foo) {
    int i;
    printf("%s -> %s\n",foo->h_name,inet_ntoa(*(struct in_addr*)foo->h_addr));
    for (i=0; foo->h_aliases[i]; ++i) {
      printf("  also known as %s\n",foo->h_aliases[i]);
    }
  } else return 1;
/*  printf("%g %g\n",1e-10,1e10); */

return 0;
}

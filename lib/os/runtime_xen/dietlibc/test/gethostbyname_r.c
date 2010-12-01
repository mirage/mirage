#include <arpa/inet.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

int main() {
  struct hostent host,*res;
  char buf[2048];
  int fnord;
  if (gethostbyname_r("localhost",&host,buf,2048,&res,&fnord))
    return 2;
  printf("%s -> %s\n",res->h_name,inet_ntoa(*(struct in_addr*)res->h_addr));

  assert(strcmp(res->h_name, "localhost") == 0);
  assert(strcmp((char *)inet_ntoa(*(struct in_addr*)res->h_addr), "127.0.0.1") == 0);
  return 0;
}

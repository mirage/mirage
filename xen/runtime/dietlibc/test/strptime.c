#define _XOPEN_SOURCE
#include <time.h>
#include <stdio.h>

int main() {
  char buf[1024];
  struct tm* t;
  time_t T=time(0);
  t=localtime(&T);

  strftime(buf,sizeof(buf),"%c",t);
  printf("%s\n",strptime(buf,"%c",t));

  printf("%s\n",strptime("Tue, 31 May 2005 14:16:16 GMT","%a, %d %b %Y %T",t));
  printf("%2d.%02d.%d %2d:%02d:%02d\n",t->tm_mday,t->tm_mon+1,t->tm_year+1900,t->tm_hour,t->tm_min,t->tm_sec);

  return 0;
}

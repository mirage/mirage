#include <stdio.h>
#include <sys/time.h>

int main() {
  struct timeval a,b;
  a.tv_sec=0; a.tv_usec=0;
  printf("%d\n",adjtime(&a,&b));
  return 0;
}

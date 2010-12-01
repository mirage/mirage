#include <unistd.h>
#include <sys/time.h>
#include <stdio.h>

main() {
  struct timeval t;
  printf("%d\n",gettimeofday(&t,0));
  printf("%lu %lu\n",t.tv_sec,t.tv_usec);
}

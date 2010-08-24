#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>

int main() {
  fd_set f;
  struct timeval tv;
  FD_ZERO(&f);
  tv.tv_sec=3; tv.tv_usec=0;
  select(1,&f,0,0,&tv);
  return 0;
}

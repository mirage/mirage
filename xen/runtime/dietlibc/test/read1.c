#include <unistd.h>

int main() {
  char buf[10];
  read(0,buf,1);
  return 0;
}

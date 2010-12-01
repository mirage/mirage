#include <asm/unistd.h>
#include <stdio.h>
#include <errno.h>
#include <assert.h>

int main() {
  int a,b;
  syscall(__NR_write,1,"foo\n",4);
  a=syscall(__NR_write,23,"bar\n",4);
  b=errno;
  assert(a==-1);
  assert(b==EBADF);
  return 0;
}

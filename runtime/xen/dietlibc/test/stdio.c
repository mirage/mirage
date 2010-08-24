#include <stdio.h>

int main() {
  char buf[1000];
  printf("sftp> ");
  fgets(buf,sizeof buf,stdin);
  fwrite("foo\n",2,2,stdout);
  return 0;
}

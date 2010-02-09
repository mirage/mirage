#include <stdio.h>
#include <assert.h>

int main() {
  FILE* f;
  char buf[1024];
  assert(f=popen("/bin/echo foo","r"));
  assert(fgets(buf,sizeof(buf),f));
  assert(fclose(f)==0);
  assert(!strcmp(buf,"foo\n"));
}

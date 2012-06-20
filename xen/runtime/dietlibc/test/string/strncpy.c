#include <stdio.h>
#include <string.h>
#include <assert.h>

int main() {
  char buf[100];
  assert(strncpy(buf,"fnord",6)==buf);
  assert(!strcmp(buf,"fnord"));
  memset(buf,23,sizeof buf);
  assert(strncpy(buf,"fnord",5)==buf);
  assert(!memcmp(buf,"fnord",5) && buf[5]==23);

  return 0;
}

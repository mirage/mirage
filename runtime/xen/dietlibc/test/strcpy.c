#include <string.h>
#include <assert.h>

int main() {
  char buf[128];
  size_t i;
  for (i=0; i<100; ++i) {
    memset(buf,'x',sizeof(buf));
    strcpy(buf+i,"fnord");
    assert(!strcmp(buf+i,"fnord"));
    assert(buf[i+6]=='x');
  }
}

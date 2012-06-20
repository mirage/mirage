#include <stdio.h>
#include <net/if.h>

int main() {
  struct if_nameindex* t=if_nameindex();
  if (t) {
    struct if_nameindex* t1=t;
    while (t->if_index) {
      printf("index %u: \"%s\"\n",t->if_index,t->if_name);
      ++t;
    }
    if_freenameindex(t1);
  }
  return 0;
}

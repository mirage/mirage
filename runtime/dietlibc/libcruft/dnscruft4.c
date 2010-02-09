#include <stdlib.h>
#include <sys/types.h>

size_t __dns_buflen=0;
char* __dns_buf=0;

void __dns_makebuf(size_t x);
void __dns_makebuf(size_t x) {
  char* tmp=realloc(__dns_buf,__dns_buflen=x);
  if (tmp) __dns_buf=tmp; else { free(__dns_buf);  __dns_buf=0; }
}

#define _GNU_SOURCE
#include <sys/types.h>
#include <string.h>

void* memrchr(const void *s, int c, size_t n) {
  register const char* t=s;
  register const char* last=0;
  int i;
  for (i=n; i; --i) {
    if (*t==c)
      last=t;
    ++t;
  }
  return (void*)last; /* man, what an utterly b0rken prototype */
}

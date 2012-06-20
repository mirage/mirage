#include <string.h>
#include <stdlib.h>

char *strdup(const char *s) {
  size_t l=strlen(s)+1;
  char *tmp=(char *)malloc(l);
  if (!tmp) return 0;
  return memcpy(tmp,s,l);
}

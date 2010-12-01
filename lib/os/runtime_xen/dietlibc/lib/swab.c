#include <unistd.h>

void swab(const void *src, void *dest, ssize_t nbytes)
{
  ssize_t i;
  const char *s=src;
  char *d=dest;
  nbytes&=~1;
  for (i=0; i<nbytes; i+=2) {
    d[i]=s[i+1];
    d[i+1]=s[i];
  }
}

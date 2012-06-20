#include <stdio.h>
#include <stdlib.h>

int main() {
  char* c=malloc(13);
  char* tmp;
  fprintf(stderr,"got %p\n",c);
  c[0]=14;
//  c[15]=0;
  tmp=realloc(c,12345);
  ++tmp[0];
  if (tmp[0]!=15) abort();
//  c[0]=1;
//  free(c);
  free(tmp);
//  c[0]=13;
  return 0;
}

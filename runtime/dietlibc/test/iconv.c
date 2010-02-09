#include <iconv.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>

int main() {
  iconv_t i=iconv_open("UTF-16BE","UTF-16");
  char foo[100]="\xFE\xFF\xD8\x08\xDF\x45\x00\x3D\x00\x52\x00\x61";
  char bar[100];
  char *x=foo,*y=bar;
  size_t X=12,Y=100;
  assert(iconv(i,&x,&X,&y,&Y)==0 && X==0 && Y==90);
  assert(memcmp(bar,"\xD8\x08\xDF\x45\x00\x3D\x00\x52\x00\x61",10)==0);
return 0;
}

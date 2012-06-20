#include <stdlib.h>
#include <wchar.h>
#include <stdio.h>
#include <locale.h>
#include <string.h>
#include <assert.h>
#include <errno.h>

int main() {
  wchar_t c[100];
  char buf[100];
  size_t n=0;
  c[0]='f';
  c[1]='n';
  c[2]=0xd6;
  c[3]='r';
  c[4]='d';
  c[5]=0;
  setlocale(LC_CTYPE,"de_DE.UTF8");

  assert(wctomb(buf,c[0])==1);
  assert(wctomb(buf+1,c[1])==1);
  assert(wctomb(buf+2,c[2])==2);
  assert(wctomb(buf+4,c[3])==1);
  assert(wctomb(buf+5,c[4])==1);
  buf[6]=0;
  assert(!strcmp(buf,"fn\xc3\x96rd"));

}

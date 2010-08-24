#include <stdlib.h>
#include <wchar.h>
#include <stdio.h>
#include <locale.h>
#include <string.h>
#include <assert.h>
#include <errno.h>

int main() {
  wchar_t ws;
  char* c="fn\xc3\xb6rd";
  size_t n=strlen(c);
  setlocale(LC_CTYPE,"de_DE.UTF8");

  ws=0;
  assert(mbtowc(&ws,c,6)==1 && ws==102);
  assert(mbtowc(&ws,c+1,5)==1 && ws==110);
  assert(mbtowc(&ws,c+2,4)==2 && ws==246);
  assert(mbtowc(&ws,c+4,2)==1 && ws==114);
  assert(mbtowc(&ws,c+5,1)==1 && ws==100);
  assert(mbtowc(&ws,c+6,1)==0);

  errno=0;
  c="fnörd";
  assert(mbtowc(&ws,c,6)==1 && ws==102);
  assert(mbtowc(&ws,c+1,5)==1 && ws==110);
  assert(mbtowc(&ws,c+2,4)==(size_t)-1 && errno==EILSEQ);
}

#include <wchar.h>
#include <assert.h>
#include <stdio.h>
#include <locale.h>

main() {
  static mbstate_t ps;
  setlocale(LC_CTYPE,"de_DE.UTF8");
  /* does it parse a single multibyte sequence OK? */
  assert(mbrlen("\xc2\xa9",2,&ps)==2);
  /* does it whine about an invalid sequence? */
  assert(mbrlen("\xa9",1,&ps)==(size_t)-1);
  /* does it accept a multibyte sequence in two parts? */
  printf("%d\n",mbrlen("\xc2\xa9",1,&ps));
  printf("%d\n",mbrlen("\xa9""fnord",6,&ps));
  /* does it parse non-sequence stuff right? */
  assert(mbrlen("f",1,&ps)==1);
}

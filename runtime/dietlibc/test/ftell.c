#include <stdio.h>
#include <assert.h>

int main() {
  FILE* f = popen("/bin/echo testing","r");
  int i=getc(f);
  assert(ftell(f)==-1);
  assert(getc(f) == 'e');
  pclose(f);
  f=fopen("/tmp/test","w");
  assert(ftell(f)==0);
  fputs("test",f);
  assert(ftell(f)==4);
  fclose(f);
  f=fopen("/tmp/test","r");
  assert(ftell(f)==0);
  i=getc(f);
  assert(ftell(f)==1);
  ungetc(i,f);
  assert(ftell(f)==0);
  i=getc(f);
  i=getc(f);
  assert(ftell(f)==2);
  fclose(f);
  unlink("/tmp/test");
}

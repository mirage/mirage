#include <unistd.h>
#include <stdarg.h>

static char* res[10];

void fnord(char*x,...) {
  int i;
  va_list v;
  va_start(v,x);
  for (i=0; i<10; ++i) {
    char *tmp=va_arg(v,char*);
    if (!tmp) break;
    res[i]=tmp;
  }
}

int main(int argc,char *argv[]) {
  const char foo[]="foo\n";
  const char bar[]="bar\n";
  fnord("fnord",foo,bar,0);
  if (res[0]==foo && res[1]==bar && res[2]==0) {
    write(1,"ok\n",3);
    return 0;
  }
  write(1,"fail\n",5);
  return 1;
}

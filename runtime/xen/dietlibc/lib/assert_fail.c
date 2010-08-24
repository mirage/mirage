#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "dietwarning.h"
#include <write12.h>

void __assert_fail (const char *assertion, const char *file, unsigned int line, const char *function);

void __assert_fail (const char *assertion, const char *file, unsigned int line, const char *function)
{
  unsigned int alen=strlen(assertion);
  unsigned int flen=strlen(file);
  unsigned int fulen=function?strlen(function):0;
  char *buf=(char*)alloca(alen+flen+fulen+50);
  if (buf) {
    char *tmp;
    *buf=0;
    if (file) strcat(strcat(buf,file),":");
    tmp=buf+strlen(buf);
    __ltostr(tmp,10,line,10,0);
    strcat(buf,": ");
    if (function) strcat(strcat(buf,function),": ");
    strcat(buf,"Assertion `");
    strcat(buf,assertion);
    strcat(buf,"' failed.\n");
    __write2(buf);
  }
  abort();
}

link_warning("__assert_fail","warning: your code still has assertions enabled!")

#define _BSD_SOURCE
#include <paths.h>
#include <string.h>
#undef __attribute_dontuse__
#define __attribute_dontuse__
#include <unistd.h>
#include "parselib.h"

static struct state __ps;

void setusershell(void) {
  __prepare_parse(_PATH_SHELLS,&__ps);
}

void endusershell(void) {
  __end_parse(&__ps);
}

#define MAXSHELL 128

char *getusershell(void) {
  static char line[MAXSHELL+1];
  size_t i;
  if (!__ps.buffirst) setusershell();
  if (!__ps.buffirst) goto error;
  if (__ps.cur>=__ps.buflen) goto error;
  i=__parse_1(&__ps,'\n');
  if (i>=MAXSHELL) i=MAXSHELL-1;
  memcpy(line,__ps.buffirst+__ps.cur,i);
  line[i]=0;
  __ps.cur+=i+1;
  return line;
error:
  return 0;
}

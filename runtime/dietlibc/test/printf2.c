#include <stdio.h>
#include <string.h>
#include <assert.h>

#define runtest(fmt,arg,wanted) memset(buf,0,sizeof(buf)); sprintf(buf,fmt,arg); assert(!strcmp(buf,wanted));

int main() {
  char buf[100];

  runtest("%.6u",1234,"001234");
  runtest("%6u",1234,"  1234");
  runtest("%06u",1234,"001234");
  runtest("%-6u",1234,"1234  ");
  runtest("%6.5u",1234," 01234");

  runtest("%.6s","1234","1234");
  runtest("%6s","1234","  1234");
  runtest("%06s","1234","  1234");
  runtest("%-6s","1234","1234  ");
  runtest("%6.5s","1234","  1234");

  runtest("%6.3f",1.23," 1.230");
  runtest("%6.3g",1.23,"  1.23");

  return 0;
}


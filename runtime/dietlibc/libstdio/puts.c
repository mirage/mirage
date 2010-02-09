#include <unistd.h>
#include <string.h>
#include "dietstdio.h"
#include "dietfeatures.h"

int __stdio_outs(const char *s,size_t len) __attribute__((weak));
int __stdio_outs(const char *s,size_t len) {
  return (write(1,s,len)==(ssize_t)len)?1:0;
}

int puts(const char *s) {
  return (__stdio_outs(s,strlen(s)) && __stdio_outs("\n",1))?0:-1;
}


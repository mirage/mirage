#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include "dietfeatures.h"

#ifndef O_NOFOLLOW
#define O_NOFOLLOW 0
#endif

int mkstemp(char* template) {
  char *tmp=template+strlen(template)-6;
  int randfd;
  int i,res;
  unsigned int random;
  if (tmp<template) goto error;
  for (i=0; i<6; ++i) if (tmp[i]!='X') { error: errno=EINVAL; return -1; }
  randfd=open("/dev/urandom",O_RDONLY);
  for (;;) {
    read(randfd,&random,sizeof(random));
    for (i=0; i<6; ++i) {
      int hexdigit=(random>>(i*5))&0x1f;
      tmp[i]=hexdigit>9?hexdigit+'a'-10:hexdigit+'0';
    }
    res=open(template,O_CREAT|O_RDWR|O_EXCL|O_NOFOLLOW,0600);
    if (res>=0 || errno!=EEXIST) break;
  }
  close(randfd);
  return res;
}

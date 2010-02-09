#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include "dietfeatures.h"
#include <errno.h>
#include <sys/stat.h>
#include <dietwarning.h>
#include <stdlib.h>
#include <stdio.h>

link_warning("tmpnam","\e[1;33;41m>>> tmpnam stinks! NEVER ! NEVER USE IT ! <<<\e[0m");

char* tmpnam(char* s) {
  static char buf[100];
  char *tmp;
  if (s) tmp=s; else tmp=buf;
  strcpy(tmp,"/tmp/temp_");
  for (;;) {
    struct stat s;
    int i,j;
    i=rand();
    for (j=0; j<8; ++j) {
      char c=i&0xf;
      tmp[9+j]=c>9?c+'a'-10:c+'0';
      i>>=4;
    }
    tmp[17]=0;
    if (lstat(tmp,&s)==-1 && errno==ENOENT) break;
  }
  return tmp;
}

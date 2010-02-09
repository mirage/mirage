#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

#include <dietwarning.h>

link_warning("mktemp","\e[1;33;41m>>> mktemp stinks! DON'T USE IT ! <<<\e[0m");

char* mktemp(char* template) {
  int fd;
  if ((fd=mkstemp(template))<0) return 0;
  close(fd);
  unlink(template);
  return template;
}

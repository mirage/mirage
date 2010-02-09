#define _XOPEN_SOURCE
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <stdlib.h>

int grantpt (int fd) {
  struct stat st;
  if ((fstat(fd, &st))<0) return -1;
  if ((chmod((char*)ptsname(fd), st.st_mode | S_IRUSR | S_IWUSR | S_IWGRP))<0)
    return -1;
  return 0;
}

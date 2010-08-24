#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include "dietfeatures.h"

int lockf(int fd, int cmd, off_t len) {
  struct flock fl;
  fl.l_whence=SEEK_CUR;
  fl.l_start=0;
  fl.l_len=len;
  fl.l_pid=0;
  switch (cmd) {
  case F_TEST:
    if (fcntl(fd,F_GETLK,&fl)<0)
      return -1;
    if (fl.l_type == F_UNLCK || fl.l_pid == getpid ())
      return 0;
    errno=EACCES;
    return -1;
  case F_ULOCK:
    fl.l_type=F_UNLCK;
    cmd=F_SETLK;
    break;
  case F_LOCK:
    fl.l_type = F_WRLCK;
    cmd = F_SETLKW;
    break;
  case F_TLOCK:
    fl.l_type = F_WRLCK;
    cmd = F_SETLK;
    break;
  default:
    errno=EINVAL;
    return -1;
  }
  return fcntl(fd,cmd,&fl);
}

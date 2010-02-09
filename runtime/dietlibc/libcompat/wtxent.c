#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#define _GNU_SOURCE
#include <utmpx.h>

void updwtmpx(const char *wtmpx_file, const struct utmpx *ut) {
  int fd = open(wtmpx_file, O_WRONLY|O_APPEND);
  if (fd<0) return;
  fcntl (fd, F_SETFD, FD_CLOEXEC);
  write(fd, ut, sizeof(struct utmpx));
  close(fd);
}

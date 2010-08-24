#include <sys/stat.h>
#include <unistd.h>

int mkfifo(const char *fn,mode_t mode) {
  return mknod(fn,(mode_t)(mode|S_IFIFO),0);
}

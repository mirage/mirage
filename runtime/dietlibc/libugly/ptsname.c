#define _XOPEN_SOURCE
#include <unistd.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#include <string.h>

# define MAX_FDS 4

char *ptsname(int fd) {
  static char buffer[9+MAX_FDS]; /* Ahh..great */
  int pty;

  strcpy(buffer,"/dev/pts/");
  if ((ioctl(fd, TIOCGPTN, &pty)) == -1) return 0;
  __ltostr(buffer+9, MAX_FDS, pty, 10, 0);
  return buffer;
}

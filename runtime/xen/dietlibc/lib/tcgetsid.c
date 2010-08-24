#include <termios.h>
#include <sys/ioctl.h>

pid_t tcgetsid(int fildes) {
  pid_t pid;
  return ioctl(fildes, TIOCGSID, &pid)==-1?-1:pid;
}


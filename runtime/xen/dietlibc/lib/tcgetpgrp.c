#include <termios.h>
#include <sys/ioctl.h>
#include <unistd.h>

pid_t tcgetpgrp(int fildes)
{
  int32_t foo = -1;
  if (ioctl(fildes, TIOCGPGRP, &foo)==-1)
    return -1;
  else
    return foo;
}

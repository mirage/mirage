#include <termios.h>
#include <sys/ioctl.h>
#include <unistd.h>

int tcsetpgrp(int fildes, pid_t pgrpid)
{
  return ioctl(fildes, TIOCSPGRP, &pgrpid);
}

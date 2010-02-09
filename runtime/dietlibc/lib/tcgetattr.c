#include <termios.h>
#include <sys/ioctl.h>

int tcgetattr(int fildes, struct termios *termios_p)
{
  return ioctl(fildes, TCGETS, termios_p);
}

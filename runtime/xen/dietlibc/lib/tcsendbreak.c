#include "dietfeatures.h"
#include <errno.h>
#include <termios.h>
#include <sys/ioctl.h>

int tcsendbreak (int fd,int duration)
{
  if (duration <= 0) return (ioctl (fd,TCSBRKP,0));
  errno = EINVAL;
  return (-1);
}

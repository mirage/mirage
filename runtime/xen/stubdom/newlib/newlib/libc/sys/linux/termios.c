/* libc/sys/linux/termios.c - Terminal control */

/* Written 2000 by Werner Almesberger */


#include <errno.h>
#include <sys/types.h>
#include <sys/termios.h>
#include <sys/ioctl.h>


int 
tcgetattr(int fd,struct termios *termios_p)
{
  return ioctl(fd,TCGETS,termios_p);
}


int 
tcsetattr(int fd,int optional_actions,const struct termios *termios_p)
{
  int cmd;

  switch (optional_actions) {
    case TCSANOW:
      cmd = TCSETS;
    break;
    case TCSADRAIN:
      cmd = TCSETSW;
    break;
    case TCSAFLUSH:
      cmd = TCSETSF;
    break;
    default:
      errno = EINVAL;
      return -1;
    }
  return ioctl(fd,cmd,termios_p);
}

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 4
pid_t 
tcgetpgrp(int fd)
{
  int p;
    
  if (ioctl(fd,TIOCGPGRP,&p) < 0)
    return (pid_t)-1;
  return (pid_t)p;
}


int 
tcsetpgrp(int fd, pid_t pid)
{
  int p = (int)pid;
  return ioctl(fd,TIOCSPGRP,&p);
}
#endif /* !_ELIX_LEVEL || _ELIX_LEVEL >= 4 */

int
tcflow (int fd, int action)
{
  return ioctl (fd, TCXONC, action);
}

int
tcflush (int fd, int queue_selector)
{
  return ioctl (fd, TCFLSH, queue_selector);
}


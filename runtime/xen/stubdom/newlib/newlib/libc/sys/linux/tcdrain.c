/* tcdrain - wait for transmission of output */

#include <termios.h>
#include <sys/ioctl.h>
#include <machine/weakalias.h>

int
__libc_tcdrain (int fd)
{ 
  return ioctl (fd, TCSBRK, 1);
}
weak_alias (__libc_tcdrain, tcdrain)


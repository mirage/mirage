#include <termios.h>
#include <errno.h>
#include "dietfeatures.h"

int cfsetospeed(struct termios *termios_p, speed_t speed) {
  if ((speed & (speed_t)~CBAUD) != 0 && (speed < B57600 || speed > B460800)) {
    errno=EINVAL;
    return -1;
  }
  termios_p->c_cflag &= ~(CBAUD | CBAUDEX);
  termios_p->c_cflag |= speed;
  return 0;
}


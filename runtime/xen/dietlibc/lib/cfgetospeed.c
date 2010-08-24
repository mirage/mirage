#include <termios.h>
#include <sys/types.h>

speed_t cfgetospeed(const struct termios *termios_p) {
  return ((termios_p->c_cflag & (CBAUD|CBAUDEX)));
}

speed_t cfgetispeed(const struct termios *termios_p)	__attribute__((weak,alias("cfgetospeed")));

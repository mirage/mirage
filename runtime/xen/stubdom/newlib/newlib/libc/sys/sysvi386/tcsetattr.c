#include <sys/termios.h>

int
tcsetattr (int fd, int opts, const struct termios *tp) {
	return _ioctl (fd, opts, tp);
}


#define _NO_MACROS
#include <sys/termios.h>

speed_t
cfgetospeed(const struct termios *tp) {
	return tp->c_ospeed;
}

int
cfsetospeed(struct termios *tp, speed_t speed) {
	tp->c_ospeed = speed;
	return 0;
}

speed_t
cfgetispeed(const struct termios *tp) {
	return tp->c_ispeed;
}

int
cfsetispeed(struct termios *tp, speed_t speed) {
	tp->c_ispeed = speed;
	return 0;
}

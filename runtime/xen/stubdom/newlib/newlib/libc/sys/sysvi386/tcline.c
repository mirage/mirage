#define _NO_MACROS
#include <sys/unistd.h>
#include <sys/termios.h>
#include <errno.h>

int
tcsendbreak (int fd, int dur) {
	do {
		if (_ioctl (fd, _TCSBRK, 0) == -1)
			return -1;
	} while (dur--);
	return 0;
}

int
tcdrain (int fd) {
	return _ioctl (fd, _TCSBRK, 1);
}

int
tcflush(int fd, int what) {
	return _ioctl (fd, _TCFLSH, what);
}

/*
 * I'm not positive about this function.  I *think* it's right,
 * but I could be missing something.
 */

int
tcflow (int fd, int action) {
	struct termios t;

	switch (action) {
	case TCOOFF:
	case TCOON:
		return _ioctl (fd, _TCXONC, action);
/*
 * Here is where I'm not terribly certain.  1003.1 says:
 * if action is TCIOFF, the system shall transmit a STOP
 * character, which is intended to cause the terminal device
 * to stop transmitting data to the system.  (Similarly for
 * TCION.)
 * I *assume* that means I find out what VSTOP for the
 * terminal device is, and then write it.  1003.1 also does
 * not say what happens if c_cc[VSTOP] is _POSIX_VDISABLE;
 * I assume it should reaturn EINVAL, so that's what I do.
 * Anyway, here's the code.  It might or might not be right.
 */
	case TCIOFF:
		if (tcgetattr (fd, &t) == -1)
			return -1;
		if (tcgetattr (fd, &t) == -1)
			return -1;
#ifdef _POSIX_VDISABLE
		if (t.c_cc[VSTOP] == _POSIX_VDISABLE) {
			errno = EINVAL;
			return -1;
		}
#endif
		if (write (fd, &t.c_cc[VSTOP], 1) == 1)
			return 0;
		else
			return -1;
	case TCION:
		if (tcgetattr (fd, &t) == -1)
			return -1;
		if (tcgetattr (fd, &t) == -1)
			return -1;
#ifdef _POSIX_VDISABLE
		if (t.c_cc[VSTART] == _POSIX_VDISABLE) {
			errno = EINVAL;
			return -1;
		}
#endif
		if (write (fd, &t.c_cc[VSTART], 1) == 1)
			return 0;
		else
			return -1;
	default:
		errno = EINVAL;
		return -1;
	}
}

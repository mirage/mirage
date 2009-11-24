#include <sys/termio.h>

int
isatty(fd)
int fd; {
	struct termio buf;

	if (ioctl (fd, TCGETA, &buf) == -1)
		return 0;
	return 1;
}

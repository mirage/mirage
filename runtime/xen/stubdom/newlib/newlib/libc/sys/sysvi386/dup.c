#include <fcntl.h>

int
dup (int fd1) {
	return (fcntl (fd1, F_DUPFD, 0));
}

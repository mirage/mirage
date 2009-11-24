#include <fcntl.h>

int
dup2 (int fd1, int fd2) {
	close (fd2);	/* ignore errors, if any */
	return (fcntl (fd1, F_DUPFD, fd2));
}

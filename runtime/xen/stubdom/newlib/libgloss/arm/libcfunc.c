/* Support files for GNU libc.  Files in the C namespace go here.
   Files in the system namespace (ie those that start with an underscore)
   go in syscalls.c.
   
   Note: These functions are in a seperate file so that OS providers can
   overrride the system call stubs (defined in syscalls.c) without having
   to provide libc funcitons as well.  */

#include "swi.h"
#include <errno.h>
#include <unistd.h>

unsigned __attribute__((weak))
alarm (unsigned seconds)
{
	(void)seconds;
	return 0;
}

clock_t _clock(void);
clock_t __attribute__((weak))
clock(void)
{
      return _clock();
}

int _isatty(int fildes);
int __attribute__((weak))
isatty(int fildes)
{
	return _isatty(fildes);
}

int __attribute__((weak))
pause(void)
{
	errno = ENOSYS;
	return -1;
}

#include <sys/types.h>
#include <time.h>

unsigned __attribute__((weak))
sleep(unsigned seconds)
{
	clock_t t0 = _clock();
	clock_t dt = seconds * CLOCKS_PER_SEC;

	while (_clock() - t0  < dt);
	return 0;
}

int __attribute__((weak))
usleep(useconds_t useconds)
{
	clock_t t0 = _clock();
	clock_t dt = useconds / (1000000/CLOCKS_PER_SEC);

	while (_clock() - t0  < dt);
	return 0;
}

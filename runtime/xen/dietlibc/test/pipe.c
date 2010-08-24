#include <unistd.h>
#include <assert.h>

int
main (void)
{
	int fd[2];
	assert (!pipe (fd));
	/* if for some reason the parent process has fd3 or fd4
	   already open, then this will fail although there is
	   no real error */
	assert (fd[0] == 3);
	assert (fd[1] == 4);
	return (0);
}

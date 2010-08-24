#include <string.h>
#include <assert.h>

int
main ()
{
	char buf[100];
	memset (buf, 0x1, sizeof (buf));
	assert (memccpy (buf, "Hello World\n", ' ', sizeof (buf)));
	assert (buf[6] == 0x1);
	assert (!*(char *) (memccpy (buf, "Hello, World", 0, sizeof (buf))-1));
	assert (buf[13] == 0x1);
	assert (!memccpy (buf, "Hello, World\n", 0, 5));
	return (0);
}

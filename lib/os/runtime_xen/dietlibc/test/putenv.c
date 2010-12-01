#include <stdlib.h>
#include <string.h>
#include <assert.h>

int
main ()
{
	static char foo[] = "Hello=World";
	assert (putenv ("foo=bar") != -1);
	assert (!strcmp (getenv ("foo"), "bar"));
	assert (putenv ("foo=baz") != -1);
	assert (!strcmp (getenv ("foo"), "baz"));
	putenv (foo);
	assert (!strcmp (getenv ("Hello"), "World"));
	foo[6] = 'M';
	assert (!strcmp (getenv ("Hello"), "Morld"));
	return (0);
}

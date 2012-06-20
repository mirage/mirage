#include <assert.h>

int main()
{
	long foo = 0;
	__testandset (&foo);
	assert (foo);
	assert (__testandset (&foo));
	return (0);
}

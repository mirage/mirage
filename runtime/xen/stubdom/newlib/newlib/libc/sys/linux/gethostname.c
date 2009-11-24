/* Copyright 2002, Red Hat Inc. */

#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/utsname.h>
#include <machine/weakalias.h>

int
__gethostname (char *name, size_t len)
{
	struct utsname nodebuf;
	size_t nodelen;

	if (uname (&nodebuf))
		return -1;

	nodelen = strlen (nodebuf.nodename) + 1;
	if (len < nodelen)
		memcpy (name, nodebuf.nodename, len);
	else
		memcpy (name, nodebuf.nodename, nodelen);

	if (nodelen > len)
	{
		errno = ENAMETOOLONG;
		return -1;
	}
	return 0;
}
weak_alias(__gethostname, gethostname)

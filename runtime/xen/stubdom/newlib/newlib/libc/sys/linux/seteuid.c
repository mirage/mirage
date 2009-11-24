/* Copyright 2002, Red Hat Inc. */

#include <errno.h>
#include <unistd.h>

int
seteuid (uid_t uid)
{
	int result;

	if (uid == (uid_t) ~0)
	{
		errno = (EINVAL);
		return -1;
	}

	return setresuid (-1, uid, -1);
}

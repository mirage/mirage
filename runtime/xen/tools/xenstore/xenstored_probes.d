/*
 * Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
 * Use is subject to license terms.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2 of the License.
 */

#include <sys/types.h>

provider xenstore {
	/* tx id, dom id, pid, type, msg */
	probe msg(uint32_t, unsigned int, pid_t, int, const char *);
	/* tx id, dom id, pid, type, reply */
	probe reply(uint32_t, unsigned int, pid_t, int, const char *);
	/* tx id, dom id, pid, reply */
	probe error(uint32_t, unsigned int, pid_t, const char *);
	/* dom id, pid, watch details */
	probe watch_event(unsigned int, pid_t, const char *);
};

#pragma D attributes Evolving/Evolving/Common provider xenstore provider
#pragma D attributes Private/Private/Unknown provider xenstore module
#pragma D attributes Private/Private/Unknown provider xenstore function
#pragma D attributes Evolving/Evolving/Common provider xenstore name
#pragma D attributes Evolving/Evolving/Common provider xenstore args


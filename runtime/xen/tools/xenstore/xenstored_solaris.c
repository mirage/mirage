/******************************************************************************
 *
 * Copyright 2006 Sun Microsystems, Inc.  All rights reserved.
 * Use is subject to license terms.
 *
 * Copyright (C) 2005 Rusty Russell IBM Corporation
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2 of the
 * License.
 */

#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdarg.h>
#include <sys/mman.h>
#include <strings.h>
#include <ucred.h>
#include <stdio.h>

#include <xen/sys/xenbus.h>

#include "talloc.h"
#include "xenstored_core.h"
#include "xenstored_probes.h"

evtchn_port_t xenbus_evtchn(void)
{
	int fd;
	evtchn_port_t port; 

	fd = open("/dev/xen/xenbus", O_RDONLY); 
	if (fd == -1)
		return -1;

	port = ioctl(fd, IOCTL_XENBUS_XENSTORE_EVTCHN);

	close(fd); 
	return port;
}

void *xenbus_map(void)
{
	int fd;
	void *addr;

	fd = open("/dev/xen/xenbus", O_RDWR);
	if (fd == -1)
		return NULL;

	addr = mmap(NULL, getpagesize(), PROT_READ|PROT_WRITE,
		MAP_SHARED, fd, 0);

	if (addr == MAP_FAILED)
		addr = NULL;

	close(fd);

	return addr;
}

void xenbus_notify_running(void)
{
	int fd;

	fd = open("/dev/xen/xenbus", O_RDONLY);

	(void) ioctl(fd, IOCTL_XENBUS_NOTIFY_UP);

	close(fd);
}

static pid_t cred(const struct connection *conn)
{
	ucred_t *ucred = NULL;
	pid_t pid;

	if (conn->domain)
		return (0);

	if (getpeerucred(conn->fd, &ucred) == -1)
		return (0);

	pid = ucred_getpid(ucred);

	ucred_free(ucred);
	return (pid);
}

/*
 * The strings are often a number of nil-separated strings. We'll just
 * replace the separators with spaces - not quite right, but good
 * enough.
 */
static char *
mangle(const struct connection *conn, const struct buffered_data *in)
{
	char *str;
	int i;

	if (in->hdr.msg.len == 0)
		return (talloc_strdup(conn, ""));

	if ((str = talloc_zero_size(conn, in->hdr.msg.len + 1)) == NULL)
		return (NULL);

	memcpy(str, in->buffer, in->hdr.msg.len);
	
	/*
	 * The protocol is absurdly inconsistent in whether the length
	 * includes the terminating nil or not; replace all nils that
	 * aren't the last one.
	 */
	for (i = 0; i < (in->hdr.msg.len - 1); i++) {
		if (str[i] == '\0')
			str[i] = ' ';
	}

	return (str);
}

void
dtrace_io(const struct connection *conn, const struct buffered_data *in,
    int io_out)
{
	if (!io_out) {
		if (XENSTORE_MSG_ENABLED()) {
			char *mangled = mangle(conn, in);
			XENSTORE_MSG(in->hdr.msg.tx_id, conn->id, cred(conn),
			    in->hdr.msg.type, mangled);
		}

		goto out;
	}

	switch (in->hdr.msg.type) {
	case XS_ERROR:
		if (XENSTORE_ERROR_ENABLED()) {
			char *mangled = mangle(conn, in);
			XENSTORE_ERROR(in->hdr.msg.tx_id, conn->id,
			    cred(conn), mangled);
		}
		break;

	case XS_WATCH_EVENT:
		if (XENSTORE_WATCH_EVENT_ENABLED()) {
			char *mangled = mangle(conn, in);
			XENSTORE_WATCH_EVENT(conn->id, cred(conn), mangled);
		}
		break;

	default:
		if (XENSTORE_REPLY_ENABLED()) {
			char *mangled = mangle(conn, in);
			XENSTORE_REPLY(in->hdr.msg.tx_id, conn->id, cred(conn),
			    in->hdr.msg.type, mangled);
		}
		break;
	}

out:
	/*
	 * 6589130 dtrace -G fails for certain tail-calls on x86
	 */
	asm("nop");
}

/* 
    Common routines between Xen store user library and daemon.
    Copyright (C) 2005 Rusty Russell IBM Corporation

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#ifndef _XS_LIB_H
#define _XS_LIB_H

#include <stdbool.h>
#include <limits.h>
#include <errno.h>
#include <stdint.h>
#include <xen/io/xs_wire.h>

/* Bitmask of permissions. */
enum xs_perm_type {
	XS_PERM_NONE = 0,
	XS_PERM_READ = 1,
	XS_PERM_WRITE = 2,
	/* Internal use. */
	XS_PERM_ENOENT_OK = 4,
	XS_PERM_OWNER = 8,
};

struct xs_permissions
{
	unsigned int id;
	enum xs_perm_type perms;
};

/* Each 10 bits takes ~ 3 digits, plus one, plus one for nul terminator. */
#define MAX_STRLEN(x) ((sizeof(x) * CHAR_BIT + CHAR_BIT-1) / 10 * 3 + 2)

/* Path for various daemon things: env vars can override. */
const char *xs_daemon_rootdir(void);
const char *xs_daemon_rundir(void);
const char *xs_daemon_socket(void);
const char *xs_daemon_socket_ro(void);
const char *xs_domain_dev(void);
const char *xs_daemon_tdb(void);

/* Simple write function: loops for you. */
bool xs_write_all(int fd, const void *data, unsigned int len);

/* Convert strings to permissions.  False if a problem. */
bool xs_strings_to_perms(struct xs_permissions *perms, unsigned int num,
			 const char *strings);

/* Convert permissions to a string (up to len MAX_STRLEN(unsigned int)+1). */
bool xs_perm_to_string(const struct xs_permissions *perm,
                       char *buffer, size_t buf_len);

/* Given a string and a length, count how many strings (nul terms). */
unsigned int xs_count_strings(const char *strings, unsigned int len);

/* Sanitising (quoting) possibly-binary strings. */
struct expanding_buffer {
	char *buf;
	int avail;
};

/* Ensure that given expanding buffer has at least min_avail characters. */
char *expanding_buffer_ensure(struct expanding_buffer *, int min_avail);

/* sanitise_value() may return NULL if malloc fails. */
char *sanitise_value(struct expanding_buffer *, const char *val, unsigned len);

/* *out_len_r on entry is ignored; out must be at least strlen(in)+1 bytes. */
void unsanitise_value(char *out, unsigned *out_len_r, const char *in);

#endif /* _XS_LIB_H */

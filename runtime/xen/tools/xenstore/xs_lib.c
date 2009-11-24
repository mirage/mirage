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

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <assert.h>
#include "xs_lib.h"

/* Common routines for the Xen store daemon and client library. */

const char *xs_daemon_rootdir(void)
{
	char *s = getenv("XENSTORED_ROOTDIR");
	return (s ? s : "/var/lib/xenstored");
}

const char *xs_daemon_rundir(void)
{
	char *s = getenv("XENSTORED_RUNDIR");
	return (s ? s : "/var/run/xenstored");
}

static const char *xs_daemon_path(void)
{
	static char buf[PATH_MAX];
	char *s = getenv("XENSTORED_PATH");
	if (s)
		return s;
	if (snprintf(buf, sizeof(buf), "%s/socket",
		     xs_daemon_rundir()) >= PATH_MAX)
		return NULL;
	return buf;
}

const char *xs_daemon_tdb(void)
{
	static char buf[PATH_MAX];
	snprintf(buf, sizeof(buf), "%s/tdb", xs_daemon_rootdir());
	return buf;
}

const char *xs_daemon_socket(void)
{
	return xs_daemon_path();
}

const char *xs_daemon_socket_ro(void)
{
	static char buf[PATH_MAX];
	const char *s = xs_daemon_path();
	if (s == NULL)
		return NULL;
	if (snprintf(buf, sizeof(buf), "%s_ro", s) >= PATH_MAX)
		return NULL;
	return buf;
}

const char *xs_domain_dev(void)
{
	char *s = getenv("XENSTORED_PATH");
	if (s)
		return s;

#if defined(__linux__)
	return "/proc/xen/xenbus";
#elif defined(__NetBSD__)
	return "/kern/xen/xenbus";
#else
	return "/dev/xen/xenbus";
#endif
}

/* Simple routines for writing to sockets, etc. */
bool xs_write_all(int fd, const void *data, unsigned int len)
{
	while (len) {
		int done;

		done = write(fd, data, len);
		if (done < 0 && errno == EINTR)
			continue;
		if (done <= 0)
			return false;
		data += done;
		len -= done;
	}

	return true;
}

/* Convert strings to permissions.  False if a problem. */
bool xs_strings_to_perms(struct xs_permissions *perms, unsigned int num,
			 const char *strings)
{
	const char *p;
	char *end;
	unsigned int i;

	for (p = strings, i = 0; i < num; i++) {
		/* "r", "w", or "b" for both. */
		switch (*p) {
		case 'r':
			perms[i].perms = XS_PERM_READ;
			break;
		case 'w':
			perms[i].perms = XS_PERM_WRITE;
			break;
		case 'b':
			perms[i].perms = XS_PERM_READ|XS_PERM_WRITE;
			break;
		case 'n':
			perms[i].perms = XS_PERM_NONE;
			break;
		default:
			errno = EINVAL;
			return false;
		} 
		p++;
		perms[i].id = strtol(p, &end, 0);
		if (*end || !*p) {
			errno = EINVAL;
			return false;
		}
		p = end + 1;
	}
	return true;
}

/* Convert permissions to a string (up to len MAX_STRLEN(unsigned int)+1). */
bool xs_perm_to_string(const struct xs_permissions *perm,
                       char *buffer, size_t buf_len)
{
	switch (perm->perms) {
	case XS_PERM_WRITE:
		*buffer = 'w';
		break;
	case XS_PERM_READ:
		*buffer = 'r';
		break;
	case XS_PERM_READ|XS_PERM_WRITE:
		*buffer = 'b';
		break;
	case XS_PERM_NONE:
		*buffer = 'n';
		break;
	default:
		errno = EINVAL;
		return false;
	}
	snprintf(buffer+1, buf_len-1, "%i", (int)perm->id);
	return true;
}

/* Given a string and a length, count how many strings (nul terms). */
unsigned int xs_count_strings(const char *strings, unsigned int len)
{
	unsigned int num;
	const char *p;

	for (p = strings, num = 0; p < strings + len; p++)
		if (*p == '\0')
			num++;

	return num;
}

char *expanding_buffer_ensure(struct expanding_buffer *ebuf, int min_avail)
{
	int want;
	char *got;

	if (ebuf->avail >= min_avail)
		return ebuf->buf;

	if (min_avail >= INT_MAX/3)
		return 0;

	want = ebuf->avail + min_avail + 10;
	got = realloc(ebuf->buf, want);
	if (!got)
		return 0;

	ebuf->buf = got;
	ebuf->avail = want;
	return ebuf->buf;
}

char *sanitise_value(struct expanding_buffer *ebuf,
		     const char *val, unsigned len)
{
	int used, remain, c;
	unsigned char *ip;

#define ADD(c) (ebuf->buf[used++] = (c))
#define ADDF(f,c) (used += sprintf(ebuf->buf+used, (f), (c)))

	assert(len < INT_MAX/5);

	ip = (unsigned char *)val;
	used = 0;
	remain = len;

	if (!expanding_buffer_ensure(ebuf, remain + 1))
		return NULL;

	while (remain-- > 0) {
		c= *ip++;

		if (c >= ' ' && c <= '~' && c != '\\') {
			ADD(c);
			continue;
		}

		if (!expanding_buffer_ensure(ebuf, used + remain + 5))
			/* for "<used>\\nnn<remain>\0" */
			return 0;

		ADD('\\');
		switch (c) {
		case '\t':  ADD('t');   break;
		case '\n':  ADD('n');   break;
		case '\r':  ADD('r');   break;
		case '\\':  ADD('\\');  break;
		default:
			if (c < 010) ADDF("%03o", c);
			else         ADDF("x%02x", c);
		}
	}

	ADD(0);
	assert(used <= ebuf->avail);
	return ebuf->buf;

#undef ADD
#undef ADDF
}

void unsanitise_value(char *out, unsigned *out_len_r, const char *in)
{
	const char *ip;
	char *op;
	unsigned c;
	int n;

	for (ip = in, op = out; (c = *ip++); *op++ = c) {
		if (c == '\\') {
			c = *ip++;

#define GETF(f) do {					\
		        n = 0;				\
                        sscanf(ip, f "%n", &c, &n);	\
			ip += n;			\
		} while (0)

			switch (c) {
			case 't':              c= '\t';            break;
			case 'n':              c= '\n';            break;
			case 'r':              c= '\r';            break;
			case '\\':             c= '\\';            break;
			case 'x':                    GETF("%2x");  break;
			case '0': case '4':
			case '1': case '5':
			case '2': case '6':
			case '3': case '7':    --ip; GETF("%3o");  break;
			case 0:                --ip;               break;
			default:;
			}
#undef GETF
		}
	}

	*op = 0;

	if (out_len_r)
		*out_len_r = op - out;
}

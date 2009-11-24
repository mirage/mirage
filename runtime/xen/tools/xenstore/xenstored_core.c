/* 
    Simple prototype Xen Store Daemon providing simple tree-like database.
    Copyright (C) 2005 Rusty Russell IBM Corporation

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <sys/un.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <syslog.h>
#include <string.h>
#include <errno.h>
#include <dirent.h>
#include <getopt.h>
#include <signal.h>
#include <assert.h>
#include <setjmp.h>

#include "utils.h"
#include "list.h"
#include "talloc.h"
#include "xs_lib.h"
#include "xenstored_core.h"
#include "xenstored_watch.h"
#include "xenstored_transaction.h"
#include "xenstored_domain.h"
#include "xenctrl.h"
#include "tdb.h"

#include "hashtable.h"

extern int xce_handle; /* in xenstored_domain.c */

static bool verbose = false;
LIST_HEAD(connections);
static int tracefd = -1;
static bool recovery = true;
static bool remove_local = true;
static int reopen_log_pipe[2];
static char *tracefile = NULL;
static TDB_CONTEXT *tdb_ctx;

static void corrupt(struct connection *conn, const char *fmt, ...);
static void check_store(void);

#define log(...)							\
	do {								\
		char *s = talloc_asprintf(NULL, __VA_ARGS__);		\
		trace("%s\n", s);					\
		syslog(LOG_ERR, "%s",  s);				\
		talloc_free(s);						\
	} while (0)


int quota_nb_entry_per_domain = 1000;
int quota_nb_watch_per_domain = 128;
int quota_max_entry_size = 2048; /* 2K */
int quota_max_transaction = 10;

TDB_CONTEXT *tdb_context(struct connection *conn)
{
	/* conn = NULL used in manual_node at setup. */
	if (!conn || !conn->transaction)
		return tdb_ctx;
	return tdb_transaction_context(conn->transaction);
}

bool replace_tdb(const char *newname, TDB_CONTEXT *newtdb)
{
	if (rename(newname, xs_daemon_tdb()) != 0)
		return false;
	tdb_close(tdb_ctx);
	tdb_ctx = talloc_steal(talloc_autofree_context(), newtdb);
	return true;
}

static char *sockmsg_string(enum xsd_sockmsg_type type)
{
	switch (type) {
	case XS_DEBUG: return "DEBUG";
	case XS_DIRECTORY: return "DIRECTORY";
	case XS_READ: return "READ";
	case XS_GET_PERMS: return "GET_PERMS";
	case XS_WATCH: return "WATCH";
	case XS_UNWATCH: return "UNWATCH";
	case XS_TRANSACTION_START: return "TRANSACTION_START";
	case XS_TRANSACTION_END: return "TRANSACTION_END";
	case XS_INTRODUCE: return "INTRODUCE";
	case XS_RELEASE: return "RELEASE";
	case XS_GET_DOMAIN_PATH: return "GET_DOMAIN_PATH";
	case XS_WRITE: return "WRITE";
	case XS_MKDIR: return "MKDIR";
	case XS_RM: return "RM";
	case XS_SET_PERMS: return "SET_PERMS";
	case XS_WATCH_EVENT: return "WATCH_EVENT";
	case XS_ERROR: return "ERROR";
	case XS_IS_DOMAIN_INTRODUCED: return "XS_IS_DOMAIN_INTRODUCED";
	case XS_RESUME: return "RESUME";
	case XS_SET_TARGET: return "SET_TARGET";
	default:
		return "**UNKNOWN**";
	}
}

void trace(const char *fmt, ...)
{
	va_list arglist;
	char *str;
	char sbuf[1024];
	int ret, dummy;

	if (tracefd < 0)
		return;

	/* try to use a static buffer */
	va_start(arglist, fmt);
	ret = vsnprintf(sbuf, 1024, fmt, arglist);
	va_end(arglist);

	if (ret <= 1024) {
		dummy = write(tracefd, sbuf, ret);
		return;
	}

	/* fail back to dynamic allocation */
	va_start(arglist, fmt);
	str = talloc_vasprintf(NULL, fmt, arglist);
	va_end(arglist);
	dummy = write(tracefd, str, strlen(str));
	talloc_free(str);
}

static void trace_io(const struct connection *conn,
		     const struct buffered_data *data,
		     int out)
{
	unsigned int i;
	time_t now;
	struct tm *tm;

#ifdef HAVE_DTRACE
	dtrace_io(conn, data, out);
#endif

	if (tracefd < 0)
		return;

	now = time(NULL);
	tm = localtime(&now);

	trace("%s %p %04d%02d%02d %02d:%02d:%02d %s (",
	      out ? "OUT" : "IN", conn,
	      tm->tm_year + 1900, tm->tm_mon + 1,
	      tm->tm_mday, tm->tm_hour, tm->tm_min, tm->tm_sec,
	      sockmsg_string(data->hdr.msg.type));
	
	for (i = 0; i < data->hdr.msg.len; i++)
		trace("%c", (data->buffer[i] != '\0') ? data->buffer[i] : ' ');
	trace(")\n");
}

void trace_create(const void *data, const char *type)
{
	trace("CREATE %s %p\n", type, data);
}

void trace_destroy(const void *data, const char *type)
{
	trace("DESTROY %s %p\n", type, data);
}

/**
 * Signal handler for SIGHUP, which requests that the trace log is reopened
 * (in the main loop).  A single byte is written to reopen_log_pipe, to awaken
 * the select() in the main loop.
 */
static void trigger_reopen_log(int signal __attribute__((unused)))
{
	char c = 'A';
	int dummy;
	dummy = write(reopen_log_pipe[1], &c, 1);
}


static void reopen_log(void)
{
	if (tracefile) {
		if (tracefd > 0)
			close(tracefd);

		tracefd = open(tracefile, O_WRONLY|O_CREAT|O_APPEND, 0600);

		if (tracefd < 0)
			perror("Could not open tracefile");
		else
			trace("\n***\n");
	}
}


static bool write_messages(struct connection *conn)
{
	int ret;
	struct buffered_data *out;

	out = list_top(&conn->out_list, struct buffered_data, list);
	if (out == NULL)
		return true;

	if (out->inhdr) {
		if (verbose)
			xprintf("Writing msg %s (%.*s) out to %p\n",
				sockmsg_string(out->hdr.msg.type),
				out->hdr.msg.len,
				out->buffer, conn);
		ret = conn->write(conn, out->hdr.raw + out->used,
				  sizeof(out->hdr) - out->used);
		if (ret < 0)
			return false;

		out->used += ret;
		if (out->used < sizeof(out->hdr))
			return true;

		out->inhdr = false;
		out->used = 0;

		/* Second write might block if non-zero. */
		if (out->hdr.msg.len && !conn->domain)
			return true;
	}

	ret = conn->write(conn, out->buffer + out->used,
			  out->hdr.msg.len - out->used);
	if (ret < 0)
		return false;

	out->used += ret;
	if (out->used != out->hdr.msg.len)
		return true;

	trace_io(conn, out, 1);

	list_del(&out->list);
	talloc_free(out);

	return true;
}

static int destroy_conn(void *_conn)
{
	struct connection *conn = _conn;

	/* Flush outgoing if possible, but don't block. */
	if (!conn->domain) {
		fd_set set;
		struct timeval none;

		FD_ZERO(&set);
		FD_SET(conn->fd, &set);
		none.tv_sec = none.tv_usec = 0;

		while (!list_empty(&conn->out_list)
		       && select(conn->fd+1, NULL, &set, NULL, &none) == 1)
			if (!write_messages(conn))
				break;
		close(conn->fd);
	}
        if (conn->target)
                talloc_unlink(conn, conn->target);
	list_del(&conn->list);
	trace_destroy(conn, "connection");
	return 0;
}


static void set_fd(int fd, fd_set *set, int *max)
{
	if (fd < 0)
		return;
	FD_SET(fd, set);
	if (fd > *max)
		*max = fd;
}


static int initialize_set(fd_set *inset, fd_set *outset, int sock, int ro_sock,
			  struct timeval **ptimeout)
{
	static struct timeval zero_timeout = { 0 };
	struct connection *conn;
	int max = -1;

	*ptimeout = NULL;

	FD_ZERO(inset);
	FD_ZERO(outset);

	set_fd(sock,               inset, &max);
	set_fd(ro_sock,            inset, &max);
	set_fd(reopen_log_pipe[0], inset, &max);

	if (xce_handle != -1)
		set_fd(xc_evtchn_fd(xce_handle), inset, &max);

	list_for_each_entry(conn, &connections, list) {
		if (conn->domain) {
			if (domain_can_read(conn) ||
			    (domain_can_write(conn) &&
			     !list_empty(&conn->out_list)))
				*ptimeout = &zero_timeout;
		} else {
			set_fd(conn->fd, inset, &max);
			if (!list_empty(&conn->out_list))
				FD_SET(conn->fd, outset);
		}
	}

	return max;
}

static int destroy_fd(void *_fd)
{
	int *fd = _fd;
	close(*fd);
	return 0;
}

/* Is child a subnode of parent, or equal? */
bool is_child(const char *child, const char *parent)
{
	unsigned int len = strlen(parent);

	/* / should really be "" for this algorithm to work, but that's a
	 * usability nightmare. */
	if (streq(parent, "/"))
		return true;

	if (strncmp(child, parent, len) != 0)
		return false;

	return child[len] == '/' || child[len] == '\0';
}

/* If it fails, returns NULL and sets errno. */
static struct node *read_node(struct connection *conn, const char *name)
{
	TDB_DATA key, data;
	uint32_t *p;
	struct node *node;
	TDB_CONTEXT * context = tdb_context(conn);

	key.dptr = (void *)name;
	key.dsize = strlen(name);
	data = tdb_fetch(context, key);

	if (data.dptr == NULL) {
		if (tdb_error(context) == TDB_ERR_NOEXIST)
			errno = ENOENT;
		else {
			log("TDB error on read: %s", tdb_errorstr(context));
			errno = EIO;
		}
		return NULL;
	}

	node = talloc(name, struct node);
	node->name = talloc_strdup(node, name);
	node->parent = NULL;
	node->tdb = tdb_context(conn);
	talloc_steal(node, data.dptr);

	/* Datalen, childlen, number of permissions */
	p = (uint32_t *)data.dptr;
	node->num_perms = p[0];
	node->datalen = p[1];
	node->childlen = p[2];

	/* Permissions are struct xs_permissions. */
	node->perms = (void *)&p[3];
	/* Data is binary blob (usually ascii, no nul). */
	node->data = node->perms + node->num_perms;
	/* Children is strings, nul separated. */
	node->children = node->data + node->datalen;

	return node;
}

static bool write_node(struct connection *conn, const struct node *node)
{
	/*
	 * conn will be null when this is called from manual_node.
	 * tdb_context copes with this.
	 */

	TDB_DATA key, data;
	void *p;

	key.dptr = (void *)node->name;
	key.dsize = strlen(node->name);

	data.dsize = 3*sizeof(uint32_t)
		+ node->num_perms*sizeof(node->perms[0])
		+ node->datalen + node->childlen;

	if (domain_is_unprivileged(conn) && data.dsize >= quota_max_entry_size)
		goto error;

	data.dptr = talloc_size(node, data.dsize);
	((uint32_t *)data.dptr)[0] = node->num_perms;
	((uint32_t *)data.dptr)[1] = node->datalen;
	((uint32_t *)data.dptr)[2] = node->childlen;
	p = data.dptr + 3 * sizeof(uint32_t);

	memcpy(p, node->perms, node->num_perms*sizeof(node->perms[0]));
	p += node->num_perms*sizeof(node->perms[0]);
	memcpy(p, node->data, node->datalen);
	p += node->datalen;
	memcpy(p, node->children, node->childlen);

	/* TDB should set errno, but doesn't even set ecode AFAICT. */
	if (tdb_store(tdb_context(conn), key, data, TDB_REPLACE) != 0) {
		corrupt(conn, "Write of %s failed", key.dptr);
		goto error;
	}
	return true;
 error:
	errno = ENOSPC;
	return false;
}

static enum xs_perm_type perm_for_conn(struct connection *conn,
				       struct xs_permissions *perms,
				       unsigned int num)
{
	unsigned int i;
	enum xs_perm_type mask = XS_PERM_READ|XS_PERM_WRITE|XS_PERM_OWNER;

	if (!conn->can_write)
		mask &= ~XS_PERM_WRITE;

	/* Owners and tools get it all... */
	if (!conn->id || perms[0].id == conn->id
                || (conn->target && perms[0].id == conn->target->id))
		return (XS_PERM_READ|XS_PERM_WRITE|XS_PERM_OWNER) & mask;

	for (i = 1; i < num; i++)
		if (perms[i].id == conn->id
                        || (conn->target && perms[i].id == conn->target->id))
			return perms[i].perms & mask;

	return perms[0].perms & mask;
}

static char *get_parent(const char *node)
{
	char *slash = strrchr(node + 1, '/');
	if (!slash)
		return talloc_strdup(node, "/");
	return talloc_asprintf(node, "%.*s", (int)(slash - node), node);
}

/* What do parents say? */
static enum xs_perm_type ask_parents(struct connection *conn, const char *name)
{
	struct node *node;

	do {
		name = get_parent(name);
		node = read_node(conn, name);
		if (node)
			break;
	} while (!streq(name, "/"));

	/* No permission at root?  We're in trouble. */
	if (!node)
		corrupt(conn, "No permissions file at root");

	return perm_for_conn(conn, node->perms, node->num_perms);
}

/* We have a weird permissions system.  You can allow someone into a
 * specific node without allowing it in the parents.  If it's going to
 * fail, however, we don't want the errno to indicate any information
 * about the node. */
static int errno_from_parents(struct connection *conn, const char *node,
			      int errnum, enum xs_perm_type perm)
{
	/* We always tell them about memory failures. */
	if (errnum == ENOMEM)
		return errnum;

	if (ask_parents(conn, node) & perm)
		return errnum;
	return EACCES;
}

/* If it fails, returns NULL and sets errno. */
struct node *get_node(struct connection *conn,
		      const char *name,
		      enum xs_perm_type perm)
{
	struct node *node;

	if (!name || !is_valid_nodename(name)) {
		errno = EINVAL;
		return NULL;
	}
	node = read_node(conn, name);
	/* If we don't have permission, we don't have node. */
	if (node) {
		if ((perm_for_conn(conn, node->perms, node->num_perms) & perm)
		    != perm) {
			errno = EACCES;
			node = NULL;
		}
	}
	/* Clean up errno if they weren't supposed to know. */
	if (!node) 
		errno = errno_from_parents(conn, name, errno, perm);
	return node;
}

static struct buffered_data *new_buffer(void *ctx)
{
	struct buffered_data *data;

	data = talloc_zero(ctx, struct buffered_data);
	if (data == NULL)
		return NULL;
	
	data->inhdr = true;
	return data;
}

/* Return length of string (including nul) at this offset.
 * If there is no nul, returns 0 for failure.
 */
static unsigned int get_string(const struct buffered_data *data,
			       unsigned int offset)
{
	const char *nul;

	if (offset >= data->used)
		return 0;

	nul = memchr(data->buffer + offset, 0, data->used - offset);
	if (!nul)
		return 0;

	return nul - (data->buffer + offset) + 1;
}

/* Break input into vectors, return the number, fill in up to num of them.
 * Always returns the actual number of nuls in the input.  Stores the
 * positions of the starts of the nul-terminated strings in vec.
 * Callers who use this and then rely only on vec[] will
 * ignore any data after the final nul.
 */
unsigned int get_strings(struct buffered_data *data,
			 char *vec[], unsigned int num)
{
	unsigned int off, i, len;

	off = i = 0;
	while ((len = get_string(data, off)) != 0) {
		if (i < num)
			vec[i] = data->buffer + off;
		i++;
		off += len;
	}
	return i;
}

void send_reply(struct connection *conn, enum xsd_sockmsg_type type,
		const void *data, unsigned int len)
{
	struct buffered_data *bdata;

	/* Message is a child of the connection context for auto-cleanup. */
	bdata = new_buffer(conn);
	bdata->buffer = talloc_array(bdata, char, len);

	/* Echo request header in reply unless this is an async watch event. */
	if (type != XS_WATCH_EVENT) {
		memcpy(&bdata->hdr.msg, &conn->in->hdr.msg,
		       sizeof(struct xsd_sockmsg));
	} else {
		memset(&bdata->hdr.msg, 0, sizeof(struct xsd_sockmsg));
	}

	/* Update relevant header fields and fill in the message body. */
	bdata->hdr.msg.type = type;
	bdata->hdr.msg.len = len;
	memcpy(bdata->buffer, data, len);

	/* Queue for later transmission. */
	list_add_tail(&bdata->list, &conn->out_list);
}

/* Some routines (write, mkdir, etc) just need a non-error return */
void send_ack(struct connection *conn, enum xsd_sockmsg_type type)
{
	send_reply(conn, type, "OK", sizeof("OK"));
}

void send_error(struct connection *conn, int error)
{
	unsigned int i;

	for (i = 0; error != xsd_errors[i].errnum; i++) {
		if (i == ARRAY_SIZE(xsd_errors) - 1) {
			eprintf("xenstored: error %i untranslatable", error);
			i = 0; 	/* EINVAL */
			break;
		}
	}
	send_reply(conn, XS_ERROR, xsd_errors[i].errstring,
			  strlen(xsd_errors[i].errstring) + 1);
}

static bool valid_chars(const char *node)
{
	/* Nodes can have lots of crap. */
	return (strspn(node, 
		       "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		       "abcdefghijklmnopqrstuvwxyz"
		       "0123456789-/_@") == strlen(node));
}

bool is_valid_nodename(const char *node)
{
	/* Must start in /. */
	if (!strstarts(node, "/"))
		return false;

	/* Cannot end in / (unless it's just "/"). */
	if (strends(node, "/") && !streq(node, "/"))
		return false;

	/* No double //. */
	if (strstr(node, "//"))
		return false;

	if (strlen(node) > XENSTORE_ABS_PATH_MAX)
		return false;

	return valid_chars(node);
}

/* We expect one arg in the input: return NULL otherwise.
 * The payload must contain exactly one nul, at the end.
 */
static const char *onearg(struct buffered_data *in)
{
	if (!in->used || get_string(in, 0) != in->used)
		return NULL;
	return in->buffer;
}

static char *perms_to_strings(const void *ctx,
			      struct xs_permissions *perms, unsigned int num,
			      unsigned int *len)
{
	unsigned int i;
	char *strings = NULL;
	char buffer[MAX_STRLEN(unsigned int) + 1];

	for (*len = 0, i = 0; i < num; i++) {
		if (!xs_perm_to_string(&perms[i], buffer, sizeof(buffer)))
			return NULL;

		strings = talloc_realloc(ctx, strings, char,
					 *len + strlen(buffer) + 1);
		strcpy(strings + *len, buffer);
		*len += strlen(buffer) + 1;
	}
	return strings;
}

char *canonicalize(struct connection *conn, const char *node)
{
	const char *prefix;

	if (!node || (node[0] == '/') || (node[0] == '@'))
		return (char *)node;
	prefix = get_implicit_path(conn);
	if (prefix)
		return talloc_asprintf(node, "%s/%s", prefix, node);
	return (char *)node;
}

bool check_event_node(const char *node)
{
	if (!node || !strstarts(node, "@")) {
		errno = EINVAL;
		return false;
	}
	return true;
}

static void send_directory(struct connection *conn, const char *name)
{
	struct node *node;

	name = canonicalize(conn, name);
	node = get_node(conn, name, XS_PERM_READ);
	if (!node) {
		send_error(conn, errno);
		return;
	}

	send_reply(conn, XS_DIRECTORY, node->children, node->childlen);
}

static void do_read(struct connection *conn, const char *name)
{
	struct node *node;

	name = canonicalize(conn, name);
	node = get_node(conn, name, XS_PERM_READ);
	if (!node) {
		send_error(conn, errno);
		return;
	}

	send_reply(conn, XS_READ, node->data, node->datalen);
}

static void delete_node_single(struct connection *conn, struct node *node)
{
	TDB_DATA key;

	key.dptr = (void *)node->name;
	key.dsize = strlen(node->name);

	if (tdb_delete(tdb_context(conn), key) != 0) {
		corrupt(conn, "Could not delete '%s'", node->name);
		return;
	}
	domain_entry_dec(conn, node);
}

/* Must not be / */
static char *basename(const char *name)
{
	return strrchr(name, '/') + 1;
}

static struct node *construct_node(struct connection *conn, const char *name)
{
	const char *base;
	unsigned int baselen;
	struct node *parent, *node;
	char *children, *parentname = get_parent(name);

	/* If parent doesn't exist, create it. */
	parent = read_node(conn, parentname);
	if (!parent)
		parent = construct_node(conn, parentname);
	if (!parent)
		return NULL;

	if (domain_entry(conn) >= quota_nb_entry_per_domain)
		return NULL;

	/* Add child to parent. */
	base = basename(name);
	baselen = strlen(base) + 1;
	children = talloc_array(name, char, parent->childlen + baselen);
	memcpy(children, parent->children, parent->childlen);
	memcpy(children + parent->childlen, base, baselen);
	parent->children = children;
	parent->childlen += baselen;

	/* Allocate node */
	node = talloc(name, struct node);
	node->tdb = tdb_context(conn);
	node->name = talloc_strdup(node, name);

	/* Inherit permissions, except domains own what they create */
	node->num_perms = parent->num_perms;
	node->perms = talloc_memdup(node, parent->perms,
				    node->num_perms * sizeof(node->perms[0]));
	if (conn && conn->id)
		node->perms[0].id = conn->id;

	/* No children, no data */
	node->children = node->data = NULL;
	node->childlen = node->datalen = 0;
	node->parent = parent;
	domain_entry_inc(conn, node);
	return node;
}

static int destroy_node(void *_node)
{
	struct node *node = _node;
	TDB_DATA key;

	if (streq(node->name, "/"))
		corrupt(NULL, "Destroying root node!");

	key.dptr = (void *)node->name;
	key.dsize = strlen(node->name);

	tdb_delete(node->tdb, key);
	return 0;
}

static struct node *create_node(struct connection *conn, 
				const char *name,
				void *data, unsigned int datalen)
{
	struct node *node, *i;

	node = construct_node(conn, name);
	if (!node)
		return NULL;

	node->data = data;
	node->datalen = datalen;

	/* We write out the nodes down, setting destructor in case
	 * something goes wrong. */
	for (i = node; i; i = i->parent) {
		if (!write_node(conn, i)) {
			domain_entry_dec(conn, i);
			return NULL;
		}
		talloc_set_destructor(i, destroy_node);
	}

	/* OK, now remove destructors so they stay around */
	for (i = node; i; i = i->parent)
		talloc_set_destructor(i, NULL);
	return node;
}

/* path, data... */
static void do_write(struct connection *conn, struct buffered_data *in)
{
	unsigned int offset, datalen;
	struct node *node;
	char *vec[1] = { NULL }; /* gcc4 + -W + -Werror fucks code. */
	char *name;

	/* Extra "strings" can be created by binary data. */
	if (get_strings(in, vec, ARRAY_SIZE(vec)) < ARRAY_SIZE(vec)) {
		send_error(conn, EINVAL);
		return;
	}

	offset = strlen(vec[0]) + 1;
	datalen = in->used - offset;

	name = canonicalize(conn, vec[0]);
	node = get_node(conn, name, XS_PERM_WRITE);
	if (!node) {
		/* No permissions, invalid input? */
		if (errno != ENOENT) {
			send_error(conn, errno);
			return;
		}
		node = create_node(conn, name, in->buffer + offset, datalen);
		if (!node) {
			send_error(conn, errno);
			return;
		}
	} else {
		node->data = in->buffer + offset;
		node->datalen = datalen;
		if (!write_node(conn, node)){
			send_error(conn, errno);
			return;
		}
	}

	add_change_node(conn->transaction, name, false);
	fire_watches(conn, name, false);
	send_ack(conn, XS_WRITE);
}

static void do_mkdir(struct connection *conn, const char *name)
{
	struct node *node;

	name = canonicalize(conn, name);
	node = get_node(conn, name, XS_PERM_WRITE);

	/* If it already exists, fine. */
	if (!node) {
		/* No permissions? */
		if (errno != ENOENT) {
			send_error(conn, errno);
			return;
		}
		node = create_node(conn, name, NULL, 0);
		if (!node) {
			send_error(conn, errno);
			return;
		}
		add_change_node(conn->transaction, name, false);
		fire_watches(conn, name, false);
	}
	send_ack(conn, XS_MKDIR);
}

static void delete_node(struct connection *conn, struct node *node)
{
	unsigned int i;

	/* Delete self, then delete children.  If we crash, then the worst
	   that can happen is the children will continue to take up space, but
	   will otherwise be unreachable. */
	delete_node_single(conn, node);

	/* Delete children, too. */
	for (i = 0; i < node->childlen; i += strlen(node->children+i) + 1) {
		struct node *child;

		child = read_node(conn, 
				  talloc_asprintf(node, "%s/%s", node->name,
						  node->children + i));
		if (child) {
			delete_node(conn, child);
		}
		else {
			trace("delete_node: No child '%s/%s' found!\n",
			      node->name, node->children + i);
			/* Skip it, we've already deleted the parent. */
		}
	}
}


/* Delete memory using memmove. */
static void memdel(void *mem, unsigned off, unsigned len, unsigned total)
{
	memmove(mem + off, mem + off + len, total - off - len);
}


static bool remove_child_entry(struct connection *conn, struct node *node,
			       size_t offset)
{
	size_t childlen = strlen(node->children + offset);
	memdel(node->children, offset, childlen + 1, node->childlen);
	node->childlen -= childlen + 1;
	return write_node(conn, node);
}


static bool delete_child(struct connection *conn,
			 struct node *node, const char *childname)
{
	unsigned int i;

	for (i = 0; i < node->childlen; i += strlen(node->children+i) + 1) {
		if (streq(node->children+i, childname)) {
			return remove_child_entry(conn, node, i);
		}
	}
	corrupt(conn, "Can't find child '%s' in %s", childname, node->name);
	return false;
}


static int _rm(struct connection *conn, struct node *node, const char *name)
{
	/* Delete from parent first, then if we crash, the worst that can
	   happen is the child will continue to take up space, but will
	   otherwise be unreachable. */
	struct node *parent = read_node(conn, get_parent(name));
	if (!parent) {
		send_error(conn, EINVAL);
		return 0;
	}

	if (!delete_child(conn, parent, basename(name))) {
		send_error(conn, EINVAL);
		return 0;
	}

	delete_node(conn, node);
	return 1;
}


static void internal_rm(const char *name)
{
	char *tname = talloc_strdup(NULL, name);
	struct node *node = read_node(NULL, tname);
	if (node)
		_rm(NULL, node, tname);
	talloc_free(node);
	talloc_free(tname);
}


static void do_rm(struct connection *conn, const char *name)
{
	struct node *node;

	name = canonicalize(conn, name);
	node = get_node(conn, name, XS_PERM_WRITE);
	if (!node) {
		/* Didn't exist already?  Fine, if parent exists. */
		if (errno == ENOENT) {
			node = read_node(conn, get_parent(name));
			if (node) {
				send_ack(conn, XS_RM);
				return;
			}
			/* Restore errno, just in case. */
			errno = ENOENT;
		}
		send_error(conn, errno);
		return;
	}

	if (streq(name, "/")) {
		send_error(conn, EINVAL);
		return;
	}

	if (_rm(conn, node, name)) {
		add_change_node(conn->transaction, name, true);
		fire_watches(conn, name, true);
		send_ack(conn, XS_RM);
	}
}


static void do_get_perms(struct connection *conn, const char *name)
{
	struct node *node;
	char *strings;
	unsigned int len;

	name = canonicalize(conn, name);
	node = get_node(conn, name, XS_PERM_READ);
	if (!node) {
		send_error(conn, errno);
		return;
	}

	strings = perms_to_strings(node, node->perms, node->num_perms, &len);
	if (!strings)
		send_error(conn, errno);
	else
		send_reply(conn, XS_GET_PERMS, strings, len);
}

static void do_set_perms(struct connection *conn, struct buffered_data *in)
{
	unsigned int num;
	struct xs_permissions *perms;
	char *name, *permstr;
	struct node *node;

	num = xs_count_strings(in->buffer, in->used);
	if (num < 2) {
		send_error(conn, EINVAL);
		return;
	}

	/* First arg is node name. */
	name = canonicalize(conn, in->buffer);
	permstr = in->buffer + strlen(in->buffer) + 1;
	num--;

	/* We must own node to do this (tools can do this too). */
	node = get_node(conn, name, XS_PERM_WRITE|XS_PERM_OWNER);
	if (!node) {
		send_error(conn, errno);
		return;
	}

	perms = talloc_array(node, struct xs_permissions, num);
	if (!xs_strings_to_perms(perms, num, permstr)) {
		send_error(conn, errno);
		return;
	}

	/* Unprivileged domains may not change the owner. */
	if (domain_is_unprivileged(conn) &&
	    perms[0].id != node->perms[0].id) {
		send_error(conn, EPERM);
		return;
	}

	domain_entry_dec(conn, node);
	node->perms = perms;
	node->num_perms = num;
	domain_entry_inc(conn, node);

	if (!write_node(conn, node)) {
		send_error(conn, errno);
		return;
	}

	add_change_node(conn->transaction, name, false);
	fire_watches(conn, name, false);
	send_ack(conn, XS_SET_PERMS);
}

static void do_debug(struct connection *conn, struct buffered_data *in)
{
	int num;

	if (conn->id != 0) {
		send_error(conn, EACCES);
		return;
	}

	num = xs_count_strings(in->buffer, in->used);

	if (streq(in->buffer, "print")) {
		if (num < 2) {
			send_error(conn, EINVAL);
			return;
		}
		xprintf("debug: %s", in->buffer + get_string(in, 0));
	}

	if (streq(in->buffer, "check"))
		check_store();

	send_ack(conn, XS_DEBUG);
}

/* Process "in" for conn: "in" will vanish after this conversation, so
 * we can talloc off it for temporary variables.  May free "conn".
 */
static void process_message(struct connection *conn, struct buffered_data *in)
{
	struct transaction *trans;

	trans = transaction_lookup(conn, in->hdr.msg.tx_id);
	if (IS_ERR(trans)) {
		send_error(conn, -PTR_ERR(trans));
		return;
	}

	assert(conn->transaction == NULL);
	conn->transaction = trans;

	switch (in->hdr.msg.type) {
	case XS_DIRECTORY:
		send_directory(conn, onearg(in));
		break;

	case XS_READ:
		do_read(conn, onearg(in));
		break;

	case XS_WRITE:
		do_write(conn, in);
		break;

	case XS_MKDIR:
		do_mkdir(conn, onearg(in));
		break;

	case XS_RM:
		do_rm(conn, onearg(in));
		break;

	case XS_GET_PERMS:
		do_get_perms(conn, onearg(in));
		break;

	case XS_SET_PERMS:
		do_set_perms(conn, in);
		break;

	case XS_DEBUG:
		do_debug(conn, in);
		break;

	case XS_WATCH:
		do_watch(conn, in);
		break;

	case XS_UNWATCH:
		do_unwatch(conn, in);
		break;

	case XS_TRANSACTION_START:
		do_transaction_start(conn, in);
		break;

	case XS_TRANSACTION_END:
		do_transaction_end(conn, onearg(in));
		break;

	case XS_INTRODUCE:
		do_introduce(conn, in);
		break;

	case XS_IS_DOMAIN_INTRODUCED:
		do_is_domain_introduced(conn, onearg(in));
		break;

	case XS_RELEASE:
		do_release(conn, onearg(in));
		break;

	case XS_GET_DOMAIN_PATH:
		do_get_domain_path(conn, onearg(in));
		break;

	case XS_RESUME:
		do_resume(conn, onearg(in));
		break;

	case XS_SET_TARGET:
		do_set_target(conn, in);
		break;

	default:
		eprintf("Client unknown operation %i", in->hdr.msg.type);
		send_error(conn, ENOSYS);
		break;
	}

	conn->transaction = NULL;
}

static void consider_message(struct connection *conn)
{
	if (verbose)
		xprintf("Got message %s len %i from %p\n",
			sockmsg_string(conn->in->hdr.msg.type),
			conn->in->hdr.msg.len, conn);

	process_message(conn, conn->in);

	talloc_free(conn->in);
	conn->in = new_buffer(conn);
}

/* Errors in reading or allocating here mean we get out of sync, so we
 * drop the whole client connection. */
static void handle_input(struct connection *conn)
{
	int bytes;
	struct buffered_data *in = conn->in;

	/* Not finished header yet? */
	if (in->inhdr) {
		bytes = conn->read(conn, in->hdr.raw + in->used,
				   sizeof(in->hdr) - in->used);
		if (bytes < 0)
			goto bad_client;
		in->used += bytes;
		if (in->used != sizeof(in->hdr))
			return;

		if (in->hdr.msg.len > XENSTORE_PAYLOAD_MAX) {
			syslog(LOG_ERR, "Client tried to feed us %i",
			       in->hdr.msg.len);
			goto bad_client;
		}

		in->buffer = talloc_array(in, char, in->hdr.msg.len);
		if (!in->buffer)
			goto bad_client;
		in->used = 0;
		in->inhdr = false;
		return;
	}

	bytes = conn->read(conn, in->buffer + in->used,
			   in->hdr.msg.len - in->used);
	if (bytes < 0)
		goto bad_client;

	in->used += bytes;
	if (in->used != in->hdr.msg.len)
		return;

	trace_io(conn, in, 0);
	consider_message(conn);
	return;

bad_client:
	/* Kill it. */
	talloc_free(conn);
}

static void handle_output(struct connection *conn)
{
	if (!write_messages(conn))
		talloc_free(conn);
}

struct connection *new_connection(connwritefn_t *write, connreadfn_t *read)
{
	struct connection *new;

	new = talloc_zero(talloc_autofree_context(), struct connection);
	if (!new)
		return NULL;

	new->fd = -1;
	new->write = write;
	new->read = read;
	new->can_write = true;
	new->transaction_started = 0;
	INIT_LIST_HEAD(&new->out_list);
	INIT_LIST_HEAD(&new->watches);
	INIT_LIST_HEAD(&new->transaction_list);

	new->in = new_buffer(new);
	if (new->in == NULL) {
		talloc_free(new);
		return NULL;
	}

	list_add_tail(&new->list, &connections);
	talloc_set_destructor(new, destroy_conn);
	trace_create(new, "connection");
	return new;
}

static int writefd(struct connection *conn, const void *data, unsigned int len)
{
	int rc;

	while ((rc = write(conn->fd, data, len)) < 0) {
		if (errno == EAGAIN) {
			rc = 0;
			break;
		}
		if (errno != EINTR)
			break;
	}

	return rc;
}

static int readfd(struct connection *conn, void *data, unsigned int len)
{
	int rc;

	while ((rc = read(conn->fd, data, len)) < 0) {
		if (errno == EAGAIN) {
			rc = 0;
			break;
		}
		if (errno != EINTR)
			break;
	}

	/* Reading zero length means we're done with this connection. */
	if ((rc == 0) && (len != 0)) {
		errno = EBADF;
		rc = -1;
	}

	return rc;
}

static void accept_connection(int sock, bool canwrite)
{
	int fd;
	struct connection *conn;

	fd = accept(sock, NULL, NULL);
	if (fd < 0)
		return;

	conn = new_connection(writefd, readfd);
	if (conn) {
		conn->fd = fd;
		conn->can_write = canwrite;
	} else
		close(fd);
}

#define TDB_FLAGS 0

/* We create initial nodes manually. */
static void manual_node(const char *name, const char *child)
{
	struct node *node;
	struct xs_permissions perms = { .id = 0, .perms = XS_PERM_NONE };

	node = talloc_zero(NULL, struct node);
	node->name = name;
	node->perms = &perms;
	node->num_perms = 1;
	node->children = (char *)child;
	if (child)
		node->childlen = strlen(child) + 1;

	if (!write_node(NULL, node))
		barf_perror("Could not create initial node %s", name);
	talloc_free(node);
}

static void setup_structure(void)
{
	char *tdbname;
	tdbname = talloc_strdup(talloc_autofree_context(), xs_daemon_tdb());
	tdb_ctx = tdb_open(tdbname, 0, TDB_FLAGS, O_RDWR, 0);

	if (tdb_ctx) {
		/* XXX When we make xenstored able to restart, this will have
		   to become cleverer, checking for existing domains and not
		   removing the corresponding entries, but for now xenstored
		   cannot be restarted without losing all the registered
		   watches, which breaks all the backend drivers anyway.  We
		   can therefore get away with just clearing /local and
		   expecting Xend to put the appropriate entries back in.

		   When this change is made it is important to note that
		   dom0's entries must be cleaned up on reboot _before_ this
		   daemon starts, otherwise the backend drivers and dom0's
		   balloon driver will pick up stale entries.  In the case of
		   the balloon driver, this can be fatal.
		*/
		char *tlocal = talloc_strdup(NULL, "/local");

		check_store();

		if (remove_local) {
			internal_rm("/local");
			create_node(NULL, tlocal, NULL, 0);

			check_store();
		}

		talloc_free(tlocal);
	}
	else {
		tdb_ctx = tdb_open(tdbname, 7919, TDB_FLAGS, O_RDWR|O_CREAT,
				   0640);
		if (!tdb_ctx)
			barf_perror("Could not create tdb file %s", tdbname);

		manual_node("/", "tool");
		manual_node("/tool", "xenstored");
		manual_node("/tool/xenstored", NULL);

		check_store();
	}
}


static unsigned int hash_from_key_fn(void *k)
{
	char *str = k;
	unsigned int hash = 5381;
	char c;

	while ((c = *str++))
		hash = ((hash << 5) + hash) + (unsigned int)c;

	return hash;
}


static int keys_equal_fn(void *key1, void *key2)
{
	return 0 == strcmp((char *)key1, (char *)key2);
}


static char *child_name(const char *s1, const char *s2)
{
	if (strcmp(s1, "/")) {
		return talloc_asprintf(NULL, "%s/%s", s1, s2);
	}
	else {
		return talloc_asprintf(NULL, "/%s", s2);
	}
}


static void remember_string(struct hashtable *hash, const char *str)
{
	char *k = malloc(strlen(str) + 1);
	strcpy(k, str);
	hashtable_insert(hash, k, (void *)1);
}


/**
 * A node has a children field that names the children of the node, separated
 * by NULs.  We check whether there are entries in there that are duplicated
 * (and if so, delete the second one), and whether there are any that do not
 * have a corresponding child node (and if so, delete them).  Each valid child
 * is then recursively checked.
 *
 * No deleting is performed if the recovery flag is cleared (i.e. -R was
 * passed on the command line).
 *
 * As we go, we record each node in the given reachable hashtable.  These
 * entries will be used later in clean_store.
 */
static void check_store_(const char *name, struct hashtable *reachable)
{
	struct node *node = read_node(NULL, name);

	if (node) {
		size_t i = 0;

		struct hashtable * children =
			create_hashtable(16, hash_from_key_fn, keys_equal_fn);

		remember_string(reachable, name);

		while (i < node->childlen) {
			size_t childlen = strlen(node->children + i);
			char * childname = child_name(node->name,
						      node->children + i);
			struct node *childnode = read_node(NULL, childname);
			
			if (childnode) {
				if (hashtable_search(children, childname)) {
					log("check_store: '%s' is duplicated!",
					    childname);

					if (recovery) {
						remove_child_entry(NULL, node,
								   i);
						i -= childlen + 1;
					}
				}
				else {
					remember_string(children, childname);
					check_store_(childname, reachable);
				}
			}
			else {
				log("check_store: No child '%s' found!\n",
				    childname);

				if (recovery) {
					remove_child_entry(NULL, node, i);
					i -= childlen + 1;
				}
			}

			talloc_free(childnode);
			talloc_free(childname);
			i += childlen + 1;
		}

		hashtable_destroy(children, 0 /* Don't free values (they are
						 all (void *)1) */);
		talloc_free(node);
	}
	else {
		/* Impossible, because no database should ever be without the
		   root, and otherwise, we've just checked in our caller
		   (which made a recursive call to get here). */
		   
		log("check_store: No child '%s' found: impossible!", name);
	}
}


/**
 * Helper to clean_store below.
 */
static int clean_store_(TDB_CONTEXT *tdb, TDB_DATA key, TDB_DATA val,
			void *private)
{
	struct hashtable *reachable = private;
	char * name = talloc_strndup(NULL, key.dptr, key.dsize);

	if (!hashtable_search(reachable, name)) {
		log("clean_store: '%s' is orphaned!", name);
		if (recovery) {
			tdb_delete(tdb, key);
		}
	}

	talloc_free(name);

	return 0;
}


/**
 * Given the list of reachable nodes, iterate over the whole store, and
 * remove any that were not reached.
 */
static void clean_store(struct hashtable *reachable)
{
	tdb_traverse(tdb_ctx, &clean_store_, reachable);
}


static void check_store(void)
{
	char * root = talloc_strdup(NULL, "/");
	struct hashtable * reachable =
		create_hashtable(16, hash_from_key_fn, keys_equal_fn);
 
	log("Checking store ...");
	check_store_(root, reachable);
	clean_store(reachable);
	log("Checking store complete.");

	hashtable_destroy(reachable, 0 /* Don't free values (they are all
					  (void *)1) */);
	talloc_free(root);
}


/* Something is horribly wrong: check the store. */
static void corrupt(struct connection *conn, const char *fmt, ...)
{
	va_list arglist;
	char *str;
	int saved_errno = errno;

	va_start(arglist, fmt);
	str = talloc_vasprintf(NULL, fmt, arglist);
	va_end(arglist);

	log("corruption detected by connection %i: err %s: %s",
	    conn ? (int)conn->id : -1, strerror(saved_errno), str);

	check_store();
}


static void write_pidfile(const char *pidfile)
{
	char buf[100];
	int len;
	int fd;

	fd = open(pidfile, O_RDWR | O_CREAT, 0600);
	if (fd == -1)
		barf_perror("Opening pid file %s", pidfile);

	/* We exit silently if daemon already running. */
	if (lockf(fd, F_TLOCK, 0) == -1)
		exit(0);

	len = snprintf(buf, sizeof(buf), "%ld\n", (long)getpid());
	if (write(fd, buf, len) != len)
		barf_perror("Writing pid file %s", pidfile);
}

/* Stevens. */
static void daemonize(void)
{
	pid_t pid;

	/* Separate from our parent via fork, so init inherits us. */
	if ((pid = fork()) < 0)
		barf_perror("Failed to fork daemon");
	if (pid != 0)
		exit(0);

	/* Session leader so ^C doesn't whack us. */
	setsid();

	/* Let session leader exit so child cannot regain CTTY */
	if ((pid = fork()) < 0)
		barf_perror("Failed to fork daemon");
	if (pid != 0)
		exit(0);

	/* Move off any mount points we might be in. */
	if (chdir("/") == -1)
		barf_perror("Failed to chdir");

	/* Discard our parent's old-fashioned umask prejudices. */
	umask(0);
}


static void usage(void)
{
	fprintf(stderr,
"Usage:\n"
"\n"
"  xenstored <options>\n"
"\n"
"where options may include:\n"
"\n"
"  --no-domain-init    to state that xenstored should not initialise dom0,\n"
"  --pid-file <file>   giving a file for the daemon's pid to be written,\n"
"  --help              to output this message,\n"
"  --no-fork           to request that the daemon does not fork,\n"
"  --output-pid        to request that the pid of the daemon is output,\n"
"  --trace-file <file> giving the file for logging, and\n"
"  --entry-nb <nb>     limit the number of entries per domain,\n"
"  --entry-size <size> limit the size of entry per domain, and\n"
"  --entry-watch <nb>  limit the number of watches per domain,\n"
"  --transaction <nb>  limit the number of transaction allowed per domain,\n"
"  --no-recovery       to request that no recovery should be attempted when\n"
"                      the store is corrupted (debug only),\n"
"  --preserve-local    to request that /local is preserved on start-up,\n"
"  --verbose           to request verbose execution.\n");
}


static struct option options[] = {
	{ "no-domain-init", 0, NULL, 'D' },
	{ "entry-nb", 1, NULL, 'E' },
	{ "pid-file", 1, NULL, 'F' },
	{ "help", 0, NULL, 'H' },
	{ "no-fork", 0, NULL, 'N' },
	{ "output-pid", 0, NULL, 'P' },
	{ "entry-size", 1, NULL, 'S' },
	{ "trace-file", 1, NULL, 'T' },
	{ "transaction", 1, NULL, 't' },
	{ "no-recovery", 0, NULL, 'R' },
	{ "preserve-local", 0, NULL, 'L' },
	{ "verbose", 0, NULL, 'V' },
	{ "watch-nb", 1, NULL, 'W' },
	{ NULL, 0, NULL, 0 } };

extern void dump_conn(struct connection *conn); 

int main(int argc, char *argv[])
{
	int opt, *sock, *ro_sock, max;
	struct sockaddr_un addr;
	fd_set inset, outset;
	bool dofork = true;
	bool outputpid = false;
	bool no_domain_init = false;
	const char *pidfile = NULL;
	int evtchn_fd = -1;
	struct timeval *timeout;

	while ((opt = getopt_long(argc, argv, "DE:F:HNPS:t:T:RLVW:", options,
				  NULL)) != -1) {
		switch (opt) {
		case 'D':
			no_domain_init = true;
			break;
		case 'E':
			quota_nb_entry_per_domain = strtol(optarg, NULL, 10);
			break;
		case 'F':
			pidfile = optarg;
			break;
		case 'H':
			usage();
			return 0;
		case 'N':
			dofork = false;
			break;
		case 'P':
			outputpid = true;
			break;
		case 'R':
			recovery = false;
			break;
		case 'L':
			remove_local = false;
			break;
		case 'S':
			quota_max_entry_size = strtol(optarg, NULL, 10);
			break;
		case 't':
			quota_max_transaction = strtol(optarg, NULL, 10);
			break;
		case 'T':
			tracefile = optarg;
			break;
		case 'V':
			verbose = true;
			break;
		case 'W':
			quota_nb_watch_per_domain = strtol(optarg, NULL, 10);
			break;
		}
	}
	if (optind != argc)
		barf("%s: No arguments desired", argv[0]);

	reopen_log();

	/* make sure xenstored directory exists */
	if (mkdir(xs_daemon_rundir(), 0755)) {
		if (errno != EEXIST) {
			perror("error: mkdir daemon rundir");
			exit(-1);
		}
	}

	if (mkdir(xs_daemon_rootdir(), 0755)) {
		if (errno != EEXIST) {
			perror("error: mkdir daemon rootdir");
			exit(-1);
		}
	}

	if (dofork) {
		openlog("xenstored", 0, LOG_DAEMON);
		daemonize();
	}
	if (pidfile)
		write_pidfile(pidfile);

	/* Talloc leak reports go to stderr, which is closed if we fork. */
	if (!dofork)
		talloc_enable_leak_report_full();

	/* Create sockets for them to listen to. */
	sock = talloc(talloc_autofree_context(), int);
	*sock = socket(PF_UNIX, SOCK_STREAM, 0);
	if (*sock < 0)
		barf_perror("Could not create socket");
	ro_sock = talloc(talloc_autofree_context(), int);
	*ro_sock = socket(PF_UNIX, SOCK_STREAM, 0);
	if (*ro_sock < 0)
		barf_perror("Could not create socket");
	talloc_set_destructor(sock, destroy_fd);
	talloc_set_destructor(ro_sock, destroy_fd);

	/* Don't kill us with SIGPIPE. */
	signal(SIGPIPE, SIG_IGN);

	/* FIXME: Be more sophisticated, don't mug running daemon. */
	unlink(xs_daemon_socket());
	unlink(xs_daemon_socket_ro());

	addr.sun_family = AF_UNIX;
	strcpy(addr.sun_path, xs_daemon_socket());
	if (bind(*sock, (struct sockaddr *)&addr, sizeof(addr)) != 0)
		barf_perror("Could not bind socket to %s", xs_daemon_socket());
	strcpy(addr.sun_path, xs_daemon_socket_ro());
	if (bind(*ro_sock, (struct sockaddr *)&addr, sizeof(addr)) != 0)
		barf_perror("Could not bind socket to %s",
			    xs_daemon_socket_ro());
	if (chmod(xs_daemon_socket(), 0600) != 0
	    || chmod(xs_daemon_socket_ro(), 0660) != 0)
		barf_perror("Could not chmod sockets");

	if (listen(*sock, 1) != 0
	    || listen(*ro_sock, 1) != 0)
		barf_perror("Could not listen on sockets");

	if (pipe(reopen_log_pipe)) {
		barf_perror("pipe");
	}

	/* Setup the database */
	setup_structure();

	/* Listen to hypervisor. */
	if (!no_domain_init)
		domain_init();

	/* Restore existing connections. */
	restore_existing_connections();

	if (outputpid) {
		printf("%ld\n", (long)getpid());
		fflush(stdout);
	}

	/* redirect to /dev/null now we're ready to accept connections */
	if (dofork) {
		int devnull = open("/dev/null", O_RDWR);
		if (devnull == -1)
			barf_perror("Could not open /dev/null\n");
		dup2(devnull, STDIN_FILENO);
		dup2(devnull, STDOUT_FILENO);
		dup2(devnull, STDERR_FILENO);
		close(devnull);
		xprintf = trace;
	}

	signal(SIGHUP, trigger_reopen_log);

	if (xce_handle != -1)
		evtchn_fd = xc_evtchn_fd(xce_handle);

	/* Get ready to listen to the tools. */
	max = initialize_set(&inset, &outset, *sock, *ro_sock, &timeout);

	/* Tell the kernel we're up and running. */
	xenbus_notify_running();

	/* Main loop. */
	for (;;) {
		struct connection *conn, *next;

		if (select(max+1, &inset, &outset, NULL, timeout) < 0) {
			if (errno == EINTR)
				continue;
			barf_perror("Select failed");
		}

		if (FD_ISSET(reopen_log_pipe[0], &inset)) {
			char c;
			if (read(reopen_log_pipe[0], &c, 1) != 1)
				barf_perror("read failed");
			reopen_log();
		}

		if (FD_ISSET(*sock, &inset))
			accept_connection(*sock, true);

		if (FD_ISSET(*ro_sock, &inset))
			accept_connection(*ro_sock, false);

		if (evtchn_fd != -1 && FD_ISSET(evtchn_fd, &inset))
			handle_event();

		next = list_entry(connections.next, typeof(*conn), list);
		if (&next->list != &connections)
			talloc_increase_ref_count(next);
		while (&next->list != &connections) {
			conn = next;

			next = list_entry(conn->list.next,
					  typeof(*conn), list);
			if (&next->list != &connections)
				talloc_increase_ref_count(next);

			if (conn->domain) {
				if (domain_can_read(conn))
					handle_input(conn);
				if (talloc_free(conn) == 0)
					continue;

				talloc_increase_ref_count(conn);
				if (domain_can_write(conn) &&
				    !list_empty(&conn->out_list))
					handle_output(conn);
				if (talloc_free(conn) == 0)
					continue;
			} else {
				if (FD_ISSET(conn->fd, &inset))
					handle_input(conn);
				if (talloc_free(conn) == 0)
					continue;

				talloc_increase_ref_count(conn);
				if (FD_ISSET(conn->fd, &outset))
					handle_output(conn);
				if (talloc_free(conn) == 0)
					continue;
			}
		}

		max = initialize_set(&inset, &outset, *sock, *ro_sock,
				     &timeout);
	}
}

/*
 * Local variables:
 *  c-file-style: "linux"
 *  indent-tabs-mode: t
 *  c-indent-level: 8
 *  c-basic-offset: 8
 *  tab-width: 8
 * End:
 */

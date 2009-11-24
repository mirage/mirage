/* 
    Internal interfaces for Xen Store Daemon.
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

#ifndef _XENSTORED_CORE_H
#define _XENSTORED_CORE_H

#include <xenctrl.h>

#include <sys/types.h>
#include <dirent.h>
#include <stdbool.h>
#include <stdint.h>
#include <errno.h>
#include "xs_lib.h"
#include "list.h"
#include "tdb.h"

struct buffered_data
{
	struct list_head list;

	/* Are we still doing the header? */
	bool inhdr;

	/* How far are we? */
	unsigned int used;

	union {
		struct xsd_sockmsg msg;
		char raw[sizeof(struct xsd_sockmsg)];
	} hdr;

	/* The actual data. */
	char *buffer;
};

struct connection;
typedef int connwritefn_t(struct connection *, const void *, unsigned int);
typedef int connreadfn_t(struct connection *, void *, unsigned int);

struct connection
{
	struct list_head list;

	/* The file descriptor we came in on. */
	int fd;

	/* Who am I? 0 for socket connections. */
	unsigned int id;

	/* Is this a read-only connection? */
	bool can_write;

	/* Buffered incoming data. */
	struct buffered_data *in;

	/* Buffered output data */
	struct list_head out_list;

	/* Transaction context for current request (NULL if none). */
	struct transaction *transaction;

	/* List of in-progress transactions. */
	struct list_head transaction_list;
	uint32_t next_transaction_id;
	unsigned int transaction_started;

	/* The domain I'm associated with, if any. */
	struct domain *domain;

        /* The target of the domain I'm associated with. */
        struct connection *target;

	/* My watches. */
	struct list_head watches;

	/* Methods for communicating over this connection: write can be NULL */
	connwritefn_t *write;
	connreadfn_t *read;
};
extern struct list_head connections;

struct node {
	const char *name;

	/* Database I came from */
	TDB_CONTEXT *tdb;

	/* Parent (optional) */
	struct node *parent;

	/* Permissions. */
	unsigned int num_perms;
	struct xs_permissions *perms;

	/* Contents. */
	unsigned int datalen;
	void *data;

	/* Children, each nul-terminated. */
	unsigned int childlen;
	char *children;
};

/* Break input into vectors, return the number, fill in up to num of them. */
unsigned int get_strings(struct buffered_data *data,
			 char *vec[], unsigned int num);

/* Is child node a child or equal to parent node? */
bool is_child(const char *child, const char *parent);

void send_reply(struct connection *conn, enum xsd_sockmsg_type type,
		const void *data, unsigned int len);

/* Some routines (write, mkdir, etc) just need a non-error return */
void send_ack(struct connection *conn, enum xsd_sockmsg_type type);

/* Send an error: error is usually "errno". */
void send_error(struct connection *conn, int error);

/* Canonicalize this path if possible. */
char *canonicalize(struct connection *conn, const char *node);

/* Check if node is an event node. */
bool check_event_node(const char *node);

/* Get this node, checking we have permissions. */
struct node *get_node(struct connection *conn,
		      const char *name,
		      enum xs_perm_type perm);

/* Get TDB context for this connection */
TDB_CONTEXT *tdb_context(struct connection *conn);

/* Destructor for tdbs: required for transaction code */
int destroy_tdb(void *_tdb);

/* Replace the tdb: required for transaction code */
bool replace_tdb(const char *newname, TDB_CONTEXT *newtdb);

struct connection *new_connection(connwritefn_t *write, connreadfn_t *read);


/* Is this a valid node name? */
bool is_valid_nodename(const char *node);

/* Tracing infrastructure. */
void trace_create(const void *data, const char *type);
void trace_destroy(const void *data, const char *type);
void trace_watch_timeout(const struct connection *conn, const char *node, const char *token);
void trace(const char *fmt, ...);
void dtrace_io(const struct connection *conn, const struct buffered_data *data, int out);

extern int event_fd;

/* Map the kernel's xenstore page. */
void *xenbus_map(void);

/* Return the event channel used by xenbus. */
evtchn_port_t xenbus_evtchn(void);

/* Tell the kernel xenstored is running. */
void xenbus_notify_running(void);

#endif /* _XENSTORED_CORE_H */

/*
 * Local variables:
 *  c-file-style: "linux"
 *  indent-tabs-mode: t
 *  c-indent-level: 8
 *  c-basic-offset: 8
 *  tab-width: 8
 * End:
 */

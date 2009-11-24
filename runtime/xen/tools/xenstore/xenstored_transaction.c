/* 
    Transaction code for Xen Store Daemon.
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

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <time.h>
#include <assert.h>
#include <stdarg.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include "talloc.h"
#include "list.h"
#include "xenstored_transaction.h"
#include "xenstored_watch.h"
#include "xenstored_domain.h"
#include "xs_lib.h"
#include "utils.h"

struct changed_node
{
	/* List of all changed nodes in the context of this transaction. */
	struct list_head list;

	/* The name of the node. */
	char *node;

	/* And the children? (ie. rm) */
	bool recurse;
};

struct changed_domain
{
	/* List of all changed domains in the context of this transaction. */
	struct list_head list;

	/* Identifier of the changed domain. */
	unsigned int domid;

	/* Amount by which this domain's nbentry field has changed. */
	int nbentry;
};

struct transaction
{
	/* List of all transactions active on this connection. */
	struct list_head list;

	/* Connection-local identifier for this transaction. */
	uint32_t id;

	/* Generation when transaction started. */
	unsigned int generation;

	/* TDB to work on, and filename */
	TDB_CONTEXT *tdb;
	char *tdb_name;

	/* List of changed nodes. */
	struct list_head changes;

	/* List of changed domains - to record the changed domain entry number */
	struct list_head changed_domains;
};

extern int quota_max_transaction;
static unsigned int generation;

/* Return tdb context to use for this connection. */
TDB_CONTEXT *tdb_transaction_context(struct transaction *trans)
{
	return trans->tdb;
}

/* Callers get a change node (which can fail) and only commit after they've
 * finished.  This way they don't have to unwind eg. a write. */
void add_change_node(struct transaction *trans, const char *node, bool recurse)
{
	struct changed_node *i;

	if (!trans) {
		/* They're changing the global database. */
		generation++;
		return;
	}

	list_for_each_entry(i, &trans->changes, list)
		if (streq(i->node, node))
			return;

	i = talloc(trans, struct changed_node);
	i->node = talloc_strdup(i, node);
	i->recurse = recurse;
	list_add_tail(&i->list, &trans->changes);
}

static int destroy_transaction(void *_transaction)
{
	struct transaction *trans = _transaction;

	trace_destroy(trans, "transaction");
	if (trans->tdb)
		tdb_close(trans->tdb);
	unlink(trans->tdb_name);
	return 0;
}

struct transaction *transaction_lookup(struct connection *conn, uint32_t id)
{
	struct transaction *trans;

	if (id == 0)
		return NULL;

	list_for_each_entry(trans, &conn->transaction_list, list)
		if (trans->id == id)
			return trans;

	return ERR_PTR(-ENOENT);
}

void do_transaction_start(struct connection *conn, struct buffered_data *in)
{
	struct transaction *trans, *exists;
	char id_str[20];

	/* We don't support nested transactions. */
	if (conn->transaction) {
		send_error(conn, EBUSY);
		return;
	}

	if (conn->id && conn->transaction_started > quota_max_transaction) {
		send_error(conn, ENOSPC);
		return;
	}

	/* Attach transaction to input for autofree until it's complete */
	trans = talloc(in, struct transaction);
	INIT_LIST_HEAD(&trans->changes);
	INIT_LIST_HEAD(&trans->changed_domains);
	trans->generation = generation;
	trans->tdb_name = talloc_asprintf(trans, "%s.%p",
					  xs_daemon_tdb(), trans);
	trans->tdb = tdb_copy(tdb_context(conn), trans->tdb_name);
	if (!trans->tdb) {
		send_error(conn, errno);
		return;
	}
	/* Make it close if we go away. */
	talloc_steal(trans, trans->tdb);

	/* Pick an unused transaction identifier. */
	do {
		trans->id = conn->next_transaction_id;
		exists = transaction_lookup(conn, conn->next_transaction_id++);
	} while (!IS_ERR(exists));

	/* Now we own it. */
	list_add_tail(&trans->list, &conn->transaction_list);
	talloc_steal(conn, trans);
	talloc_set_destructor(trans, destroy_transaction);
	conn->transaction_started++;

	snprintf(id_str, sizeof(id_str), "%u", trans->id);
	send_reply(conn, XS_TRANSACTION_START, id_str, strlen(id_str)+1);
}

void do_transaction_end(struct connection *conn, const char *arg)
{
	struct changed_node *i;
	struct changed_domain *d;
	struct transaction *trans;

	if (!arg || (!streq(arg, "T") && !streq(arg, "F"))) {
		send_error(conn, EINVAL);
		return;
	}

	if ((trans = conn->transaction) == NULL) {
		send_error(conn, ENOENT);
		return;
	}

	conn->transaction = NULL;
	list_del(&trans->list);
	conn->transaction_started--;

	/* Attach transaction to arg for auto-cleanup */
	talloc_steal(arg, trans);

	if (streq(arg, "T")) {
		/* FIXME: Merge, rather failing on any change. */
		if (trans->generation != generation) {
			send_error(conn, EAGAIN);
			return;
		}
		if (!replace_tdb(trans->tdb_name, trans->tdb)) {
			send_error(conn, errno);
			return;
		}
		/* Don't close this: we won! */
		trans->tdb = NULL;

		/* fix domain entry for each changed domain */
		list_for_each_entry(d, &trans->changed_domains, list)
			domain_entry_fix(d->domid, d->nbentry);

		/* Fire off the watches for everything that changed. */
		list_for_each_entry(i, &trans->changes, list)
			fire_watches(conn, i->node, i->recurse);
		generation++;
	}
	send_ack(conn, XS_TRANSACTION_END);
}

void transaction_entry_inc(struct transaction *trans, unsigned int domid)
{
	struct changed_domain *d;

	list_for_each_entry(d, &trans->changed_domains, list)
		if (d->domid == domid) {
			d->nbentry++;
			return;
		}

	d = talloc(trans, struct changed_domain);
	d->domid = domid;
	d->nbentry = 1;
	list_add_tail(&d->list, &trans->changed_domains);
}

void transaction_entry_dec(struct transaction *trans, unsigned int domid)
{
	struct changed_domain *d;

	list_for_each_entry(d, &trans->changed_domains, list)
		if (d->domid == domid) {
			d->nbentry--;
			return;
		}

	d = talloc(trans, struct changed_domain);
	d->domid = domid;
	d->nbentry = -1;
	list_add_tail(&d->list, &trans->changed_domains);
}

void conn_delete_all_transactions(struct connection *conn)
{
	struct transaction *trans;

	while ((trans = list_top(&conn->transaction_list,
				 struct transaction, list))) {
		list_del(&trans->list);
		talloc_free(trans);
	}

	assert(conn->transaction == NULL);

	conn->transaction_started = 0;
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

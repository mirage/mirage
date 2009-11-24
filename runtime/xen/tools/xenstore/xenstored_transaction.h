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
#ifndef _XENSTORED_TRANSACTION_H
#define _XENSTORED_TRANSACTION_H
#include "xenstored_core.h"

struct transaction;

void do_transaction_start(struct connection *conn, struct buffered_data *node);
void do_transaction_end(struct connection *conn, const char *arg);

struct transaction *transaction_lookup(struct connection *conn, uint32_t id);

/* inc/dec entry number local to trans while changing a node */
void transaction_entry_inc(struct transaction *trans, unsigned int domid);
void transaction_entry_dec(struct transaction *trans, unsigned int domid);

/* This node was changed: can fail and longjmp. */
void add_change_node(struct transaction *trans, const char *node,
                     bool recurse);

/* Return tdb context to use for this connection. */
TDB_CONTEXT *tdb_transaction_context(struct transaction *trans);

void conn_delete_all_transactions(struct connection *conn);

#endif /* _XENSTORED_TRANSACTION_H */

/* 
    Domain communications for Xen Store Daemon.
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

#ifndef _XENSTORED_DOMAIN_H
#define _XENSTORED_DOMAIN_H

void handle_event(void);

/* domid, mfn, eventchn, path */
void do_introduce(struct connection *conn, struct buffered_data *in);

/* domid */
void do_is_domain_introduced(struct connection *conn, const char *domid_str);

/* domid */
void do_release(struct connection *conn, const char *domid_str);

/* domid */
void do_resume(struct connection *conn, const char *domid_str);

/* domid, target */
void do_set_target(struct connection *conn, struct buffered_data *in);

/* domid */
void do_get_domain_path(struct connection *conn, const char *domid_str);

/* Returns the event channel handle */
int domain_init(void);

/* Returns the implicit path of a connection (only domains have this) */
const char *get_implicit_path(const struct connection *conn);

/* Read existing connection information from store. */
void restore_existing_connections(void);

/* Can connection attached to domain read/write. */
bool domain_can_read(struct connection *conn);
bool domain_can_write(struct connection *conn);

bool domain_is_unprivileged(struct connection *conn);

/* Quota manipulation */
void domain_entry_inc(struct connection *conn, struct node *);
void domain_entry_dec(struct connection *conn, struct node *);
void domain_entry_fix(unsigned int domid, int num);
int domain_entry(struct connection *conn);
void domain_watch_inc(struct connection *conn);
void domain_watch_dec(struct connection *conn);
int domain_watch(struct connection *conn);

#endif /* _XENSTORED_DOMAIN_H */

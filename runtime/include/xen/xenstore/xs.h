/* 
    Xen Store Daemon providing simple tree-like database.
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

#ifndef _XS_H
#define _XS_H

#include <xs_lib.h>

#define XBT_NULL 0

struct xs_handle;
typedef uint32_t xs_transaction_t;

/* IMPORTANT: For details on xenstore protocol limits, see
 * docs/misc/xenstore.txt in the Xen public source repository, and use the
 * XENSTORE_*_MAX limit macros defined in xen/io/xs_wire.h.
 */

/* On failure, these routines set errno. */

/* Connect to the xs daemon.
 * Returns a handle or NULL.
 */
struct xs_handle *xs_daemon_open(void);
struct xs_handle *xs_domain_open(void);

/* Connect to the xs daemon (readonly for non-root clients).
 * Returns a handle or NULL.
 */
struct xs_handle *xs_daemon_open_readonly(void);

/* Close the connection to the xs daemon. */
void xs_daemon_close(struct xs_handle *);

/* Get contents of a directory.
 * Returns a malloced array: call free() on it after use.
 * Num indicates size.
 */
char **xs_directory(struct xs_handle *h, xs_transaction_t t,
		    const char *path, unsigned int *num);

/* Get the value of a single file, nul terminated.
 * Returns a malloced value: call free() on it after use.
 * len indicates length in bytes, not including terminator.
 */
void *xs_read(struct xs_handle *h, xs_transaction_t t,
	      const char *path, unsigned int *len);

/* Write the value of a single file.
 * Returns false on failure.
 */
bool xs_write(struct xs_handle *h, xs_transaction_t t,
	      const char *path, const void *data, unsigned int len);

/* Create a new directory.
 * Returns false on failure, or success if it already exists.
 */
bool xs_mkdir(struct xs_handle *h, xs_transaction_t t,
	      const char *path);

/* Destroy a file or directory (and children).
 * Returns false on failure, or if it doesn't exist.
 */
bool xs_rm(struct xs_handle *h, xs_transaction_t t,
	   const char *path);

/* Get permissions of node (first element is owner, first perms is "other").
 * Returns malloced array, or NULL: call free() after use.
 */
struct xs_permissions *xs_get_permissions(struct xs_handle *h,
					  xs_transaction_t t,
					  const char *path, unsigned int *num);

/* Set permissions of node (must be owner).
 * Returns false on failure.
 */
bool xs_set_permissions(struct xs_handle *h, xs_transaction_t t,
			const char *path, struct xs_permissions *perms,
			unsigned int num_perms);

/* Watch a node for changes (poll on fd to detect, or call read_watch()).
 * When the node (or any child) changes, fd will become readable.
 * Token is returned when watch is read, to allow matching.
 * Returns false on failure.
 */
bool xs_watch(struct xs_handle *h, const char *path, const char *token);

/* Return the FD to poll on to see if a watch has fired. */
int xs_fileno(struct xs_handle *h);

/* Find out what node change was on (will block if nothing pending).
 * Returns array containing the path and token. Use XS_WATCH_* to access these
 * elements. Call free() after use.
 */
char **xs_read_watch(struct xs_handle *h, unsigned int *num);

/* Remove a watch on a node: implicitly acks any outstanding watch.
 * Returns false on failure (no watch on that node).
 */
bool xs_unwatch(struct xs_handle *h, const char *path, const char *token);

/* Start a transaction: changes by others will not be seen during this
 * transaction, and changes will not be visible to others until end.
 * Returns NULL on failure.
 */
xs_transaction_t xs_transaction_start(struct xs_handle *h);

/* End a transaction.
 * If abandon is true, transaction is discarded instead of committed.
 * Returns false on failure: if errno == EAGAIN, you have to restart
 * transaction.
 */
bool xs_transaction_end(struct xs_handle *h, xs_transaction_t t,
			bool abort);

/* Introduce a new domain.
 * This tells the store daemon about a shared memory page, event channel and
 * store path associated with a domain: the domain uses these to communicate.
 */
bool xs_introduce_domain(struct xs_handle *h,
			 unsigned int domid,
			 unsigned long mfn,
                         unsigned int eventchn); 

/* Set the target of a domain
 * This tells the store daemon that a domain is targetting another one, so
 * it should let it tinker with it.
 */
bool xs_set_target(struct xs_handle *h,
		   unsigned int domid,
		   unsigned int target);

/* Resume a domain.
 * Clear the shutdown flag for this domain in the store.
 */
bool xs_resume_domain(struct xs_handle *h, unsigned int domid);

/* Release a domain.
 * Tells the store domain to release the memory page to the domain.
 */
bool xs_release_domain(struct xs_handle *h, unsigned int domid);

/* Query the home path of a domain.  Call free() after use.
 */
char *xs_get_domain_path(struct xs_handle *h, unsigned int domid);

/* Return whether the domain specified has been introduced to xenstored.
 */
bool xs_is_domain_introduced(struct xs_handle *h, unsigned int domid);

/* Only useful for DEBUG versions */
char *xs_debug_command(struct xs_handle *h, const char *cmd,
		       void *data, unsigned int len);

int xs_suspend_evtchn_port(int domid);
#endif /* _XS_H */

/*
 * Local variables:
 *  c-file-style: "linux"
 *  indent-tabs-mode: t
 *  c-indent-level: 8
 *  c-basic-offset: 8
 *  tab-width: 8
 * End:
 */

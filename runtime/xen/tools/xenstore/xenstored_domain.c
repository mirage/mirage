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

#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdarg.h>

#include "utils.h"
#include "talloc.h"
#include "xenstored_core.h"
#include "xenstored_domain.h"
#include "xenstored_transaction.h"
#include "xenstored_watch.h"

#include <xenctrl.h>

static int *xc_handle;
static evtchn_port_t virq_port;

int xce_handle = -1; 

struct domain
{
	struct list_head list;

	/* The id of this domain */
	unsigned int domid;

	/* Event channel port */
	evtchn_port_t port;

	/* The remote end of the event channel, used only to validate
	   repeated domain introductions. */
	evtchn_port_t remote_port;

	/* The mfn associated with the event channel, used only to validate
	   repeated domain introductions. */
	unsigned long mfn;

	/* Domain path in store. */
	char *path;

	/* Shared page. */
	struct xenstore_domain_interface *interface;

	/* The connection associated with this. */
	struct connection *conn;

	/* Have we noticed that this domain is shutdown? */
	int shutdown;

	/* number of entry from this domain in the store */
	int nbentry;

	/* number of watch for this domain */
	int nbwatch;
};

static LIST_HEAD(domains);

static bool check_indexes(XENSTORE_RING_IDX cons, XENSTORE_RING_IDX prod)
{
	return ((prod - cons) <= XENSTORE_RING_SIZE);
}

static void *get_output_chunk(XENSTORE_RING_IDX cons,
			      XENSTORE_RING_IDX prod,
			      char *buf, uint32_t *len)
{
	*len = XENSTORE_RING_SIZE - MASK_XENSTORE_IDX(prod);
	if ((XENSTORE_RING_SIZE - (prod - cons)) < *len)
		*len = XENSTORE_RING_SIZE - (prod - cons);
	return buf + MASK_XENSTORE_IDX(prod);
}

static const void *get_input_chunk(XENSTORE_RING_IDX cons,
				   XENSTORE_RING_IDX prod,
				   const char *buf, uint32_t *len)
{
	*len = XENSTORE_RING_SIZE - MASK_XENSTORE_IDX(cons);
	if ((prod - cons) < *len)
		*len = prod - cons;
	return buf + MASK_XENSTORE_IDX(cons);
}

static int writechn(struct connection *conn,
		    const void *data, unsigned int len)
{
	uint32_t avail;
	void *dest;
	struct xenstore_domain_interface *intf = conn->domain->interface;
	XENSTORE_RING_IDX cons, prod;

	/* Must read indexes once, and before anything else, and verified. */
	cons = intf->rsp_cons;
	prod = intf->rsp_prod;
	xen_mb();

	if (!check_indexes(cons, prod)) {
		errno = EIO;
		return -1;
	}

	dest = get_output_chunk(cons, prod, intf->rsp, &avail);
	if (avail < len)
		len = avail;

	memcpy(dest, data, len);
	xen_mb();
	intf->rsp_prod += len;

	xc_evtchn_notify(xce_handle, conn->domain->port);

	return len;
}

static int readchn(struct connection *conn, void *data, unsigned int len)
{
	uint32_t avail;
	const void *src;
	struct xenstore_domain_interface *intf = conn->domain->interface;
	XENSTORE_RING_IDX cons, prod;

	/* Must read indexes once, and before anything else, and verified. */
	cons = intf->req_cons;
	prod = intf->req_prod;
	xen_mb();

	if (!check_indexes(cons, prod)) {
		errno = EIO;
		return -1;
	}

	src = get_input_chunk(cons, prod, intf->req, &avail);
	if (avail < len)
		len = avail;

	memcpy(data, src, len);
	xen_mb();
	intf->req_cons += len;

	xc_evtchn_notify(xce_handle, conn->domain->port);

	return len;
}

static int destroy_domain(void *_domain)
{
	struct domain *domain = _domain;

	list_del(&domain->list);

	if (domain->port) {
		if (xc_evtchn_unbind(xce_handle, domain->port) == -1)
			eprintf("> Unbinding port %i failed!\n", domain->port);
	}

	if (domain->interface)
		munmap(domain->interface, getpagesize());

	fire_watches(NULL, "@releaseDomain", false);

	return 0;
}

static void domain_cleanup(void)
{
	xc_dominfo_t dominfo;
	struct domain *domain, *tmp;
	int notify = 0;

	list_for_each_entry_safe(domain, tmp, &domains, list) {
		if (xc_domain_getinfo(*xc_handle, domain->domid, 1,
				      &dominfo) == 1 &&
		    dominfo.domid == domain->domid) {
			if ((dominfo.crashed || dominfo.shutdown)
			    && !domain->shutdown) {
				domain->shutdown = 1;
				notify = 1;
			}
			if (!dominfo.dying)
				continue;
		}
		talloc_free(domain->conn);
		notify = 0; /* destroy_domain() fires the watch */
	}

	if (notify)
		fire_watches(NULL, "@releaseDomain", false);
}

/* We scan all domains rather than use the information given here. */
void handle_event(void)
{
	evtchn_port_t port;

	if ((port = xc_evtchn_pending(xce_handle)) == -1)
		barf_perror("Failed to read from event fd");

	if (port == virq_port)
		domain_cleanup();

	if (xc_evtchn_unmask(xce_handle, port) == -1)
		barf_perror("Failed to write to event fd");
}

bool domain_can_read(struct connection *conn)
{
	struct xenstore_domain_interface *intf = conn->domain->interface;
	return (intf->req_cons != intf->req_prod);
}

bool domain_is_unprivileged(struct connection *conn)
{
	return (conn && conn->domain && conn->domain->domid != 0);
}

bool domain_can_write(struct connection *conn)
{
	struct xenstore_domain_interface *intf = conn->domain->interface;
	return ((intf->rsp_prod - intf->rsp_cons) != XENSTORE_RING_SIZE);
}

static char *talloc_domain_path(void *context, unsigned int domid)
{
	return talloc_asprintf(context, "/local/domain/%u", domid);
}

static struct domain *new_domain(void *context, unsigned int domid,
				 int port)
{
	struct domain *domain;
	int rc;

	domain = talloc(context, struct domain);
	domain->port = 0;
	domain->shutdown = 0;
	domain->domid = domid;
	domain->path = talloc_domain_path(domain, domid);

	list_add(&domain->list, &domains);
	talloc_set_destructor(domain, destroy_domain);

	/* Tell kernel we're interested in this event. */
	rc = xc_evtchn_bind_interdomain(xce_handle, domid, port);
	if (rc == -1)
	    return NULL;
	domain->port = rc;

	domain->conn = new_connection(writechn, readchn);
	domain->conn->domain = domain;
	domain->conn->id = domid;

	domain->remote_port = port;
	domain->nbentry = 0;
	domain->nbwatch = 0;

	return domain;
}


static struct domain *find_domain_by_domid(unsigned int domid)
{
	struct domain *i;

	list_for_each_entry(i, &domains, list) {
		if (i->domid == domid)
			return i;
	}
	return NULL;
}

static void domain_conn_reset(struct domain *domain)
{
	struct connection *conn = domain->conn;
	struct buffered_data *out;

	conn_delete_all_watches(conn);
	conn_delete_all_transactions(conn);

	while ((out = list_top(&conn->out_list, struct buffered_data, list))) {
		list_del(&out->list);
		talloc_free(out);
	}

	talloc_free(conn->in->buffer);
	memset(conn->in, 0, sizeof(*conn->in));
	conn->in->inhdr = true;

	domain->interface->req_cons = domain->interface->req_prod = 0;
	domain->interface->rsp_cons = domain->interface->rsp_prod = 0;
}

/* domid, mfn, evtchn, path */
void do_introduce(struct connection *conn, struct buffered_data *in)
{
	struct domain *domain;
	char *vec[3];
	unsigned int domid;
	unsigned long mfn;
	evtchn_port_t port;
	int rc;
	struct xenstore_domain_interface *interface;

	if (get_strings(in, vec, ARRAY_SIZE(vec)) < ARRAY_SIZE(vec)) {
		send_error(conn, EINVAL);
		return;
	}

	if (conn->id != 0 || !conn->can_write) {
		send_error(conn, EACCES);
		return;
	}

	domid = atoi(vec[0]);
	mfn = atol(vec[1]);
	port = atoi(vec[2]);

	/* Sanity check args. */
	if (port <= 0) { 
		send_error(conn, EINVAL);
		return;
	}

	domain = find_domain_by_domid(domid);

	if (domain == NULL) {
		interface = xc_map_foreign_range(
			*xc_handle, domid,
			getpagesize(), PROT_READ|PROT_WRITE, mfn);
		if (!interface) {
			send_error(conn, errno);
			return;
		}
		/* Hang domain off "in" until we're finished. */
		domain = new_domain(in, domid, port);
		if (!domain) {
			munmap(interface, getpagesize());
			send_error(conn, errno);
			return;
		}
		domain->interface = interface;
		domain->mfn = mfn;

		/* Now domain belongs to its connection. */
		talloc_steal(domain->conn, domain);

		fire_watches(NULL, "@introduceDomain", false);
	} else if ((domain->mfn == mfn) && (domain->conn != conn)) {
		/* Use XS_INTRODUCE for recreating the xenbus event-channel. */
		if (domain->port)
			xc_evtchn_unbind(xce_handle, domain->port);
		rc = xc_evtchn_bind_interdomain(xce_handle, domid, port);
		domain->port = (rc == -1) ? 0 : rc;
		domain->remote_port = port;
	} else {
		send_error(conn, EINVAL);
		return;
	}

	domain_conn_reset(domain);

	send_ack(conn, XS_INTRODUCE);
}

void do_set_target(struct connection *conn, struct buffered_data *in)
{
	char *vec[2];
	unsigned int domid, tdomid;
        struct domain *domain, *tdomain;
	if (get_strings(in, vec, ARRAY_SIZE(vec)) < ARRAY_SIZE(vec)) {
		send_error(conn, EINVAL);
		return;
	}

	if (conn->id != 0 || !conn->can_write) {
		send_error(conn, EACCES);
		return;
	}

	domid = atoi(vec[0]);
	tdomid = atoi(vec[1]);

        domain = find_domain_by_domid(domid);
	if (!domain) {
		send_error(conn, ENOENT);
		return;
	}
        if (!domain->conn) {
		send_error(conn, EINVAL);
		return;
	}

        tdomain = find_domain_by_domid(tdomid);
	if (!tdomain) {
		send_error(conn, ENOENT);
		return;
	}

        if (!tdomain->conn) {
		send_error(conn, EINVAL);
		return;
	}

        talloc_reference(domain->conn, tdomain->conn);
        domain->conn->target = tdomain->conn;

	send_ack(conn, XS_SET_TARGET);
}

/* domid */
void do_release(struct connection *conn, const char *domid_str)
{
	struct domain *domain;
	unsigned int domid;

	if (!domid_str) {
		send_error(conn, EINVAL);
		return;
	}

	domid = atoi(domid_str);
	if (!domid) {
		send_error(conn, EINVAL);
		return;
	}

	if (conn->id != 0) {
		send_error(conn, EACCES);
		return;
	}

	domain = find_domain_by_domid(domid);
	if (!domain) {
		send_error(conn, ENOENT);
		return;
	}

	if (!domain->conn) {
		send_error(conn, EINVAL);
		return;
	}

	talloc_free(domain->conn);

	send_ack(conn, XS_RELEASE);
}

void do_resume(struct connection *conn, const char *domid_str)
{
	struct domain *domain;
	unsigned int domid;

	if (!domid_str) {
		send_error(conn, EINVAL);
		return;
	}

	domid = atoi(domid_str);
	if (!domid) {
		send_error(conn, EINVAL);
		return;
	}

	if (conn->id != 0) {
		send_error(conn, EACCES);
		return;
	}

	domain = find_domain_by_domid(domid);
	if (!domain) {
		send_error(conn, ENOENT);
		return;
	}

	if (!domain->conn) {
		send_error(conn, EINVAL);
		return;
	}

	domain->shutdown = 0;
	
	send_ack(conn, XS_RESUME);
}

void do_get_domain_path(struct connection *conn, const char *domid_str)
{
	char *path;

	if (!domid_str) {
		send_error(conn, EINVAL);
		return;
	}

	path = talloc_domain_path(conn, atoi(domid_str));

	send_reply(conn, XS_GET_DOMAIN_PATH, path, strlen(path) + 1);

	talloc_free(path);
}

void do_is_domain_introduced(struct connection *conn, const char *domid_str)
{
	int result;
	unsigned int domid;

	if (!domid_str) {
		send_error(conn, EINVAL);
		return;
	}

	domid = atoi(domid_str);
	if (domid == DOMID_SELF)
		result = 1;
	else
		result = (find_domain_by_domid(domid) != NULL);

	send_reply(conn, XS_IS_DOMAIN_INTRODUCED, result ? "T" : "F", 2);
}

static int close_xc_handle(void *_handle)
{
	xc_interface_close(*(int *)_handle);
	return 0;
}

/* Returns the implicit path of a connection (only domains have this) */
const char *get_implicit_path(const struct connection *conn)
{
	if (!conn->domain)
		return NULL;
	return conn->domain->path;
}

/* Restore existing connections. */
void restore_existing_connections(void)
{
}

static int dom0_init(void) 
{ 
	evtchn_port_t port;
	struct domain *dom0;

	port = xenbus_evtchn();
	if (port == -1)
		return -1;

	dom0 = new_domain(NULL, 0, port); 
	if (dom0 == NULL)
		return -1;

	dom0->interface = xenbus_map();
	if (dom0->interface == NULL)
		return -1;

	talloc_steal(dom0->conn, dom0); 

	xc_evtchn_notify(xce_handle, dom0->port); 

	return 0; 
}

/* Returns the event channel handle. */
int domain_init(void)
{
	int rc;

	xc_handle = talloc(talloc_autofree_context(), int);
	if (!xc_handle)
		barf_perror("Failed to allocate domain handle");

	*xc_handle = xc_interface_open();
	if (*xc_handle < 0)
		barf_perror("Failed to open connection to hypervisor");

	talloc_set_destructor(xc_handle, close_xc_handle);

	xce_handle = xc_evtchn_open();

	if (xce_handle < 0)
		barf_perror("Failed to open evtchn device");

	if (dom0_init() != 0) 
		barf_perror("Failed to initialize dom0 state"); 

	if ((rc = xc_evtchn_bind_virq(xce_handle, VIRQ_DOM_EXC)) == -1)
		barf_perror("Failed to bind to domain exception virq port");
	virq_port = rc;

	return xce_handle;
}

void domain_entry_inc(struct connection *conn, struct node *node)
{
	struct domain *d;

	if (!conn)
		return;

	if (node->perms && node->perms[0].id != conn->id) {
		if (conn->transaction) {
			transaction_entry_inc(conn->transaction,
				node->perms[0].id);
		} else {
			d = find_domain_by_domid(node->perms[0].id);
			if (d)
				d->nbentry++;
		}
	} else if (conn->domain) {
		if (conn->transaction) {
			transaction_entry_inc(conn->transaction,
				conn->domain->domid);
 		} else {
 			conn->domain->nbentry++;
		}
	}
}

void domain_entry_dec(struct connection *conn, struct node *node)
{
	struct domain *d;

	if (!conn)
		return;

	if (node->perms && node->perms[0].id != conn->id) {
		if (conn->transaction) {
			transaction_entry_dec(conn->transaction,
				node->perms[0].id);
		} else {
			d = find_domain_by_domid(node->perms[0].id);
			if (d && d->nbentry)
				d->nbentry--;
		}
	} else if (conn->domain && conn->domain->nbentry) {
		if (conn->transaction) {
			transaction_entry_dec(conn->transaction,
				conn->domain->domid);
		} else {
			conn->domain->nbentry--;
		}
	}
}

void domain_entry_fix(unsigned int domid, int num)
{
	struct domain *d;

	d = find_domain_by_domid(domid);
	if (d && ((d->nbentry += num) < 0))
		d->nbentry = 0;
}

int domain_entry(struct connection *conn)
{
	return (domain_is_unprivileged(conn))
		? conn->domain->nbentry
		: 0;
}

void domain_watch_inc(struct connection *conn)
{
	if (!conn || !conn->domain)
		return;
	conn->domain->nbwatch++;
}

void domain_watch_dec(struct connection *conn)
{
	if (!conn || !conn->domain)
		return;
	if (conn->domain->nbwatch)
		conn->domain->nbwatch--;
}

int domain_watch(struct connection *conn)
{
	return (domain_is_unprivileged(conn))
		? conn->domain->nbwatch
		: 0;
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

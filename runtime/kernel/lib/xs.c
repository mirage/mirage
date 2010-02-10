/*
 * libxs-compatible layer
 *
 * Samuel Thibault <Samuel.Thibault@eu.citrix.net>, 2007-2008
 *
 * Mere wrapper around xenbus_*
 */

#include <os.h>
#include <lib.h>
#include <xen/xenstore/xs.h>
#include <xen/io/xenbus.h>
#include <stdlib.h>
#include <unistd.h>

static inline int _xs_fileno(struct xs_handle *h) {
    return (intptr_t) h;
}

struct xs_handle *xs_daemon_open()
{
    int fd = alloc_fd(FTYPE_XENBUS);
    files[fd].xenbus.events = NULL;
    printk("xs_daemon_open -> %d, %p\n", fd, &files[fd].xenbus.events);
    return (void*)(intptr_t) fd;
}

void xs_daemon_close(struct xs_handle *h)
{
    int fd = _xs_fileno(h);
    struct xenbus_event *event;
    for (event = files[fd].xenbus.events; event; event = event->next)
        free(event);
    files[fd].type = FTYPE_NONE;
}

int xs_fileno(struct xs_handle *h)
{
    return _xs_fileno(h);
}

void *xs_read(struct xs_handle *h, xs_transaction_t t,
	     const char *path, unsigned int *len)
{
    char *value;
    char *msg;

    msg = xenbus_read(t, path, &value);
    if (msg) {
	printk("xs_read(%s): %s\n", path, msg);
	return NULL;
    }

    if (len)
	*len = strlen(value);
    return value;
}

bool xs_write(struct xs_handle *h, xs_transaction_t t,
	      const char *path, const void *data, unsigned int len)
{
    char value[len + 1];
    char *msg;

    memcpy(value, data, len);
    value[len] = 0;

    msg = xenbus_write(t, path, value);
    if (msg) {
	printk("xs_write(%s): %s\n", path, msg);
	return false;
    }
    return true;
}

static bool xs_bool(char *reply)
{
    if (!reply)
	return true;
    free(reply);
    return false;
}

bool xs_rm(struct xs_handle *h, xs_transaction_t t, const char *path)
{
    return xs_bool(xenbus_rm(t, path));
}

static void *xs_talkv(struct xs_handle *h, xs_transaction_t t,
		enum xsd_sockmsg_type type,
		struct write_req *iovec,
		unsigned int num_vecs,
		unsigned int *len)
{
    struct xsd_sockmsg *msg;
    void *ret;

    msg = xenbus_msg_reply(type, t, iovec, num_vecs);
    ret = malloc(msg->len);
    memcpy(ret, (char*) msg + sizeof(*msg), msg->len);
    if (len)
	*len = msg->len - 1;
    free(msg);
    return ret;
}

static void *xs_single(struct xs_handle *h, xs_transaction_t t,
		enum xsd_sockmsg_type type,
		const char *string,
		unsigned int *len)
{
    struct write_req iovec;

    iovec.data = (void *)string;
    iovec.len = strlen(string) + 1;

    return xs_talkv(h, t, type, &iovec, 1, len);
}

char *xs_get_domain_path(struct xs_handle *h, unsigned int domid)
{
    char domid_str[MAX_STRLEN(domid)];

    sprintf(domid_str, "%u", domid);

    return xs_single(h, XBT_NULL, XS_GET_DOMAIN_PATH, domid_str, NULL);
}

char **xs_directory(struct xs_handle *h, xs_transaction_t t,
		    const char *path, unsigned int *num)
{
    char *msg;
    char **entries, **res;
    char *entry;
    int i, n;
    int size;

    msg = xenbus_ls(t, path, &res);
    if (msg) {
	printk("xs_directory(%s): %s\n", path, msg);
	return NULL;
    }

    size = 0;
    for (n = 0; res[n]; n++)
	size += strlen(res[n]) + 1;

    entries = malloc(n * sizeof(char *) + size);
    entry = (char *) (&entries[n]);

    for (i = 0; i < n; i++) {
	int l = strlen(res[i]) + 1;
	memcpy(entry, res[i], l);
	free(res[i]);
	entries[i] = entry;
	entry += l;
    }

    *num = n;
    return entries;
}

bool xs_watch(struct xs_handle *h, const char *path, const char *token)
{
    int fd = _xs_fileno(h);
    printk("xs_watch(%s, %s)\n", path, token);
    return xs_bool(xenbus_watch_path_token(XBT_NULL, path, token, &files[fd].xenbus.events));
}

char **xs_read_watch(struct xs_handle *h, unsigned int *num)
{
    int fd = _xs_fileno(h);
    struct xenbus_event *event;
    event = files[fd].xenbus.events;
    files[fd].xenbus.events = event->next;
    printk("xs_read_watch() -> %s %s\n", event->path, event->token);
    *num = 2;
    return (char **) &event->path;
}

bool xs_unwatch(struct xs_handle *h, const char *path, const char *token)
{
    printk("xs_unwatch(%s, %s)\n", path, token);
    return xs_bool(xenbus_unwatch_path_token(XBT_NULL, path, token));
}

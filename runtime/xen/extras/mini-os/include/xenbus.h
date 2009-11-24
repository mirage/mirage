#ifndef XENBUS_H__
#define XENBUS_H__

#include <xen/io/xenbus.h>

typedef unsigned long xenbus_transaction_t;
#define XBT_NIL ((xenbus_transaction_t)0)

/* Initialize the XenBus system. */
void init_xenbus(void);

/* Read the value associated with a path.  Returns a malloc'd error
   string on failure and sets *value to NULL.  On success, *value is
   set to a malloc'd copy of the value. */
char *xenbus_read(xenbus_transaction_t xbt, const char *path, char **value);

/* Watch event queue */
struct xenbus_event {
    /* Keep these two as this for xs.c */
    char *path;
    char *token;
    struct xenbus_event *next;
};
typedef struct xenbus_event *xenbus_event_queue;

char *xenbus_watch_path_token(xenbus_transaction_t xbt, const char *path, const char *token, xenbus_event_queue *events);
char *xenbus_unwatch_path_token(xenbus_transaction_t xbt, const char *path, const char *token);
extern struct wait_queue_head xenbus_watch_queue;
void xenbus_wait_for_watch(xenbus_event_queue *queue);
char **xenbus_wait_for_watch_return(xenbus_event_queue *queue);
char* xenbus_wait_for_value(const char *path, const char *value, xenbus_event_queue *queue);
char *xenbus_wait_for_state_change(const char* path, XenbusState *state, xenbus_event_queue *queue);
char *xenbus_switch_state(xenbus_transaction_t xbt, const char* path, XenbusState state);

/* When no token is provided, use a global queue. */
#define XENBUS_WATCH_PATH_TOKEN "xenbus_watch_path"
extern xenbus_event_queue xenbus_events;
#define xenbus_watch_path(xbt, path) xenbus_watch_path_token(xbt, path, XENBUS_WATCH_PATH_TOKEN, NULL)
#define xenbus_unwatch_path(xbt, path) xenbus_unwatch_path_token(xbt, path, XENBUS_WATCH_PATH_TOKEN)


/* Associates a value with a path.  Returns a malloc'd error string on
   failure. */
char *xenbus_write(xenbus_transaction_t xbt, const char *path, const char *value);

struct write_req {
    const void *data;
    unsigned len;
};

/* Send a message to xenbus, in the same fashion as xb_write, and
   block waiting for a reply.  The reply is malloced and should be
   freed by the caller. */
struct xsd_sockmsg *
xenbus_msg_reply(int type,
                 xenbus_transaction_t trans,
                 struct write_req *io,
                 int nr_reqs);

/* Removes the value associated with a path.  Returns a malloc'd error
   string on failure. */
char *xenbus_rm(xenbus_transaction_t xbt, const char *path);

/* List the contents of a directory.  Returns a malloc'd error string
   on failure and sets *contents to NULL.  On success, *contents is
   set to a malloc'd array of pointers to malloc'd strings.  The array
   is NULL terminated.  May block. */
char *xenbus_ls(xenbus_transaction_t xbt, const char *prefix, char ***contents);

/* Reads permissions associated with a path.  Returns a malloc'd error
   string on failure and sets *value to NULL.  On success, *value is
   set to a malloc'd copy of the value. */
char *xenbus_get_perms(xenbus_transaction_t xbt, const char *path, char **value);

/* Sets the permissions associated with a path.  Returns a malloc'd
   error string on failure. */
char *xenbus_set_perms(xenbus_transaction_t xbt, const char *path, domid_t dom, char perm);

/* Start a xenbus transaction.  Returns the transaction in xbt on
   success or a malloc'd error string otherwise. */
char *xenbus_transaction_start(xenbus_transaction_t *xbt);

/* End a xenbus transaction.  Returns a malloc'd error string if it
   fails.  abort says whether the transaction should be aborted.
   Returns 1 in *retry iff the transaction should be retried. */
char *xenbus_transaction_end(xenbus_transaction_t, int abort,
			     int *retry);

/* Read path and parse it as an integer.  Returns -1 on error. */
int xenbus_read_integer(const char *path);

/* Contraction of snprintf and xenbus_write(path/node). */
char* xenbus_printf(xenbus_transaction_t xbt,
                                  const char* node, const char* path,
                                  const char* fmt, ...)
                   __attribute__((__format__(printf, 4, 5)));

/* Utility function to figure out our domain id */
domid_t xenbus_get_self_id(void);

/* Reset the XenBus system. */
void fini_xenbus(void);

#endif /* XENBUS_H__ */

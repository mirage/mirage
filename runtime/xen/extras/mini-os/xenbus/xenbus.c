/* 
 ****************************************************************************
 * (C) 2006 - Cambridge University
 ****************************************************************************
 *
 *        File: xenbus.c
 *      Author: Steven Smith (sos22@cam.ac.uk) 
 *     Changes: Grzegorz Milos (gm281@cam.ac.uk)
 *     Changes: John D. Ramsdell
 *              
 *        Date: Jun 2006, chages Aug 2005
 * 
 * Environment: Xen Minimal OS
 * Description: Minimal implementation of xenbus
 *
 ****************************************************************************
 **/
#include <mini-os/os.h>
#include <mini-os/mm.h>
#include <mini-os/traps.h>
#include <mini-os/lib.h>
#include <mini-os/xenbus.h>
#include <mini-os/events.h>
#include <mini-os/errno.h>
#include <mini-os/sched.h>
#include <mini-os/wait.h>
#include <xen/io/xs_wire.h>
#include <mini-os/spinlock.h>
#include <mini-os/xmalloc.h>

#define min(x,y) ({                       \
        typeof(x) tmpx = (x);                 \
        typeof(y) tmpy = (y);                 \
        tmpx < tmpy ? tmpx : tmpy;            \
        })

#ifdef XENBUS_DEBUG
#define DEBUG(_f, _a...) \
    printk("MINI_OS(file=xenbus.c, line=%d) " _f , __LINE__, ## _a)
#else
#define DEBUG(_f, _a...)    ((void)0)
#endif

static struct xenstore_domain_interface *xenstore_buf;
static DECLARE_WAIT_QUEUE_HEAD(xb_waitq);
DECLARE_WAIT_QUEUE_HEAD(xenbus_watch_queue);

xenbus_event_queue xenbus_events;
static struct watch {
    char *token;
    xenbus_event_queue *events;
    struct watch *next;
} *watches;
struct xenbus_req_info 
{
    int in_use:1;
    struct wait_queue_head waitq;
    void *reply;
};

#define NR_REQS 32
static struct xenbus_req_info req_info[NR_REQS];

static void memcpy_from_ring(const void *Ring,
        void *Dest,
        int off,
        int len)
{
    int c1, c2;
    const char *ring = Ring;
    char *dest = Dest;
    c1 = min(len, XENSTORE_RING_SIZE - off);
    c2 = len - c1;
    memcpy(dest, ring + off, c1);
    memcpy(dest + c1, ring, c2);
}

char **xenbus_wait_for_watch_return(xenbus_event_queue *queue)
{
    struct xenbus_event *event;
    DEFINE_WAIT(w);
    if (!queue)
        queue = &xenbus_events;
    while (!(event = *queue)) {
        add_waiter(w, xenbus_watch_queue);
        schedule();
    }
    remove_waiter(w);
    *queue = event->next;
    return &event->path;
}

void xenbus_wait_for_watch(xenbus_event_queue *queue)
{
    char **ret;
    if (!queue)
        queue = &xenbus_events;
    ret = xenbus_wait_for_watch_return(queue);
    if (ret)
        free(ret);
    else
        printk("unexpected path returned by watch\n");
}

char* xenbus_wait_for_value(const char* path, const char* value, xenbus_event_queue *queue)
{
    if (!queue)
        queue = &xenbus_events;
    for(;;)
    {
        char *res, *msg;
        int r;

        msg = xenbus_read(XBT_NIL, path, &res);
        if(msg) return msg;

        r = strcmp(value,res);
        free(res);

        if(r==0) break;
        else xenbus_wait_for_watch(queue);
    }
    return NULL;
}

char *xenbus_switch_state(xenbus_transaction_t xbt, const char* path, XenbusState state)
{
    char *current_state;
    char *msg = NULL;
    char *msg2 = NULL;
    char value[2];
    XenbusState rs;
    int xbt_flag = 0;
    int retry = 0;

    do {
        if (xbt == XBT_NIL) {
            xenbus_transaction_start(&xbt);
            xbt_flag = 1;
        }

        msg = xenbus_read(xbt, path, &current_state);
        if (msg) goto exit;

        rs = (XenbusState) (current_state[0] - '0');
        free(current_state);
        if (rs == state) {
            msg = NULL;
            goto exit;
        }

        snprintf(value, 2, "%d", state);
        msg = xenbus_write(xbt, path, value);

exit:
        if (xbt_flag)
            msg2 = xenbus_transaction_end(xbt, 0, &retry);
        if (msg == NULL && msg2 != NULL)
            msg = msg2;
    } while (retry);

    return msg;
}

char *xenbus_wait_for_state_change(const char* path, XenbusState *state, xenbus_event_queue *queue)
{
    if (!queue)
        queue = &xenbus_events;
    for(;;)
    {
        char *res, *msg;
        XenbusState rs;

        msg = xenbus_read(XBT_NIL, path, &res);
        if(msg) return msg;

        rs = (XenbusState) (res[0] - 48);
        free(res);

        if (rs == *state)
            xenbus_wait_for_watch(queue);
        else {
            *state = rs;
            break;
        }
    }
    return NULL;
}


static void xenbus_thread_func(void *ign)
{
    struct xsd_sockmsg msg;
    unsigned prod = xenstore_buf->rsp_prod;

    for (;;) 
    {
        wait_event(xb_waitq, prod != xenstore_buf->rsp_prod);
        while (1) 
        {
            prod = xenstore_buf->rsp_prod;
            DEBUG("Rsp_cons %d, rsp_prod %d.\n", xenstore_buf->rsp_cons,
                    xenstore_buf->rsp_prod);
            if (xenstore_buf->rsp_prod - xenstore_buf->rsp_cons < sizeof(msg))
                break;
            rmb();
            memcpy_from_ring(xenstore_buf->rsp,
                    &msg,
                    MASK_XENSTORE_IDX(xenstore_buf->rsp_cons),
                    sizeof(msg));
            DEBUG("Msg len %d, %d avail, id %d.\n",
                    msg.len + sizeof(msg),
                    xenstore_buf->rsp_prod - xenstore_buf->rsp_cons,
                    msg.req_id);
            if (xenstore_buf->rsp_prod - xenstore_buf->rsp_cons <
                    sizeof(msg) + msg.len)
                break;

            DEBUG("Message is good.\n");

            if(msg.type == XS_WATCH_EVENT)
            {
		struct xenbus_event *event = malloc(sizeof(*event) + msg.len);
                xenbus_event_queue *events = NULL;
		char *data = (char*)event + sizeof(*event);
                struct watch *watch;

                memcpy_from_ring(xenstore_buf->rsp,
		    data,
                    MASK_XENSTORE_IDX(xenstore_buf->rsp_cons + sizeof(msg)),
                    msg.len);

		event->path = data;
		event->token = event->path + strlen(event->path) + 1;

                xenstore_buf->rsp_cons += msg.len + sizeof(msg);

                for (watch = watches; watch; watch = watch->next)
                    if (!strcmp(watch->token, event->token)) {
                        events = watch->events;
                        break;
                    }

                if (events) {
                    event->next = *events;
                    *events = event;
                    wake_up(&xenbus_watch_queue);
                } else {
                    printk("unexpected watch token %s\n", event->token);
                    free(event);
                }
            }

            else
            {
                req_info[msg.req_id].reply = malloc(sizeof(msg) + msg.len);
                memcpy_from_ring(xenstore_buf->rsp,
                    req_info[msg.req_id].reply,
                    MASK_XENSTORE_IDX(xenstore_buf->rsp_cons),
                    msg.len + sizeof(msg));
                xenstore_buf->rsp_cons += msg.len + sizeof(msg);
                wake_up(&req_info[msg.req_id].waitq);
            }
        }
    }
}

static void xenbus_evtchn_handler(evtchn_port_t port, struct pt_regs *regs,
				  void *ign)
{
    wake_up(&xb_waitq);
}

static int nr_live_reqs;
static spinlock_t req_lock = SPIN_LOCK_UNLOCKED;
static DECLARE_WAIT_QUEUE_HEAD(req_wq);

/* Release a xenbus identifier */
static void release_xenbus_id(int id)
{
    BUG_ON(!req_info[id].in_use);
    spin_lock(&req_lock);
    req_info[id].in_use = 0;
    nr_live_reqs--;
    req_info[id].in_use = 0;
    if (nr_live_reqs == NR_REQS - 1)
        wake_up(&req_wq);
    spin_unlock(&req_lock);
}

/* Allocate an identifier for a xenbus request.  Blocks if none are
   available. */
static int allocate_xenbus_id(void)
{
    static int probe;
    int o_probe;

    while (1) 
    {
        spin_lock(&req_lock);
        if (nr_live_reqs < NR_REQS)
            break;
        spin_unlock(&req_lock);
        wait_event(req_wq, (nr_live_reqs < NR_REQS));
    }

    o_probe = probe;
    for (;;) 
    {
        if (!req_info[o_probe].in_use)
            break;
        o_probe = (o_probe + 1) % NR_REQS;
        BUG_ON(o_probe == probe);
    }
    nr_live_reqs++;
    req_info[o_probe].in_use = 1;
    probe = (o_probe + 1) % NR_REQS;
    spin_unlock(&req_lock);
    init_waitqueue_head(&req_info[o_probe].waitq);

    return o_probe;
}

/* Initialise xenbus. */
void init_xenbus(void)
{
    int err;
    printk("Initialising xenbus\n");
    DEBUG("init_xenbus called.\n");
    xenstore_buf = mfn_to_virt(start_info.store_mfn);
    create_thread("xenstore", xenbus_thread_func, NULL);
    DEBUG("buf at %p.\n", xenstore_buf);
    err = bind_evtchn(start_info.store_evtchn,
		      xenbus_evtchn_handler,
              NULL);
    unmask_evtchn(start_info.store_evtchn);
    DEBUG("xenbus on irq %d\n", err);
}

void fini_xenbus(void)
{
}

/* Send data to xenbus.  This can block.  All of the requests are seen
   by xenbus as if sent atomically.  The header is added
   automatically, using type %type, req_id %req_id, and trans_id
   %trans_id. */
static void xb_write(int type, int req_id, xenbus_transaction_t trans_id,
		     const struct write_req *req, int nr_reqs)
{
    XENSTORE_RING_IDX prod;
    int r;
    int len = 0;
    const struct write_req *cur_req;
    int req_off;
    int total_off;
    int this_chunk;
    struct xsd_sockmsg m = {.type = type, .req_id = req_id,
        .tx_id = trans_id };
    struct write_req header_req = { &m, sizeof(m) };

    for (r = 0; r < nr_reqs; r++)
        len += req[r].len;
    m.len = len;
    len += sizeof(m);

    cur_req = &header_req;

    BUG_ON(len > XENSTORE_RING_SIZE);
    /* Wait for the ring to drain to the point where we can send the
       message. */
    prod = xenstore_buf->req_prod;
    if (prod + len - xenstore_buf->req_cons > XENSTORE_RING_SIZE) 
    {
        /* Wait for there to be space on the ring */
        DEBUG("prod %d, len %d, cons %d, size %d; waiting.\n",
                prod, len, xenstore_buf->req_cons, XENSTORE_RING_SIZE);
        wait_event(xb_waitq,
                xenstore_buf->req_prod + len - xenstore_buf->req_cons <=
                XENSTORE_RING_SIZE);
        DEBUG("Back from wait.\n");
        prod = xenstore_buf->req_prod;
    }

    /* We're now guaranteed to be able to send the message without
       overflowing the ring.  Do so. */
    total_off = 0;
    req_off = 0;
    while (total_off < len) 
    {
        this_chunk = min(cur_req->len - req_off,
                XENSTORE_RING_SIZE - MASK_XENSTORE_IDX(prod));
        memcpy((char *)xenstore_buf->req + MASK_XENSTORE_IDX(prod),
                (char *)cur_req->data + req_off, this_chunk);
        prod += this_chunk;
        req_off += this_chunk;
        total_off += this_chunk;
        if (req_off == cur_req->len) 
        {
            req_off = 0;
            if (cur_req == &header_req)
                cur_req = req;
            else
                cur_req++;
        }
    }

    DEBUG("Complete main loop of xb_write.\n");
    BUG_ON(req_off != 0);
    BUG_ON(total_off != len);
    BUG_ON(prod > xenstore_buf->req_cons + XENSTORE_RING_SIZE);

    /* Remote must see entire message before updating indexes */
    wmb();

    xenstore_buf->req_prod += len;

    /* Send evtchn to notify remote */
    notify_remote_via_evtchn(start_info.store_evtchn);
}

/* Send a mesasge to xenbus, in the same fashion as xb_write, and
   block waiting for a reply.  The reply is malloced and should be
   freed by the caller. */
struct xsd_sockmsg *
xenbus_msg_reply(int type,
		 xenbus_transaction_t trans,
		 struct write_req *io,
		 int nr_reqs)
{
    int id;
    DEFINE_WAIT(w);
    struct xsd_sockmsg *rep;

    id = allocate_xenbus_id();
    add_waiter(w, req_info[id].waitq);

    xb_write(type, id, trans, io, nr_reqs);

    schedule();
    remove_waiter(w);
    wake(current);

    rep = req_info[id].reply;
    BUG_ON(rep->req_id != id);
    release_xenbus_id(id);
    return rep;
}

static char *errmsg(struct xsd_sockmsg *rep)
{
    char *res;
    if (!rep) {
	char msg[] = "No reply";
	size_t len = strlen(msg) + 1;
	return memcpy(malloc(len), msg, len);
    }
    if (rep->type != XS_ERROR)
	return NULL;
    res = malloc(rep->len + 1);
    memcpy(res, rep + 1, rep->len);
    res[rep->len] = 0;
    free(rep);
    return res;
}	

/* Send a debug message to xenbus.  Can block. */
static void xenbus_debug_msg(const char *msg)
{
    int len = strlen(msg);
    struct write_req req[] = {
        { "print", sizeof("print") },
        { msg, len },
        { "", 1 }};
    struct xsd_sockmsg *reply;

    reply = xenbus_msg_reply(XS_DEBUG, 0, req, ARRAY_SIZE(req));
    DEBUG("Got a reply, type %d, id %d, len %d.\n",
            reply->type, reply->req_id, reply->len);
}

/* List the contents of a directory.  Returns a malloc()ed array of
   pointers to malloc()ed strings.  The array is NULL terminated.  May
   block. */
char *xenbus_ls(xenbus_transaction_t xbt, const char *pre, char ***contents)
{
    struct xsd_sockmsg *reply, *repmsg;
    struct write_req req[] = { { pre, strlen(pre)+1 } };
    int nr_elems, x, i;
    char **res, *msg;

    repmsg = xenbus_msg_reply(XS_DIRECTORY, xbt, req, ARRAY_SIZE(req));
    msg = errmsg(repmsg);
    if (msg) {
	*contents = NULL;
	return msg;
    }
    reply = repmsg + 1;
    for (x = nr_elems = 0; x < repmsg->len; x++)
        nr_elems += (((char *)reply)[x] == 0);
    res = malloc(sizeof(res[0]) * (nr_elems + 1));
    for (x = i = 0; i < nr_elems; i++) {
        int l = strlen((char *)reply + x);
        res[i] = malloc(l + 1);
        memcpy(res[i], (char *)reply + x, l + 1);
        x += l + 1;
    }
    res[i] = NULL;
    free(repmsg);
    *contents = res;
    return NULL;
}

char *xenbus_read(xenbus_transaction_t xbt, const char *path, char **value)
{
    struct write_req req[] = { {path, strlen(path) + 1} };
    struct xsd_sockmsg *rep;
    char *res, *msg;
    rep = xenbus_msg_reply(XS_READ, xbt, req, ARRAY_SIZE(req));
    msg = errmsg(rep);
    if (msg) {
	*value = NULL;
	return msg;
    }
    res = malloc(rep->len + 1);
    memcpy(res, rep + 1, rep->len);
    res[rep->len] = 0;
    free(rep);
    *value = res;
    return NULL;
}

char *xenbus_write(xenbus_transaction_t xbt, const char *path, const char *value)
{
    struct write_req req[] = { 
	{path, strlen(path) + 1},
	{value, strlen(value)},
    };
    struct xsd_sockmsg *rep;
    char *msg;
    rep = xenbus_msg_reply(XS_WRITE, xbt, req, ARRAY_SIZE(req));
    msg = errmsg(rep);
    if (msg) return msg;
    free(rep);
    return NULL;
}

char* xenbus_watch_path_token( xenbus_transaction_t xbt, const char *path, const char *token, xenbus_event_queue *events)
{
    struct xsd_sockmsg *rep;

    struct write_req req[] = { 
        {path, strlen(path) + 1},
	{token, strlen(token) + 1},
    };

    struct watch *watch = malloc(sizeof(*watch));

    char *msg;

    if (!events)
        events = &xenbus_events;

    watch->token = strdup(token);
    watch->events = events;
    watch->next = watches;
    watches = watch;

    rep = xenbus_msg_reply(XS_WATCH, xbt, req, ARRAY_SIZE(req));

    msg = errmsg(rep);
    if (msg) return msg;
    free(rep);

    return NULL;
}

char* xenbus_unwatch_path_token( xenbus_transaction_t xbt, const char *path, const char *token)
{
    struct xsd_sockmsg *rep;

    struct write_req req[] = { 
        {path, strlen(path) + 1},
	{token, strlen(token) + 1},
    };

    struct watch *watch, **prev;

    char *msg;

    rep = xenbus_msg_reply(XS_UNWATCH, xbt, req, ARRAY_SIZE(req));

    msg = errmsg(rep);
    if (msg) return msg;
    free(rep);

    for (prev = &watches, watch = *prev; watch; prev = &watch->next, watch = *prev)
        if (!strcmp(watch->token, token)) {
            free(watch->token);
            *prev = watch->next;
            free(watch);
            break;
        }

    return NULL;
}

char *xenbus_rm(xenbus_transaction_t xbt, const char *path)
{
    struct write_req req[] = { {path, strlen(path) + 1} };
    struct xsd_sockmsg *rep;
    char *msg;
    rep = xenbus_msg_reply(XS_RM, xbt, req, ARRAY_SIZE(req));
    msg = errmsg(rep);
    if (msg)
	return msg;
    free(rep);
    return NULL;
}

char *xenbus_get_perms(xenbus_transaction_t xbt, const char *path, char **value)
{
    struct write_req req[] = { {path, strlen(path) + 1} };
    struct xsd_sockmsg *rep;
    char *res, *msg;
    rep = xenbus_msg_reply(XS_GET_PERMS, xbt, req, ARRAY_SIZE(req));
    msg = errmsg(rep);
    if (msg) {
	*value = NULL;
	return msg;
    }
    res = malloc(rep->len + 1);
    memcpy(res, rep + 1, rep->len);
    res[rep->len] = 0;
    free(rep);
    *value = res;
    return NULL;
}

#define PERM_MAX_SIZE 32
char *xenbus_set_perms(xenbus_transaction_t xbt, const char *path, domid_t dom, char perm)
{
    char value[PERM_MAX_SIZE];
    struct write_req req[] = { 
	{path, strlen(path) + 1},
	{value, 0},
    };
    struct xsd_sockmsg *rep;
    char *msg;
    snprintf(value, PERM_MAX_SIZE, "%c%hu", perm, dom);
    req[1].len = strlen(value) + 1;
    rep = xenbus_msg_reply(XS_SET_PERMS, xbt, req, ARRAY_SIZE(req));
    msg = errmsg(rep);
    if (msg)
	return msg;
    free(rep);
    return NULL;
}

char *xenbus_transaction_start(xenbus_transaction_t *xbt)
{
    /* xenstored becomes angry if you send a length 0 message, so just
       shove a nul terminator on the end */
    struct write_req req = { "", 1};
    struct xsd_sockmsg *rep;
    char *err;

    rep = xenbus_msg_reply(XS_TRANSACTION_START, 0, &req, 1);
    err = errmsg(rep);
    if (err)
	return err;
    sscanf((char *)(rep + 1), "%u", xbt);
    free(rep);
    return NULL;
}

char *
xenbus_transaction_end(xenbus_transaction_t t, int abort, int *retry)
{
    struct xsd_sockmsg *rep;
    struct write_req req;
    char *err;

    *retry = 0;

    req.data = abort ? "F" : "T";
    req.len = 2;
    rep = xenbus_msg_reply(XS_TRANSACTION_END, t, &req, 1);
    err = errmsg(rep);
    if (err) {
	if (!strcmp(err, "EAGAIN")) {
	    *retry = 1;
	    free(err);
	    return NULL;
	} else {
	    return err;
	}
    }
    free(rep);
    return NULL;
}

int xenbus_read_integer(const char *path)
{
    char *res, *buf;
    int t;

    res = xenbus_read(XBT_NIL, path, &buf);
    if (res) {
	printk("Failed to read %s.\n", path);
	free(res);
	return -1;
    }
    sscanf(buf, "%d", &t);
    free(buf);
    return t;
}

char* xenbus_printf(xenbus_transaction_t xbt,
                                  const char* node, const char* path,
                                  const char* fmt, ...)
{
#define BUFFER_SIZE 256
    char fullpath[BUFFER_SIZE];
    char val[BUFFER_SIZE];
    va_list args;

    BUG_ON(strlen(node) + strlen(path) + 1 >= BUFFER_SIZE);
    sprintf(fullpath,"%s/%s", node, path);
    va_start(args, fmt);
    vsprintf(val, fmt, args);
    va_end(args);
    return xenbus_write(xbt,fullpath,val);
}

domid_t xenbus_get_self_id(void)
{
    char *dom_id;
    domid_t ret;

    BUG_ON(xenbus_read(XBT_NIL, "domid", &dom_id));
    sscanf(dom_id, "%d", &ret);

    return ret;
}

static void do_ls_test(const char *pre)
{
    char **dirs, *msg;
    int x;

    DEBUG("ls %s...\n", pre);
    msg = xenbus_ls(XBT_NIL, pre, &dirs);
    if (msg) {
	DEBUG("Error in xenbus ls: %s\n", msg);
	free(msg);
	return;
    }
    for (x = 0; dirs[x]; x++) 
    {
        DEBUG("ls %s[%d] -> %s\n", pre, x, dirs[x]);
        free(dirs[x]);
    }
    free(dirs);
}

static void do_read_test(const char *path)
{
    char *res, *msg;
    DEBUG("Read %s...\n", path);
    msg = xenbus_read(XBT_NIL, path, &res);
    if (msg) {
	DEBUG("Error in xenbus read: %s\n", msg);
	free(msg);
	return;
    }
    DEBUG("Read %s -> %s.\n", path, res);
    free(res);
}

static void do_write_test(const char *path, const char *val)
{
    char *msg;
    DEBUG("Write %s to %s...\n", val, path);
    msg = xenbus_write(XBT_NIL, path, val);
    if (msg) {
	DEBUG("Result %s\n", msg);
	free(msg);
    } else {
	DEBUG("Success.\n");
    }
}

static void do_rm_test(const char *path)
{
    char *msg;
    DEBUG("rm %s...\n", path);
    msg = xenbus_rm(XBT_NIL, path);
    if (msg) {
	DEBUG("Result %s\n", msg);
	free(msg);
    } else {
	DEBUG("Success.\n");
    }
}

/* Simple testing thing */
void test_xenbus(void)
{
    DEBUG("Doing xenbus test.\n");
    xenbus_debug_msg("Testing xenbus...\n");

    DEBUG("Doing ls test.\n");
    do_ls_test("device");
    do_ls_test("device/vif");
    do_ls_test("device/vif/0");

    DEBUG("Doing read test.\n");
    do_read_test("device/vif/0/mac");
    do_read_test("device/vif/0/backend");

    DEBUG("Doing write test.\n");
    do_write_test("device/vif/0/flibble", "flobble");
    do_read_test("device/vif/0/flibble");
    do_write_test("device/vif/0/flibble", "widget");
    do_read_test("device/vif/0/flibble");

    DEBUG("Doing rm test.\n");
    do_rm_test("device/vif/0/flibble");
    do_read_test("device/vif/0/flibble");
    DEBUG("(Should have said ENOENT)\n");
}

/*
 * Local variables:
 * mode: C
 * c-basic-offset: 4
 * End:
 */

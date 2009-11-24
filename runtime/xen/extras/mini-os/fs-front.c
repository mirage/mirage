/******************************************************************************
 * fs-front.c
 * 
 * Frontend driver for FS split device driver.
 *
 * Copyright (c) 2007, Grzegorz Milos, <gm281@cam.ac.uk>.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 * DEALINGS IN THE SOFTWARE.
 */

#undef NDEBUG
#include <stdint.h>
#include <mini-os/os.h>
#include <mini-os/list.h>
#include <mini-os/xmalloc.h>
#include <mini-os/xenbus.h>
#include <mini-os/gnttab.h>
#include <mini-os/events.h>
#include <xen/io/fsif.h>
#include <mini-os/fs.h>
#include <mini-os/sched.h>

#define preempt_disable()
#define preempt_enable()
#define cmpxchg(p,o,n) synch_cmpxchg(p,o,n)


#ifdef FS_DEBUG
#define DEBUG(_f, _a...) \
    printk("MINI_OS(file=fs-front.c, line=%d) " _f "\n", __LINE__, ## _a)
#else
#define DEBUG(_f, _a...)    ((void)0)
#endif


struct fs_request;
struct fs_import *fs_import;
void *alloc_buffer_page(struct fs_request *req, domid_t domid, grant_ref_t *gref);
void free_buffer_page(struct fs_request *req);

/******************************************************************************/
/*                      RING REQUEST/RESPONSES HANDLING                       */
/******************************************************************************/

struct fs_request
{
    void *private1;                        /* Specific to request type */
    void *private2;
    struct thread *thread;                 /* Thread blocked on this request */
    struct fsif_response shadow_rsp;       /* Response copy writen by the 
                                              interrupt handler */  
};

struct fs_rw_gnts
{
    /* TODO 16 bit? */
    int count;
    grant_ref_t grefs[FSIF_NR_READ_GNTS];  
    void *pages[FSIF_NR_READ_GNTS];  
};

/* Ring operations:
 * FSIF ring is used differently to Linux-like split devices. This stems from 
 * the fact that no I/O request queue is present. The use of some of the macros
 * defined in ring.h is not allowed, in particular:
 * RING_PUSH_REQUESTS_AND_CHECK_NOTIFY cannot be used.
 *
 * The protocol used for FSIF ring is described below:
 *
 * In order to reserve a request the frontend:
 * a) saves current frontend_ring->req_prod_pvt into a local variable
 * b) checks that there are free request using the local req_prod_pvt
 * c) tries to reserve the request using cmpxchg on frontend_ring->req_prod_pvt
 *    if cmpxchg fails, it means that someone reserved the request, start from
 *    a)
 * 
 * In order to commit a request to the shared ring:
 * a) cmpxchg shared_ring->req_prod from local req_prod_pvt to req_prod_pvt+1 
 *    Loop if unsuccessful.
 * NOTE: Request should be commited to the shared ring as quickly as possible,
 *       because otherwise other threads might busy loop trying to commit next
 *       requests. It also follows that preemption should be disabled, if
 *       possible, for the duration of the request construction.
 */

/* Number of free requests (for use on front side only). */
#define FS_RING_FREE_REQUESTS(_r, _req_prod_pvt)                         \
    (RING_SIZE(_r) - (_req_prod_pvt - (_r)->rsp_cons))



static RING_IDX reserve_fsif_request(struct fs_import *import)
{
    RING_IDX idx; 

    down(&import->reqs_sem);
    preempt_disable();
again:    
    /* We will attempt to reserve slot idx */
    idx = import->ring.req_prod_pvt;
    ASSERT (FS_RING_FREE_REQUESTS(&import->ring, idx));
    /* Attempt to reserve */
    if(cmpxchg(&import->ring.req_prod_pvt, idx, idx+1) != idx)
        goto again;

    return idx; 
}

static void commit_fsif_request(struct fs_import *import, RING_IDX idx)
{
    while(cmpxchg(&import->ring.sring->req_prod, idx, idx+1) != idx)
    {
        printk("Failed to commit a request: req_prod=%d, idx=%d\n",
                import->ring.sring->req_prod, idx);
    }
    preempt_enable();

    /* NOTE: we cannot do anything clever about rsp_event, to hold off
     * notifications, because we don't know if we are a single request (in which
     * case we have to notify always), or a part of a larger request group
     * (when, in some cases, notification isn't required) */
    notify_remote_via_evtchn(import->local_port);
}



static inline void add_id_to_freelist(unsigned int id,unsigned short* freelist)
{
    unsigned int old_id, new_id;

again:    
    old_id = freelist[0];
    /* Note: temporal inconsistency, since freelist[0] can be changed by someone
     * else, but we are a sole owner of freelist[id + 1], it's OK. */
    freelist[id + 1] = old_id;
    new_id = id;
    if(cmpxchg(&freelist[0], old_id, new_id) != old_id)
    {
        printk("Cmpxchg on freelist add failed.\n");
        goto again;
    }
}

/* always call reserve_fsif_request(import) before this, to protect from
 * depletion. */
static inline unsigned short get_id_from_freelist(unsigned short* freelist)
{
    unsigned int old_id, new_id;

again:    
    old_id = freelist[0];
    new_id = freelist[old_id + 1];
    if(cmpxchg(&freelist[0], old_id, new_id) != old_id)
    {
        printk("Cmpxchg on freelist remove failed.\n");
        goto again;
    }
    
    return old_id;
}

/******************************************************************************/
/*                  END OF RING REQUEST/RESPONSES HANDLING                    */
/******************************************************************************/



/******************************************************************************/
/*                         INDIVIDUAL FILE OPERATIONS                         */
/******************************************************************************/
int fs_open(struct fs_import *import, char *file)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    grant_ref_t gref;
    void *buffer;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    int fd;

    if (!import)
        return -1;

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_open call is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];
    buffer = alloc_buffer_page(fsr, import->dom_id, &gref);
    DEBUG("gref id=%d\n", gref);
    fsr->thread = current;
    sprintf(buffer, "%s", file);

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_FILE_OPEN;
    req->id = priv_req_id;
    req->u.fopen.gref = gref;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    fd = (int)fsr->shadow_rsp.u.ret_val;
    DEBUG("The following FD returned: %d\n", fd);
    free_buffer_page(fsr);
    add_id_to_freelist(priv_req_id, import->freelist);

    return fd;
} 

int fs_close(struct fs_import *import, int fd)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    int ret;

    if (!import)
        return -1;

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_close call is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];
    fsr->thread = current;

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_FILE_CLOSE;
    req->id = priv_req_id;
    req->u.fclose.fd = fd;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    ret = (int)fsr->shadow_rsp.u.ret_val;
    DEBUG("Close returned: %d\n", ret);
    add_id_to_freelist(priv_req_id, import->freelist);

    return ret;
}

ssize_t fs_read(struct fs_import *import, int fd, void *buf, 
                ssize_t len, ssize_t offset)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    struct fs_rw_gnts gnts;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    ssize_t ret;
    int i;

    if (!import)
        return -1;

    BUG_ON(len > PAGE_SIZE * FSIF_NR_READ_GNTS);

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_read call is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_FILE_READ;
    req->id = priv_req_id;
    req->u.fread.fd = fd;
    req->u.fread.len = len;
    req->u.fread.offset = offset;


    ASSERT(len > 0);
    gnts.count = ((len - 1) / PAGE_SIZE) + 1; 
    for(i=0; i<gnts.count; i++)
    {
        gnts.pages[i] = (void *)alloc_page(); 
        gnts.grefs[i] = gnttab_grant_access(import->dom_id, 
                                            virt_to_mfn(gnts.pages[i]), 
                                            0); 
        memset(gnts.pages[i], 0, PAGE_SIZE);
        req->u.fread.grefs[i] = gnts.grefs[i];
    }
    fsr->thread = current;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    ret = (ssize_t)fsr->shadow_rsp.u.ret_val;
    DEBUG("The following ret value returned %d\n", ret);
    if(ret > 0)
    {
        ssize_t to_copy = ret, current_copy;
        for(i=0; i<gnts.count; i++)
        {
            gnttab_end_access(gnts.grefs[i]);
            current_copy = to_copy > PAGE_SIZE ? PAGE_SIZE : to_copy;
            if(current_copy > 0)
                memcpy(buf, gnts.pages[i], current_copy); 
            to_copy -= current_copy; 
            buf = (char*) buf + current_copy;
            free_page(gnts.pages[i]);
        }
    }
    add_id_to_freelist(priv_req_id, import->freelist);

    return ret;
} 

ssize_t fs_write(struct fs_import *import, int fd, void *buf, 
                 ssize_t len, ssize_t offset)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    struct fs_rw_gnts gnts;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    ssize_t ret, to_copy;
    int i;

    if (!import)
        return -1;

    BUG_ON(len > PAGE_SIZE * FSIF_NR_WRITE_GNTS);

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_read call is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_FILE_WRITE;
    req->id = priv_req_id;
    req->u.fwrite.fd = fd;
    req->u.fwrite.len = len;
    req->u.fwrite.offset = offset;

    ASSERT(len > 0);
    gnts.count = ((len - 1) / PAGE_SIZE) + 1; 
    to_copy = len;
    for(i=0; i<gnts.count; i++)
    {
        int current_copy = (to_copy > PAGE_SIZE ? PAGE_SIZE : to_copy);
        gnts.pages[i] = (void *)alloc_page(); 
        gnts.grefs[i] = gnttab_grant_access(import->dom_id, 
                                            virt_to_mfn(gnts.pages[i]), 
                                            0); 
        memcpy(gnts.pages[i], buf, current_copy);
        if(current_copy < PAGE_SIZE)
            memset((char *)gnts.pages[i] + current_copy, 
                    0, 
                    PAGE_SIZE - current_copy); 
        req->u.fwrite.grefs[i] = gnts.grefs[i];
        to_copy -= current_copy; 
        buf = (char*) buf + current_copy;
    }
    fsr->thread = current;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    ret = (ssize_t)fsr->shadow_rsp.u.ret_val;
    DEBUG("The following ret value returned %d\n", ret);
    for(i=0; i<gnts.count; i++)
    {
        gnttab_end_access(gnts.grefs[i]);
        free_page(gnts.pages[i]);
    }
    add_id_to_freelist(priv_req_id, import->freelist);

    return ret;
} 

int fs_stat(struct fs_import *import, 
            int fd, 
            struct fsif_stat_response *stat)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    int ret;

    if (!import)
        return -1;

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_stat call is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];
    fsr->thread = current;

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_STAT;
    req->id = priv_req_id;
    req->u.fstat.fd   = fd;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    ret = (int)fsr->shadow_rsp.u.ret_val;
    DEBUG("Following ret from fstat: %d\n", ret);
    memcpy(stat, 
           &fsr->shadow_rsp.u.fstat, 
           sizeof(struct fsif_stat_response));
    add_id_to_freelist(priv_req_id, import->freelist);

    return ret;
} 

int fs_truncate(struct fs_import *import, 
                int fd, 
                int64_t length)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    int ret;

    if (!import)
        return -1;

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_truncate call is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];
    fsr->thread = current;

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_FILE_TRUNCATE;
    req->id = priv_req_id;
    req->u.ftruncate.fd = fd;
    req->u.ftruncate.length = length;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    ret = (int)fsr->shadow_rsp.u.ret_val;
    DEBUG("Following ret from ftruncate: %d\n", ret);
    add_id_to_freelist(priv_req_id, import->freelist);

    return ret;
} 

int fs_remove(struct fs_import *import, char *file)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    grant_ref_t gref;
    void *buffer;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    int ret;

    if (!import)
        return -1;

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_open call is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];
    buffer = alloc_buffer_page(fsr, import->dom_id, &gref);
    DEBUG("gref=%d\n", gref);
    fsr->thread = current;
    sprintf(buffer, "%s", file);

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_REMOVE;
    req->id = priv_req_id;
    req->u.fremove.gref = gref;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    ret = (int)fsr->shadow_rsp.u.ret_val;
    DEBUG("The following ret: %d\n", ret);
    free_buffer_page(fsr);
    add_id_to_freelist(priv_req_id, import->freelist);

    return ret;
}


int fs_rename(struct fs_import *import, 
              char *old_file_name, 
              char *new_file_name)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    grant_ref_t gref;
    void *buffer;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    int ret;
    char old_header[] = "old: ";
    char new_header[] = "new: ";

    if (!import)
        return -1;

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_open call is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];
    buffer = alloc_buffer_page(fsr, import->dom_id, &gref);
    DEBUG("gref=%d\n", gref);
    fsr->thread = current;
    sprintf(buffer, "%s%s%c%s%s", 
            old_header, old_file_name, '\0', new_header, new_file_name);

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_RENAME;
    req->id = priv_req_id;
    req->u.frename.gref = gref;
    req->u.frename.old_name_offset = strlen(old_header);
    req->u.frename.new_name_offset = strlen(old_header) +
                                     strlen(old_file_name) +
                                     strlen(new_header) +
                                     1 /* Accouning for the additional 
                                          end of string character */;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    ret = (int)fsr->shadow_rsp.u.ret_val;
    DEBUG("The following ret: %d\n", ret);
    free_buffer_page(fsr);
    add_id_to_freelist(priv_req_id, import->freelist);

    return ret;
}

int fs_create(struct fs_import *import, char *name, 
              int8_t directory, int32_t mode)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    grant_ref_t gref;
    void *buffer;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    int ret;

    if (!import)
        return -1;

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_create call is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];
    buffer = alloc_buffer_page(fsr, import->dom_id, &gref);
    DEBUG("gref=%d\n", gref);
    fsr->thread = current;
    sprintf(buffer, "%s", name);

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_CREATE;
    req->id = priv_req_id;
    req->u.fcreate.gref = gref;
    req->u.fcreate.directory = directory;
    req->u.fcreate.mode = mode;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    ret = (int)fsr->shadow_rsp.u.ret_val;
    DEBUG("The following ret: %d\n", ret);
    free_buffer_page(fsr);
    add_id_to_freelist(priv_req_id, import->freelist);

    return ret;
} 

char** fs_list(struct fs_import *import, char *name, 
               int32_t offset, int32_t *nr_files, int *has_more)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    grant_ref_t gref;
    void *buffer;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    char **files, *current_file;
    int i;

    if (!import)
        return NULL;

    DEBUG("Different masks: NR_FILES=(%llx, %d), ERROR=(%llx, %d), HAS_MORE(%llx, %d)\n",
            NR_FILES_MASK, NR_FILES_SHIFT, ERROR_MASK, ERROR_SHIFT, HAS_MORE_FLAG, HAS_MORE_SHIFT);

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_list call is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];
    buffer = alloc_buffer_page(fsr, import->dom_id, &gref);
    DEBUG("gref=%d\n", gref);
    fsr->thread = current;
    sprintf(buffer, "%s", name);

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_DIR_LIST;
    req->id = priv_req_id;
    req->u.flist.gref = gref;
    req->u.flist.offset = offset;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    *nr_files = (fsr->shadow_rsp.u.ret_val & NR_FILES_MASK) >> NR_FILES_SHIFT;
    files = NULL;
    if(*nr_files <= 0) goto exit;
    files = malloc(sizeof(char*) * (*nr_files));
    current_file = buffer; 
    for(i=0; i<*nr_files; i++)
    {
        files[i] = strdup(current_file); 
        current_file += strlen(current_file) + 1;
    }
    if(has_more != NULL)
        *has_more = fsr->shadow_rsp.u.ret_val & HAS_MORE_FLAG;
    free_buffer_page(fsr);
    add_id_to_freelist(priv_req_id, import->freelist);
exit:
    return files;
} 

int fs_chmod(struct fs_import *import, int fd, int32_t mode)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    int ret;

    if (!import)
        return -1;

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_chmod call is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];
    fsr->thread = current;

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_CHMOD;
    req->id = priv_req_id;
    req->u.fchmod.fd = fd;
    req->u.fchmod.mode = mode;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    ret = (int)fsr->shadow_rsp.u.ret_val;
    DEBUG("The following returned: %d\n", ret);
    add_id_to_freelist(priv_req_id, import->freelist);

    return ret;
} 

int64_t fs_space(struct fs_import *import, char *location)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    grant_ref_t gref;
    void *buffer;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    int64_t ret;

    if (!import)
        return -1;

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_space is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];
    buffer = alloc_buffer_page(fsr, import->dom_id, &gref);
    DEBUG("gref=%d\n", gref);
    fsr->thread = current;
    sprintf(buffer, "%s", location);

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_FS_SPACE;
    req->id = priv_req_id;
    req->u.fspace.gref = gref;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    ret = (int64_t)fsr->shadow_rsp.u.ret_val;
    DEBUG("The following returned: %lld\n", ret);
    free_buffer_page(fsr);
    add_id_to_freelist(priv_req_id, import->freelist);

    return ret;
} 

int fs_sync(struct fs_import *import, int fd)
{
    struct fs_request *fsr;
    unsigned short priv_req_id;
    RING_IDX back_req_id; 
    struct fsif_request *req;
    int ret;

    if (!import)
        return -1;

    /* Prepare request for the backend */
    back_req_id = reserve_fsif_request(import);
    DEBUG("Backend request id=%d\n", back_req_id);

    /* Prepare our private request structure */
    priv_req_id = get_id_from_freelist(import->freelist);
    DEBUG("Request id for fs_sync call is: %d\n", priv_req_id);
    fsr = &import->requests[priv_req_id];
    fsr->thread = current;

    req = RING_GET_REQUEST(&import->ring, back_req_id);
    req->type = REQ_FILE_SYNC;
    req->id = priv_req_id;
    req->u.fsync.fd = fd;

    /* Set blocked flag before commiting the request, thus avoiding missed
     * response race */
    block(current);
    commit_fsif_request(import, back_req_id);
    schedule();
    
    /* Read the response */
    ret = (int)fsr->shadow_rsp.u.ret_val;
    DEBUG("Close returned: %d\n", ret);
    add_id_to_freelist(priv_req_id, import->freelist);

    return ret;
}


/******************************************************************************/
/*                       END OF INDIVIDUAL FILE OPERATIONS                    */
/******************************************************************************/

void *alloc_buffer_page(struct fs_request *req, domid_t domid, grant_ref_t *gref)
{
    void *page;

    page = (void *)alloc_page(); 
    *gref = gnttab_grant_access(domid, virt_to_mfn(page), 0); 
    req->private1 = page;
    req->private2 = (void *)(uintptr_t)(*gref);

    return page;
}

void free_buffer_page(struct fs_request *req)
{
    gnttab_end_access((grant_ref_t)(uintptr_t)req->private2);
    free_page(req->private1);
}

static void fsfront_handler(evtchn_port_t port, struct pt_regs *regs, void *data)
{
    struct fs_import *import = (struct fs_import*)data;
    static int in_irq = 0;
    RING_IDX cons, rp;
    int more;

    /* Check for non-reentrance */
    BUG_ON(in_irq);
    in_irq = 1;

    DEBUG("Event from import [%d:%d].\n", import->dom_id, import->export_id);
moretodo:   
    rp = import->ring.sring->rsp_prod;
    rmb(); /* Ensure we see queued responses up to 'rp'. */
    cons = import->ring.rsp_cons;
    while (cons != rp)
    {
        struct fsif_response *rsp;
        struct fs_request *req;

        rsp = RING_GET_RESPONSE(&import->ring, cons); 
        DEBUG("Response at idx=%d to request id=%d, ret_val=%lx\n", 
            cons, rsp->id, rsp->u.ret_val);
        req = &import->requests[rsp->id];
        memcpy(&req->shadow_rsp, rsp, sizeof(struct fsif_response));
        DEBUG("Waking up: %s\n", req->thread->name);
        wake(req->thread);

        cons++;
        up(&import->reqs_sem);
    }

    import->ring.rsp_cons = rp;
    RING_FINAL_CHECK_FOR_RESPONSES(&import->ring, more);
    if(more) goto moretodo;
    
    in_irq = 0;
}

static void alloc_request_table(struct fs_import *import)
{
    struct fs_request *requests;
    int i;

    BUG_ON(import->nr_entries <= 0);
    printk("Allocating request array for import %d, nr_entries = %d.\n",
            import->import_id, import->nr_entries);
    requests = xmalloc_array(struct fs_request, import->nr_entries);
    import->freelist = xmalloc_array(unsigned short, import->nr_entries + 1);
    memset(import->freelist, 0, sizeof(unsigned short) * (import->nr_entries + 1));
    for(i=0; i<import->nr_entries; i++)
        add_id_to_freelist(i, import->freelist);
    import->requests = requests;
}


/******************************************************************************/
/*                                FS TESTS                                    */
/******************************************************************************/


void test_fs_import(void *data)
{
    struct fs_import *import = (struct fs_import *)data; 
    int ret, fd, i, repeat_count;
    int32_t nr_files;
    char buffer[1024];
    ssize_t offset;
    char **files;
    long ret64;
    struct fsif_stat_response stat;
    
    repeat_count = 10; 
    /* Sleep for 1s and then try to open a file */
    msleep(1000);
again:
    ret = fs_create(import, "mini-os-created-directory", 1, 0777);
    printk("Directory create: %d\n", ret);

    sprintf(buffer, "mini-os-created-directory/mini-os-created-file-%d", 
            repeat_count);
    ret = fs_create(import, buffer, 0, 0666);
    printk("File create: %d\n", ret);

    fd = fs_open(import, buffer);
    printk("File descriptor: %d\n", fd);
    if(fd < 0) return;

    offset = 0;
    for(i=0; i<10; i++)
    {
        sprintf(buffer, "Current time is: %lld\n", NOW());
        ret = fs_write(import, fd, buffer, strlen(buffer), offset);
        printk("Writen current time (%d)\n", ret);
        if(ret < 0)
            return;
        offset += ret;
    }
    ret = fs_stat(import, fd, &stat);
    printk("Ret after stat: %d\n", ret);
    printk(" st_mode=%o\n", stat.stat_mode);
    printk(" st_uid =%d\n", stat.stat_uid);
    printk(" st_gid =%d\n", stat.stat_gid);
    printk(" st_size=%ld\n", stat.stat_size);
    printk(" st_atime=%ld\n", stat.stat_atime);
    printk(" st_mtime=%ld\n", stat.stat_mtime);
    printk(" st_ctime=%ld\n", stat.stat_ctime);
 
    ret = fs_close(import, fd);
    printk("Closed fd: %d, ret=%d\n", fd, ret);
   
    printk("Listing files in /\n");
    files = fs_list(import, "/", 0, &nr_files, NULL); 
    for(i=0; i<nr_files; i++)
        printk(" files[%d] = %s\n", i, files[i]);

    ret64 = fs_space(import, "/");
    printk("Free space: %lld (=%lld Mb)\n", ret64, (ret64 >> 20));
    repeat_count--;
    if(repeat_count > 0)
        goto again;
    
}

#if 0
//    char *content = (char *)alloc_page();
    int fd, ret;
//    int read;
    char write_string[] = "\"test data written from minios\"";
    struct fsif_stat_response stat;
    char **files;
    int32_t nr_files, i;
    int64_t ret64;


    fd = fs_open(import, "test-export-file");
//    read = fs_read(import, fd, content, PAGE_SIZE, 0);
//    printk("Read: %d bytes\n", read); 
//    content[read] = '\0';
//    printk("Value: %s\n", content);
    ret = fs_write(import, fd, write_string, strlen(write_string), 0);
    printk("Ret after write: %d\n", ret);
    ret = fs_stat(import, fd, &stat);
    printk("Ret after stat: %d\n", ret);
    printk(" st_mode=%o\n", stat.stat_mode);
    printk(" st_uid =%d\n", stat.stat_uid);
    printk(" st_gid =%d\n", stat.stat_gid);
    printk(" st_size=%ld\n", stat.stat_size);
    printk(" st_atime=%ld\n", stat.stat_atime);
    printk(" st_mtime=%ld\n", stat.stat_mtime);
    printk(" st_ctime=%ld\n", stat.stat_ctime);
    ret = fs_truncate(import, fd, 30);
    printk("Ret after truncate: %d\n", ret);
    ret = fs_remove(import, "test-to-remove/test-file");
    printk("Ret after remove: %d\n", ret);
    ret = fs_remove(import, "test-to-remove");
    printk("Ret after remove: %d\n", ret);
    ret = fs_chmod(import, fd, 0700);
    printk("Ret after chmod: %d\n", ret);
    ret = fs_sync(import, fd);
    printk("Ret after sync: %d\n", ret);
    ret = fs_close(import, fd);
    //ret = fs_rename(import, "test-export-file", "renamed-test-export-file");
    //printk("Ret after rename: %d\n", ret);
    ret = fs_create(import, "created-dir", 1, 0777);
    printk("Ret after dir create: %d\n", ret);
    ret = fs_create(import, "created-dir/created-file", 0, 0777);
    printk("Ret after file create: %d\n", ret);
    files = fs_list(import, "/", 15, &nr_files, NULL); 
    for(i=0; i<nr_files; i++)
        printk(" files[%d] = %s\n", i, files[i]);
    ret64 = fs_space(import, "created-dir");
    printk("Ret after space: %lld\n", ret64);

#endif


/******************************************************************************/
/*                            END OF FS TESTS                                 */
/******************************************************************************/

static int init_fs_import(struct fs_import *import)
{    
    char *err;
    xenbus_transaction_t xbt;
    char nodename[1024], r_nodename[1024], token[128], *message = NULL;
    struct fsif_sring *sring;
    int i, retry = 0;
    domid_t self_id;
    xenbus_event_queue events = NULL;

    printk("Initialising FS fortend to backend dom %d\n", import->dom_id);
    /* Allocate page for the shared ring */
    sring = (struct fsif_sring*) alloc_pages(FSIF_RING_SIZE_ORDER);
    memset(sring, 0, PAGE_SIZE * FSIF_RING_SIZE_PAGES);

    /* Init the shared ring */
    SHARED_RING_INIT(sring);
    ASSERT(FSIF_NR_READ_GNTS == FSIF_NR_WRITE_GNTS);

    /* Init private frontend ring */
    FRONT_RING_INIT(&import->ring, sring, PAGE_SIZE * FSIF_RING_SIZE_PAGES);
    import->nr_entries = import->ring.nr_ents;

    /* Allocate table of requests */
    alloc_request_table(import);
    init_SEMAPHORE(&import->reqs_sem, import->nr_entries);

    /* Grant access to the shared ring */
    for(i=0; i<FSIF_RING_SIZE_PAGES; i++) 
        import->gnt_refs[i] = 
            gnttab_grant_access(import->dom_id, 
                                virt_to_mfn((char *)sring + i * PAGE_SIZE), 
                                0);
   
    /* Allocate event channel */ 
    BUG_ON(evtchn_alloc_unbound(import->dom_id, 
                                fsfront_handler, 
                                //ANY_CPU, 
                                import, 
                                &import->local_port));
    unmask_evtchn(import->local_port);

    
    self_id = xenbus_get_self_id(); 
    /* Write the frontend info to a node in our Xenbus */
    sprintf(nodename, "/local/domain/%d/device/vfs/%d", 
                        self_id, import->import_id);

again:    
    err = xenbus_transaction_start(&xbt);
    if (err) {
        printk("starting transaction\n");
    }
    
    err = xenbus_printf(xbt, 
                        nodename, 
                        "ring-size",
                        "%u",
                        FSIF_RING_SIZE_PAGES);
    if (err) {
        message = "writing ring-size";
        goto abort_transaction;
    }
    
    for(i=0; i<FSIF_RING_SIZE_PAGES; i++)
    {
        sprintf(r_nodename, "ring-ref-%d", i);
        err = xenbus_printf(xbt, 
                            nodename, 
                            r_nodename,
                            "%u",
                            import->gnt_refs[i]);
        if (err) {
            message = "writing ring-refs";
            goto abort_transaction;
        }
    }

    err = xenbus_printf(xbt, 
                        nodename,
                        "event-channel", 
                        "%u", 
                        import->local_port);
    if (err) {
        message = "writing event-channel";
        goto abort_transaction;
    }

    err = xenbus_printf(xbt, nodename, "state", STATE_READY, 0xdeadbeef);

    
    err = xenbus_transaction_end(xbt, 0, &retry);
    if (retry) {
            goto again;
        printk("completing transaction\n");
    }

    /* Now, when our node is prepared we write request in the exporting domain
     * */
    printk("Our own id is %d\n", self_id);
    sprintf(r_nodename, 
            "/local/domain/%d/backend/vfs/exports/requests/%d/%d/frontend", 
            import->dom_id, self_id, import->export_id);
    BUG_ON(xenbus_write(XBT_NIL, r_nodename, nodename));

    goto done;

abort_transaction:
    xenbus_transaction_end(xbt, 1, &retry);

done:

#define WAIT_PERIOD 10   /* Wait period in ms */    
#define MAX_WAIT    10   /* Max number of WAIT_PERIODs */
    import->backend = NULL;
    sprintf(r_nodename, "%s/backend", nodename);
   
    for(retry = MAX_WAIT; retry > 0; retry--)
    { 
        xenbus_read(XBT_NIL, r_nodename, &import->backend);
        if(import->backend)
        {
            printk("Backend found at %s\n", import->backend);
            break;
        }
	msleep(WAIT_PERIOD);
    }        
    
    if(!import->backend)
    {
        printk("No backend available.\n");
        /* TODO - cleanup datastructures/xenbus */
        return 0;
    }
    sprintf(r_nodename, "%s/state", import->backend);
    sprintf(token, "fs-front-%d", import->import_id);
    /* The token will not be unique if multiple imports are inited */
    xenbus_watch_path_token(XBT_NIL, r_nodename, r_nodename, &events);
    xenbus_wait_for_value(r_nodename, STATE_READY, &events);
    xenbus_unwatch_path(XBT_NIL, r_nodename);
    printk("Backend ready.\n");
   
    //create_thread("fs-tester", test_fs_import, import); 

    return 1;
}

static void add_export(struct minios_list_head *exports, unsigned int domid)
{
    char node[1024], **exports_list = NULL, *ret_msg;
    int j = 0;
    static int import_id = 0;

    sprintf(node, "/local/domain/%d/backend/vfs/exports", domid);
    ret_msg = xenbus_ls(XBT_NIL, node, &exports_list);
    if (ret_msg && strcmp(ret_msg, "ENOENT"))
        printk("couldn't read %s: %s\n", node, ret_msg);
    while(exports_list && exports_list[j])
    {
        struct fs_import *import; 
        int export_id = -1;
        
        sscanf(exports_list[j], "%d", &export_id);
        if(export_id >= 0)
        {
            import = xmalloc(struct fs_import);
            import->dom_id = domid;
            import->export_id = export_id;
            import->import_id = import_id++;
            MINIOS_INIT_LIST_HEAD(&import->list);
            minios_list_add(&import->list, exports);
        }
        free(exports_list[j]);
        j++;
    }
    if(exports_list)
        free(exports_list);
    if(ret_msg)
        free(ret_msg);
}

#if 0
static struct minios_list_head* probe_exports(void)
{
    struct minios_list_head *exports;
    char **node_list = NULL, *msg = NULL;
    int i = 0;

    exports = xmalloc(struct minios_list_head);
    MINIOS_INIT_LIST_HEAD(exports);
    
    msg = xenbus_ls(XBT_NIL, "/local/domain", &node_list);
    if(msg)
    {
        printk("Could not list VFS exports (%s).\n", msg);
        goto exit;
    }

    while(node_list[i])
    {
        add_export(exports, atoi(node_list[i]));
        free(node_list[i]);
        i++;
    } 

exit:    
    if(msg)
        free(msg);
    if(node_list)
        free(node_list);
    return exports;
}
#endif

MINIOS_LIST_HEAD(exports);

void init_fs_frontend(void)
{
    struct minios_list_head *entry;
    struct fs_import *import = NULL;
    printk("Initing FS frontend(s).\n");

    add_export(&exports, 0);
    minios_list_for_each(entry, &exports)
    {
        import = minios_list_entry(entry, struct fs_import, list);
        printk("FS export [dom=%d, id=%d] found\n", 
                import->dom_id, import->export_id);
        if (init_fs_import(import) != 0) {
            fs_import = import;
            break;
        }
    }

    if (!fs_import)
	printk("No FS import\n");
}

/* TODO: shutdown */

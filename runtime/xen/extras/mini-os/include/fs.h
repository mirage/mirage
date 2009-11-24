#ifndef __FS_H__
#define __FS_H__

#include <xen/io/fsif.h>
#include <mini-os/semaphore.h>
#include <mini-os/types.h>

#define FSIF_RING_SIZE_ORDER   1
#define FSIF_RING_SIZE_PAGES   (1<<FSIF_RING_SIZE_ORDER)

struct fs_import 
{
    domid_t dom_id;                 /* dom id of the exporting domain       */ 
    uint16_t export_id;             /* export id (exporting dom specific)   */
    uint16_t import_id;             /* import id (specific to this domain)  */ 
    struct minios_list_head list;   /* list of all imports                  */
    unsigned int nr_entries;        /* Number of entries in rings & request
                                       array                                */
    struct fsif_front_ring ring;    /* frontend ring (contains shared ring) */
    uint32_t gnt_refs[FSIF_RING_SIZE_PAGES];  /* grant references to the shared ring  */
    evtchn_port_t local_port;       /* local event channel port             */
    char *backend;                  /* XenBus location of the backend       */
    struct fs_request *requests;    /* Table of requests                    */
    unsigned short *freelist;       /* List of free request ids             */
    struct semaphore reqs_sem;      /* Accounts requests resource           */
};

extern struct fs_import *fs_import;

void init_fs_frontend(void);

int fs_open(struct fs_import *import, char *file);
int fs_close(struct fs_import *import, int fd);
ssize_t fs_read(struct fs_import *import, int fd, void *buf, 
                ssize_t len, ssize_t offset);
ssize_t fs_write(struct fs_import *import, int fd, void *buf, 
                 ssize_t len, ssize_t offset);
int fs_stat(struct fs_import *import, 
            int fd, 
            struct fsif_stat_response *stat);
int fs_truncate(struct fs_import *import, 
                int fd, 
                int64_t length);
int fs_remove(struct fs_import *import, char *file);
int fs_rename(struct fs_import *import, 
              char *old_file_name, 
              char *new_file_name);
int fs_create(struct fs_import *import, char *name, 
              int8_t directory, int32_t mode);
char** fs_list(struct fs_import *import, char *name, 
               int32_t offset, int32_t *nr_files, int *has_more);
int fs_chmod(struct fs_import *import, int fd, int32_t mode);
int64_t fs_space(struct fs_import *import, char *location);
int fs_sync(struct fs_import *import, int fd);

#endif

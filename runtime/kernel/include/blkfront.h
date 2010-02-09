#include <mini-os/wait.h>
#include <xen/io/blkif.h>
#include <mini-os/types.h>
struct blkfront_dev;

struct blkfront_aiocbv
{
    struct blkfront_dev *aio_dev;
    void (*aio_cb)(struct blkfront_aiocbv *aiocb, int ret);
    uint8_t *aio_bufv[BLKIF_MAX_SEGMENTS_PER_REQUEST];
    size_t aio_nbytes;
    off_t aio_offset;
    size_t total_bytes;
    uint8_t is_write;
    void *data;

    grant_ref_t gref[BLKIF_MAX_SEGMENTS_PER_REQUEST];
    int n;

};

struct blkfront_info
{
    uint64_t sectors;
    unsigned sector_size;
    int mode;
    int info;
    int barrier;
    int flush;
};

struct blkfront_dev *init_blkfront(char *nodename, struct blkfront_info *info);
int blkfront_open(struct blkfront_dev *dev);
void blkfront_aiov(struct blkfront_aiocbv *, int);
#define blkfront_aio_readv(aiocbp) blkfront_aiov(aiocbp, 0)
#define blkfront_aio_writev(aiocbp) blkfront_aiov(aiocbp, 1)
void blkfront_io(struct blkfront_aiocbv *aiocbp, int write);
#define blkfront_read(aiocbp) blkfront_io(aiocbp, 0)
#define blkfront_write(aiocbp) blkfront_io(aiocbp, 1)
void blkfront_aio_push_operation(struct blkfront_aiocbv *aiocbp, uint8_t op);
int blkfront_aio_poll(struct blkfront_dev *dev);
void blkfront_sync(struct blkfront_dev *dev);
void shutdown_blkfront(struct blkfront_dev *dev);

extern struct wait_queue_head blkfront_queue;

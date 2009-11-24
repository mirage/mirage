#include <mini-os/wait.h>
#include <xen/io/blkif.h>
#include <mini-os/types.h>
struct blkfront_dev;
struct blkfront_aiocb
{
    struct blkfront_dev *aio_dev;
    uint8_t *aio_buf;
    size_t aio_nbytes;
    off_t aio_offset;
    size_t total_bytes;
    uint8_t is_write;
    void *data;

    grant_ref_t gref[BLKIF_MAX_SEGMENTS_PER_REQUEST];
    int n;

    void (*aio_cb)(struct blkfront_aiocb *aiocb, int ret);
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
#ifdef HAVE_LIBC
int blkfront_open(struct blkfront_dev *dev);
#endif
void blkfront_aio(struct blkfront_aiocb *aiocbp, int write);
#define blkfront_aio_read(aiocbp) blkfront_aio(aiocbp, 0)
#define blkfront_aio_write(aiocbp) blkfront_aio(aiocbp, 1)
void blkfront_io(struct blkfront_aiocb *aiocbp, int write);
#define blkfront_read(aiocbp) blkfront_io(aiocbp, 0)
#define blkfront_write(aiocbp) blkfront_io(aiocbp, 1)
void blkfront_aio_push_operation(struct blkfront_aiocb *aiocbp, uint8_t op);
int blkfront_aio_poll(struct blkfront_dev *dev);
void blkfront_sync(struct blkfront_dev *dev);
void shutdown_blkfront(struct blkfront_dev *dev);

extern struct wait_queue_head blkfront_queue;

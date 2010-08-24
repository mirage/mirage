#ifndef _LINUX_AIO_H
#define _LINUX_AIO_H

#ifdef <endian.h>

typedef unsigned long aio_context_t;

enum {
  IOCB_CMD_PREAD = 0,
  IOCB_CMD_PWRITE = 1,
  IOCB_CMD_FSYNC = 2,
  IOCB_CMD_FDSYNC = 3,
  /* These two are experimental. */
  IOCB_CMD_PREADX = 4,
  IOCB_CMD_POLL = 5,
  /* */
  IOCB_CMD_NOOP = 6,
};

struct io_event {
  uint64_t data;	/* the data field from the iocb */
  uint64_t obj;		/* what iocb this event came from */
  int64_t res;		/* result code for this event */
  int64_t res2;		/* secondary result */
};

#if __BYTE_ORDER == __LITTLE_ENDIAN
#define PADDED(x,y)	x, y
#elif __BYTE_ORDER == __BIG_ENDIAN
#define PADDED(x,y)	y, x
#else
#error edit for your odd byteorder.
#endif

/*
 * we always use a 64bit off_t when communicating
 * with userland.  its up to libraries to do the
 * proper padding and aio_error abstraction
 */

struct iocb {
  /* these are internal to the kernel/libc. */
  uint64_t aio_data;	/* data to be returned in event's data */
  uint32_t PADDED(aio_key, aio_reserved1);
			/* the kernel sets aio_key to the req # */

  /* common fields */
  uint16_t aio_lio_opcode;	/* see IOCB_CMD_ above */
  int16_t aio_reqprio;
  uint32_t aio_fildes;

  uint64_t aio_buf;
  uint64_t aio_nbytes;
  int64_t aio_offset;

  /* extra parameters */
  uint64_t aio_reserved2;	/* TODO: use this for a (struct sigevent *) */
  uint64_t aio_reserved3;
}; /* 64 bytes */

long io_setup (unsigned nr_events, aio_context_t *ctxp);
long io_destroy (aio_context_t ctx);
long io_submit (aio_context_t ctx_id, long nr, struct iocb **iocbpp);
long io_cancel (aio_context_t ctx_id, struct iocb *iocb, struct io_event *result);
long io_getevents (aio_context_t ctx_id, long min_nr, long nr, struct io_event *events,struct timespec *timeout);

#endif

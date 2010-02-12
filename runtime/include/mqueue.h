#ifndef _MQUEUE_H
#define _MQUEUE_H

#include <sys/cdefs.h>
#include <sys/time.h>

#define MQ_PRIO_MAX 	32768
/* per-uid limit of kernel memory used by mqueue, in bytes */
#define MQ_BYTES_MAX	819200

typedef int mqd_t;
struct mq_attr {
  long	mq_flags;	/* message queue flags			*/
  long	mq_maxmsg;	/* maximum number of messages		*/
  long	mq_msgsize;	/* maximum message size			*/
  long	mq_curmsgs;	/* number of messages currently queued	*/
  long	__reserved[4];	/* ignored for input, zeroed for output */
};

#define NOTIFY_NONE	0
#define NOTIFY_WOKENUP	1
#define NOTIFY_REMOVED	2

#define NOTIFY_COOKIE_LEN	32

__BEGIN_DECLS

mqd_t mq_open(const char *name, int oflag, ...) __THROW;
int mq_unlink(const char *name) __THROW;
int mq_send(mqd_t mqdes, const char *msg_ptr, size_t msg_len, unsigned msg_prio) __THROW;
int mq_timedsend(mqd_t mqdes, const char *msg_ptr, size_t msg_len, unsigned msg_prio,
		 const struct timespec *abs_timeout) __THROW;
ssize_t mq_receive(mqd_t mqdes, char *msg_ptr, size_t msg_len, unsigned *msg_prio) __THROW;
ssize_t mq_timedreceive(mqd_t mqdes, char *restrict msg_ptr, size_t msg_len,
			unsigned *restrict msg_prio, const struct timespec *restrict abs_timeout) __THROW;
int mq_notify(mqd_t mqdes, const struct sigevent *notification) __THROW;
int mq_getattr(mqd_t mqdes, struct mq_attr *mqstat) __THROW;
int mq_setattr(mqd_t mqdes, const struct mq_attr *restrict mqstat, struct mq_attr *restrict omqstat) __THROW;

__END_DECLS

#endif

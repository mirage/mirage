/* libc/sys/linux/include/mqueue.h - message queue functions */

/* Copyright 2002, Red Hat Inc. - all rights reserved */

#ifndef __MQUEUE_H
#define __MQUEUE_H

#include <sys/types.h>
#define __need_sigevent_t 1
#include <bits/siginfo.h>

#include <sys/fcntl.h>

/* message queue types */
typedef int mqd_t;

struct mq_attr {
  long mq_flags;    /* message queue flags */
  long mq_maxmsg;   /* maximum number of messages */
  long mq_msgsize;  /* maximum message size */
  long mq_curmsgs;  /* number of messages currently queued */
};

#define MQ_PRIO_MAX 16

/* prototypes */
mqd_t mq_open (const char *__name, int __oflag, ...);
int mq_close (mqd_t __msgid);
int mq_send (mqd_t __msgid, const char *__msg, size_t __msg_len, unsigned int __msg_prio);
ssize_t mq_receive (mqd_t __msgid, char *__msg, size_t __msg_len, unsigned int *__msg_prio);
int mq_notify (mqd_t __msgid, const struct sigevent *__notification);
int mq_unlink (const char *__name);
int mq_getattr (mqd_t __msgid, struct mq_attr *__mqstat);
int mq_setattr (mqd_t __msgid, const struct mq_attr *__mqstat, struct mq_attr *__omqattr);

#endif /* __MQUEUE_H */

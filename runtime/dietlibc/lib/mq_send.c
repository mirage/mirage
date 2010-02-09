#include <mqueue.h>

int mq_send (mqd_t mqdes, const char *msg_ptr, size_t msg_len, unsigned int msg_prio) {
  return mq_timedsend(mqdes, msg_ptr, msg_len, msg_prio, NULL);
}


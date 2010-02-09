#include <mqueue.h>

int mq_getattr(mqd_t mqdes, struct mq_attr *mqstat) {
  return mq_setattr(mqdes, NULL, mqstat);
}

